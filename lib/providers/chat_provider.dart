import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/models.dart';
import '../services/llm_service.dart';
import '../services/tool_service.dart';

class ChatProvider extends ChangeNotifier {
  LLMService? _llmService;
  ToolExecutionService _toolService = ToolExecutionService();
  bool _isInitialized = false;

  // Conversations
  List<Conversation> _conversations = [];
  String? _currentConversationId;

  // State
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  // Getters
  LLMService? get llmService => _llmService;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  List<Conversation> get conversations => _conversations;
  String? get currentConversationId => _currentConversationId;
  ToolExecutionService get toolService => _toolService;

  Conversation? get currentConversation {
    try {
      return _conversations.firstWhere((c) => c.id == _currentConversationId);
    } catch (_) {
      return null;
    }
  }

  List<ChatMessage> get currentMessages => currentConversation?.messages ?? [];

  void init(LLMService llmService) {
    _llmService?.dispose();
    _llmService = llmService;
    _isInitialized = true;
    _loadConversations();
  }

  void setWorkspacePath(String path) {
    _toolService.workspacePath = path;
    _saveConversations();
  }

  void setLlmService(LLMService service) {
    _llmService?.dispose();
    _llmService = service;
    _isInitialized = true;
    notifyListeners();
  }

  /// Create a new conversation
  Conversation createConversation({String? title}) {
    final conv = Conversation(
      title: title ?? 'New Chat',
    );
    _conversations.insert(0, conv);
    _currentConversationId = conv.id;
    _saveConversations();
    notifyListeners();
    return conv;
  }

  /// Switch to a different conversation
  void switchConversation(String id) {
    if (_conversations.any((c) => c.id == id)) {
      _currentConversationId = id;
      notifyListeners();
    }
  }

  /// Delete a conversation
  void deleteConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    if (_currentConversationId == id) {
      _currentConversationId = _conversations.isNotEmpty ? _conversations.first.id : null;
      if (_currentConversationId == null) {
        createConversation(title: 'New Chat');
      }
    }
    _saveConversations();
    notifyListeners();
  }

  /// Rename a conversation
  void renameConversation(String id, String title) {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _conversations[idx].title = title;
      _saveConversations();
      notifyListeners();
    }
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String content) async {
    if (_llmService == null || content.trim().isEmpty) return;

    // Auto-create conversation if none exists
    if (_currentConversationId == null) {
      createConversation();
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    // Add user message
    final userMsg = ChatMessage(
      role: MessageRole.user,
      content: content.trim(),
    );
    currentConversation!.messages.add(userMsg);
    currentConversation!.updatedAt = DateTime.now();
    // Auto-title from first user message
    if (currentConversation!.title == 'New Chat' && content.length > 10) {
      currentConversation!.title = content.length > 40
          ? '${content.substring(0, 40)}...'
          : content;
    }
    _saveConversations();
    notifyListeners();

    try {
      await _processWithTools(content);
    } catch (e) {
      _error = e.toString();
      // Add error message
      currentConversation!.messages.add(ChatMessage(
        role: MessageRole.assistant,
        content: '❌ **Error**: ${e.toString()}',
      ));
    }

    _isSending = false;
    _saveConversations();
    notifyListeners();
  }

  /// Process message with tool call loop
  Future<void> _processWithTools(String message) async {
    final history = currentConversation!.messages.toList();
    // Remove the last user message from history for the API call
    history.removeLast();

    int maxToolRounds = 10;
    int round = 0;
    String assistantContent = '';

    while (round < maxToolRounds) {
      round++;

      final response = await _llmService!.chat(
        history: history,
        message: message,
        systemPrompt: currentConversation!.systemPrompt,
        toolResults: round > 1 ? _lastToolResults : null,
      );

      // Accumulate content
      if (response.content.isNotEmpty) {
        assistantContent += response.content;
      }

      // Check for tool calls
      if (response.toolCalls.isEmpty) {
        // No more tool calls — done
        break;
      }

      // Execute all tool calls
      _lastToolResults = [];
      for (final tc in response.toolCalls) {
        // Add tool call to history
        history.add(ChatMessage(
          role: MessageRole.assistant,
          content: '',
          toolCalls: [tc],
        ));

        // Execute the tool
        final result = await _toolService.executeTool(tc);

        // Add tool result to history
        final resultMsg = ChatMessage(
          role: MessageRole.tool,
          content: result.output.isNotEmpty ? result.output : (result.error ?? 'No output'),
          metadata: {'toolCallId': tc.id},
        );
        history.add(resultMsg);
        _lastToolResults!.add(ToolCall(
          id: tc.id,
          type: tc.type,
          name: tc.name,
          arguments: tc.arguments,
          status: result.success ? ToolCallStatus.completed : ToolCallStatus.failed,
          result: result.output,
          error: result.error,
        ));
      }
    }

    // Add final assistant message
    if (assistantContent.isNotEmpty || round >= maxToolRounds) {
      final finalContent = assistantContent.isNotEmpty
          ? assistantContent
          : (round >= maxToolRounds
              ? '⚠️ Reached maximum tool call rounds. Some operations may be incomplete.'
              : '');
      if (finalContent.isNotEmpty) {
        currentConversation!.messages.add(ChatMessage(
          role: MessageRole.assistant,
          content: finalContent,
        ));
      }
    }

    _saveConversations();
  }

  List<ToolCall>? _lastToolResults;

  /// Retry the last assistant message
  Future<void> retry() async {
    final conv = currentConversation;
    if (conv == null || conv.messages.length < 2) return;

    // Remove last assistant message
    if (conv.messages.last.role == MessageRole.assistant) {
      conv.messages.removeLast();
    }
    // Remove trailing tool messages
    while (conv.messages.isNotEmpty && conv.messages.last.role == MessageRole.tool) {
      conv.messages.removeLast();
    }

    // Find the last user message
    String lastUserMsg = '';
    for (int i = conv.messages.length - 1; i >= 0; i--) {
      if (conv.messages[i].role == MessageRole.user) {
        lastUserMsg = conv.messages[i].content;
        break;
      }
    }

    if (lastUserMsg.isNotEmpty) {
      await sendMessage(lastUserMsg);
    }
  }

  /// Save conversations to local storage
  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _conversations.map((c) => c.toJson()).toList();
      await prefs.setString('vias_conversations', jsonEncode(data));
    } catch (_) {}
  }

  /// Load conversations from local storage
  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('vias_conversations');
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List;
        _conversations = list.map((j) => Conversation.fromJson(j as Map<String, dynamic>)).toList();
        if (_conversations.isNotEmpty) {
          _currentConversationId = _conversations.first.id;
        }
      }
    } catch (_) {}

    // Ensure at least one conversation exists
    if (_conversations.isEmpty) {
      createConversation(title: 'New Chat');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _llmService?.dispose();
    super.dispose();
  }
}

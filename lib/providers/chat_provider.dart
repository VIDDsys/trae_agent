import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/llm_service.dart';
import '../services/tool_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  LLMService? _llmService;
  final ToolExecutionService _toolService = ToolExecutionService();
  bool _isProcessing = false;
  bool _isInitialized = false;

  // Getters
  List<Conversation> get conversations => _conversations;
  Conversation? get activeConversation => _activeConversation;
  List<ChatMessage> get messages => _activeConversation?.messages ?? [];
  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;
  ToolExecutionService get toolService => _toolService;

  void init(LLMService llmService) {
    // Dispose old service to prevent connection leaks
    _llmService?.dispose();
    _llmService = llmService;
    _isInitialized = true;
    _loadConversations();
    notifyListeners();
  }

  void setWorkspacePath(String? path) {
    _toolService.workspacePath = path;
  }

  /// Create a new conversation
  Conversation createConversation({String? projectPath}) {
    final conv = Conversation(
      id: _generateId(),
      projectPath: projectPath ?? _toolService.workspacePath,
    );
    _conversations.insert(0, conv);
    _activeConversation = conv;
    _saveConversations();
    notifyListeners();
    return conv;
  }

  /// Switch to an existing conversation
  void switchConversation(String id) {
    _activeConversation = _conversations.firstWhere(
      (c) => c.id == id,
      orElse: () => _conversations.first,
    );
    notifyListeners();
  }

  /// Delete a conversation
  void deleteConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    if (_activeConversation?.id == id) {
      _activeConversation = _conversations.isNotEmpty ? _conversations.first : null;
    }
    _saveConversations();
    notifyListeners();
  }

  /// Archive a conversation
  void archiveConversation(String id) {
    final conv = _conversations.firstWhere((c) => c.id == id);
    conv.isArchived = true;
    _saveConversations();
    notifyListeners();
  }

  /// Clear all conversations
  void clearAllConversations() {
    _conversations.clear();
    _activeConversation = null;
    _saveConversations();
    notifyListeners();
  }

  /// Send a message and process the response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isProcessing) return;
    if (_llmService == null) {
      _addErrorMessage('LLM service not configured. Check your API settings.');
      return;
    }

    // Ensure active conversation
    if (_activeConversation == null) {
      createConversation();
    }

    // Add user message
    final userMsg = ChatMessage(
      id: _generateId(),
      conversationId: _activeConversation!.id,
      role: MessageRole.user,
      content: content.trim(),
    );
    _activeConversation!.addMessage(userMsg);
    _isProcessing = true;
    notifyListeners();

    // Create assistant message placeholder
    final assistantMsg = ChatMessage(
      id: _generateId(),
      conversationId: _activeConversation!.id,
      role: MessageRole.assistant,
      status: MessageStatus.streaming,
      agentName: 'Trae Agent',
    );
    _activeConversation!.addMessage(assistantMsg);
    notifyListeners();

    try {
      // Main interaction loop — handles multiple tool call rounds
      final history = _activeConversation!.messages
          .where((m) => m.id != assistantMsg.id && !m.isError)
          .toList();

      String currentMessage = content;

      // Allow up to 10 tool call rounds
      for (int round = 0; round < 10; round++) {
        List<ToolCall>? toolResults;

        if (round > 0) {
          // Collect results from previous tool calls
          final toolMsgs = history
              .where((m) => m.role == MessageRole.tool && m.metadata?['round'] == round - 1)
              .toList();
          if (toolMsgs.isEmpty) break;

          toolResults = toolMsgs.map((m) {
            final tcId = m.metadata?['toolCallId'] as String? ?? '';
            return ToolCall(
              id: tcId,
              type: 'function',
              name: m.metadata?['toolName'] as String? ?? '',
              arguments: {},
              status: ToolCallStatus.completed,
              result: m.content,
            );
          }).toList();
        }

        // Get LLM response
        final response = await _llmService!
            .chat(history: history, message: currentMessage, toolResults: toolResults)
            .timeout(const Duration(seconds: 60));

        // Append assistant response content
        if (response.content.isNotEmpty) {
          assistantMsg.content += response.content;
          notifyListeners();
        }

        // Check for tool calls
        if (response.toolCalls.isNotEmpty) {
          for (final tc in response.toolCalls) {
            assistantMsg.toolCalls.add(tc);
            notifyListeners();

            // Execute the tool
            final result = await _toolService.executeTool(tc);

            // Add tool result as a tool message
            final toolMsg = ChatMessage(
              id: _generateId(),
              conversationId: _activeConversation!.id,
              role: MessageRole.tool,
              content: result.output,
              metadata: {
                'toolCallId': tc.id,
                'toolName': tc.name,
                'round': round,
              },
            );
            history.add(toolMsg);
          }
          // Continue loop to send tool results back to LLM
          currentMessage = '';
          continue;
        }

        // No tool calls — we're done
        break;
      }

      assistantMsg.status = MessageStatus.completed;
    } catch (e) {
      assistantMsg.status = MessageStatus.error;
      assistantMsg.errorMessage = e.toString();
    }

    _isProcessing = false;
    _saveConversations();
    notifyListeners();
  }

  /// Stream a message (real-time token display)
  Future<void> sendMessageStream(String content) async {
    if (content.trim().isEmpty || _isProcessing) return;
    if (_llmService == null) {
      _addErrorMessage('LLM service not configured. Check your API settings.');
      return;
    }

    if (_activeConversation == null) createConversation();

    // User message
    final userMsg = ChatMessage(
      id: _generateId(),
      conversationId: _activeConversation!.id,
      role: MessageRole.user,
      content: content.trim(),
    );
    _activeConversation!.addMessage(userMsg);
    _isProcessing = true;
    notifyListeners();

    // Assistant message placeholder for streaming
    final assistantMsg = ChatMessage(
      id: _generateId(),
      conversationId: _activeConversation!.id,
      role: MessageRole.assistant,
      status: MessageStatus.streaming,
      agentName: 'Trae Agent',
    );
    _activeConversation!.addMessage(assistantMsg);
    notifyListeners();

    try {
      final history = _activeConversation!.messages
          .where((m) => m.id != assistantMsg.id && !m.isError)
          .toList();

      // Use the working non-streaming sendMessage logic for tool call handling
      // but with streaming display for the initial response
      String currentMessage = content.trim();
      final allToolResults = <ToolCall>[];

      for (int round = 0; round < 10; round++) {
        // If we have tool results from previous round, send them back
        if (round > 0 && allToolResults.isNotEmpty) {
          final toolMsgs = allToolResults.map((tc) {
            return ChatMessage(
              id: _generateId(),
              conversationId: _activeConversation!.id,
              role: MessageRole.tool,
              content: tc.result?.toString() ?? tc.error ?? '',
              metadata: {
                'toolCallId': tc.id,
                'toolName': tc.name,
                'round': round - 1,
              },
            );
          }).toList();
          history.addAll(toolMsgs);

          final response = await _llmService!
              .chat(history: history, message: '')
              .timeout(const Duration(seconds: 60));

          if (response.content.isNotEmpty) {
            assistantMsg.content += response.content;
            notifyListeners();
          }
          if (response.toolCalls.isEmpty) break;

          allToolResults.clear();
          for (final tc in response.toolCalls) {
            assistantMsg.toolCalls.add(tc);
            notifyListeners();
            final result = await _toolService.executeTool(tc);
            allToolResults.add(ToolCall(
              id: tc.id,
              type: tc.type,
              name: tc.name,
              arguments: tc.arguments,
              status: result.success ? ToolCallStatus.completed : ToolCallStatus.failed,
              result: result.output,
              error: result.error,
            ));
          }
          continue;
        }

        // First round: use streaming
        if (round == 0) {
          final stream = _llmService!.chatStream(
            history: history,
            message: currentMessage,
          );

          ToolCall? pendingToolCall;
          await for (final chunk in stream) {
            if (chunk.content.isNotEmpty) {
              assistantMsg.content += chunk.content;
              notifyListeners();
            }
            if (chunk.toolCalls.isNotEmpty) {
              for (final tc in chunk.toolCalls) {
                pendingToolCall = tc;
                assistantMsg.toolCalls.add(tc);
                notifyListeners();
              }
            }
          }

          if (pendingToolCall != null) {
            for (final tc in assistantMsg.toolCalls) {
              final result = await _toolService.executeTool(tc);
              allToolResults.add(ToolCall(
                id: tc.id,
                type: tc.type,
                name: tc.name,
                arguments: tc.arguments,
                status: result.success ? ToolCallStatus.completed : ToolCallStatus.failed,
                result: result.output,
                error: result.error,
              ));
            }
            continue;
          }
        }
        break;
      }

      assistantMsg.status = MessageStatus.completed;
    } catch (e) {
      assistantMsg.status = MessageStatus.error;
      assistantMsg.errorMessage = e.toString();
    }

    _isProcessing = false;
    _saveConversations();
    notifyListeners();
  }

  /// Cancel current processing
  void cancelProcessing() {
    if (_isProcessing && _activeConversation != null) {
      final last = _activeConversation!.messages.lastWhere(
        (m) => m.isStreaming,
        orElse: () => _activeConversation!.messages.last,
      );
      if (last.isStreaming) {
        last.status = MessageStatus.cancelled;
      }
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Retry last assistant message
  Future<void> retryLastMessage() async {
    if (_activeConversation == null || _activeConversation!.messages.length < 2) return;
    // Remove last assistant message
    _activeConversation!.messages.removeLast();
    // Remove last user message and resend
    final lastUserMsg = _activeConversation!.messages.lastWhere(
      (m) => m.isUser,
    );
    final content = lastUserMsg.content;
    await sendMessageStream(content);
  }

  /// Export conversation as markdown
  String? exportConversation(String id) {
    final conv = _conversations.firstWhere(
      (c) => c.id == id,
      orElse: () => _conversations.first,
    );
    return conv.exportAsMarkdown();
  }

  void _addErrorMessage(String message) {
    if (_activeConversation == null) createConversation();
    final msg = ChatMessage(
      id: _generateId(),
      conversationId: _activeConversation!.id,
      role: MessageRole.assistant,
      status: MessageStatus.error,
      content: message,
      errorMessage: message,
    );
    _activeConversation!.addMessage(msg);
    _isProcessing = false;
    notifyListeners();
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'msg_${timestamp}_$random';
  }

  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('conversations');
      if (stored != null) {
        final list = jsonDecode(stored) as List;
        _conversations = list.map((c) => Conversation.fromJson(c)).toList();
        if (_conversations.isNotEmpty) {
          _activeConversation = _conversations.first;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'conversations',
        jsonEncode(_conversations.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _llmService?.dispose();
    super.dispose();
  }
}

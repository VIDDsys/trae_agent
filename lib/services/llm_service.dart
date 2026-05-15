import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/models.dart';

class LLMResponse {
  final String content;
  final List<ToolCall> toolCalls;
  final Map<String, dynamic>? usage;

  LLMResponse({
    required this.content,
    this.toolCalls = const [],
    this.usage,
  });
}

class LLMService {
  LLMConfig _config;
  http.Client? _client;

  LLMService(this._config);

  LLMConfig get config => _config;
  set config(LLMConfig c) => _config = c;

  http.Client get client => _client ??= http.Client();

  void dispose() {
    _client?.close();
    _client = null;
  }

  /// Build OpenAI-compatible messages array from conversation context
  List<Map<String, dynamic>> _buildMessages({
    required List<ChatMessage> history,
    required String newMessage,
    List<ToolCall>? toolResults,
    String? systemPrompt,
  }) {
    final messages = <Map<String, dynamic>>[];

    // System prompt
    messages.add({
      'role': 'system',
      'content': systemPrompt ?? _defaultSystemPrompt,
    });

    // Conversation history
    for (final msg in history) {
      switch (msg.role) {
        case MessageRole.user:
          messages.add({'role': 'user', 'content': msg.content});
        case MessageRole.assistant:
          final m = <String, dynamic>{'role': 'assistant', 'content': msg.content};
          if (msg.toolCalls.any((t) => t.status == ToolCallStatus.completed)) {
            m['tool_calls'] = msg.toolCalls
                .where((t) => t.status == ToolCallStatus.completed)
                .map((t) => {
                  'id': t.id,
                  'type': 'function',
                  'function': {
                    'name': t.name,
                    'arguments': jsonEncode(t.arguments),
                  },
                })
                .toList();
          }
          messages.add(m);
        case MessageRole.tool:
          messages.add({
            'role': 'tool',
            'tool_call_id': msg.metadata?['toolCallId'] ?? '',
            'content': msg.content,
          });
        default:
          break;
      }
    }

    // Current user message
    if (toolResults != null && toolResults.isNotEmpty) {
      for (final tr in toolResults) {
        messages.add({
          'role': 'tool',
          'tool_call_id': tr.id,
          'content': tr.result?.toString() ?? tr.error ?? '',
        });
      }
      // Add a follow-up assistant message to continue after tool results
      return messages;
    }

    messages.add({'role': 'user', 'content': newMessage});
    return messages;
  }

  String get _defaultSystemPrompt => '''Hey there 👋 I'm Vias — your AI coding buddy running right on your phone.

About me:
- I'm a hands-on technical partner, not a chatbot 🤖
- Direct and to the point — I lead with answers, then explain
- I use emojis to keep things friendly and readable 😊
- If I don't know something, I'll tell you straight up

What I can do for you:
📂 Read, write, and edit files in your project
🔍 Search through your codebase
📋 Browse your project's files and folders
🌐 Look things up on the web

My tools:
- `read_file(path)` — Open and read any file
- `write_file(path, content)` — Create or update files
- `edit_file(path, old_string, new_string)` — Make targeted edits
- `search_code(query)` — Find code patterns across your project
- `list_directory(path)` — Explore folder structure
- `web_search(query)` — Search the web for answers

A few ground rules:
- I work best when you tell me what you want to build or fix
- I'll wrap code in proper \`\`\`language blocks
- File operations stay within your selected workspace folder
- Web search uses DuckDuckGo (free, no API key needed)''';

  /// Available tool definitions sent to the LLM
  List<Map<String, dynamic>> get _tools => [
    {
          'type': 'function',
          'function': {
            'name': 'read_file',
            'description': 'Read the full contents of any file from the filesystem. Use for code review, analysis, inspecting configuration, logs, or understanding existing code.',
            'parameters': {
              'type': 'object',
              'properties': {
                'path': {'type': 'string', 'description': 'Absolute or relative path to the file to read'},
              },
              'required': ['path'],
            },
          },
        },
    {
          'type': 'function',
          'function': {
            'name': 'write_file',
            'description': 'Create a new file or overwrite an existing file with the given content. Use for implementing code changes, creating new files, editing configuration, or writing documentation.',
            'parameters': {
              'type': 'object',
              'properties': {
                'path': {'type': 'string', 'description': 'Absolute or relative path of the file to write'},
                'content': {'type': 'string', 'description': 'Full file content to write (completely replaces existing content)'},
              },
              'required': ['path', 'content'],
            },
          },
        },
    {
          'type': 'function',
          'function': {
            'name': 'search_code',
            'description': 'Search for text patterns across project files using regex. Use for finding relevant code, references, function definitions, imports, or any text pattern in the codebase.',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {'type': 'string', 'description': 'Search query or regex pattern to find'},
                'path': {'type': 'string', 'description': 'Optional directory path to scope the search (defaults to project root)'},
              },
              'required': ['query'],
            },
          },
        },
    {
          'type': 'function',
          'function': {
            'name': 'list_directory',
            'description': 'List files and subdirectories in a given path. Use for exploring project structure, finding files, or understanding directory layout before reading files.',
            'parameters': {
              'type': 'object',
              'properties': {
                'path': {'type': 'string', 'description': 'Directory path to list (absolute or relative)'},
              },
              'required': ['path'],
            },
          },
        },
    {
          'type': 'function',
          'function': {
            'name': 'web_search',
            'description': 'Search the web for information. Use for looking up documentation, troubleshooting errors, finding code examples, researching libraries or APIs, or any information need that requires internet access.',
            'parameters': {
              'type': 'object',
              'properties': {
                'query': {'type': 'string', 'description': 'Search query string (natural language or keywords)'},
              },
              'required': ['query'],
            },
          },
        },
  ];

  /// Build the request body for the chat completions API
  Map<String, dynamic> _buildRequestBody({
    required List<Map<String, dynamic>> messages,
    bool stream = false,
  }) {
    return {
      'model': _config.effectiveModel,
      'messages': messages,
      'temperature': _config.temperature,
      'max_tokens': _config.maxTokens,
      'top_p': _config.topP,
      'stream': stream,
      'tools': _tools,
      'tool_choice': 'auto',
    };
  }

  /// Non-streaming chat completion
  Future<LLMResponse> chat({
    required List<ChatMessage> history,
    required String message,
    String? systemPrompt,
    List<ToolCall>? toolResults,
  }) async {
    final messages = _buildMessages(
      history: history,
      newMessage: message,
      toolResults: toolResults,
      systemPrompt: systemPrompt,
    );

    final body = _buildRequestBody(messages: messages, stream: false);

    try {
      final response = await client.post(
        Uri.parse('${_config.effectiveBaseUrl}/v1/chat/completions'),
        headers: _config.headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw LLMException(
          'API returned ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choice = (data['choices'] as List).first;
      final msg = choice['message'] as Map<String, dynamic>;

      final content = msg['content'] as String? ?? '';
      final toolCalls = <ToolCall>[];

      if (msg.containsKey('tool_calls')) {
        for (final tc in msg['tool_calls'] as List) {
          toolCalls.add(ToolCall(
            id: tc['id'],
            type: tc['type'] ?? 'function',
            name: tc['function']['name'],
            arguments: jsonDecode(tc['function']['arguments']),
          ));
        }
      }

      return LLMResponse(
        content: content,
        toolCalls: toolCalls,
        usage: data['usage'] as Map<String, dynamic>?,
      );
    } catch (e) {
      if (e is LLMException) rethrow;
      throw LLMException('Failed to communicate with LLM: $e');
    }
  }

  /// Streaming chat completion — yields content chunks and tool calls
  Stream<LLMResponse> chatStream({
    required List<ChatMessage> history,
    required String message,
    String? systemPrompt,
    List<ToolCall>? toolResults,
  }) async* {
    final messages = _buildMessages(
      history: history,
      newMessage: message,
      toolResults: toolResults,
      systemPrompt: systemPrompt,
    );

    final body = _buildRequestBody(messages: messages, stream: true);

    try {
      final request = http.Request('POST',
        Uri.parse('${_config.effectiveBaseUrl}/v1/chat/completions'));
      request.headers.addAll(_config.headers);
      request.body = jsonEncode(body);

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw LLMException(
          'API returned ${streamedResponse.statusCode}: $errorBody',
        );
      }

      final buffer = StringBuffer();
      String? currentToolId;
      String? currentToolName;
      final toolArgsBuffer = StringBuffer();

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!chunk.startsWith('data: ')) continue;
        final data = chunk.substring(6).trim();
        if (data == '[DONE]') {
          if (currentToolId != null) {
            yield LLMResponse(
              content: '',
              toolCalls: [
                ToolCall(
                  id: currentToolId,
                  type: 'function',
                  name: currentToolName ?? '',
                  arguments: jsonDecode(toolArgsBuffer.toString()),
                ),
              ],
            );
          }
          return;
        }

        try {
          final parsed = jsonDecode(data) as Map<String, dynamic>;
          final choices = parsed['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;

          final delta = choices.first['delta'] as Map<String, dynamic>? ?? {};

          // Content delta
          final contentDelta = delta['content'] as String?;
          if (contentDelta != null && contentDelta.isNotEmpty) {
            buffer.write(contentDelta);
            yield LLMResponse(content: contentDelta);
          }

          // Tool call delta
          final toolCallsDelta = delta['tool_calls'] as List?;
          if (toolCallsDelta != null) {
            for (final tc in toolCallsDelta) {
              final func = tc['function'] as Map<String, dynamic>?;
              if (func == null) continue;

              final name = func['name'] as String?;
              final args = func['arguments'] as String?;

              if (tc['id'] != null) {
                currentToolId = tc['id'];
              }
              if (name != null && name.isNotEmpty) {
                currentToolName = name;
              }
              if (args != null && args.isNotEmpty) {
                toolArgsBuffer.write(args);
              }
            }
          }

          // Final choice — check for complete tool_calls
          if (choices.first['finish_reason'] == 'tool_calls') {
            // Tool calls will be handled above in the [DONE] handler or here
            if (currentToolId != null) {
              try {
                final parsedArgs = jsonDecode(toolArgsBuffer.toString());
                yield LLMResponse(
                  content: '',
                  toolCalls: [
                    ToolCall(
                      id: currentToolId,
                      type: 'function',
                      name: currentToolName ?? '',
                      arguments: parsedArgs,
                    ),
                  ],
                );
              } catch (_) {}
              currentToolId = null;
              currentToolName = null;
              toolArgsBuffer.clear();
            }
          }
        } catch (e) {
          // Skip malformed JSON chunks
          continue;
        }
      }

      // Final accumulated content
      if (buffer.isNotEmpty) {
        yield LLMResponse(content: '');
      }
    } catch (e) {
      if (e is LLMException) rethrow;
      throw LLMException('Stream error: $e');
    }
  }

  /// Validate API connectivity
  Future<bool> validateConnection() async {
    try {
      final response = await client.post(
        Uri.parse('${_config.effectiveBaseUrl}/v1/chat/completions'),
        headers: _config.headers,
        body: jsonEncode({
          'model': _config.effectiveModel,
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 5,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch available models from the API
  Future<List<String>> fetchModels() async {
    try {
      final response = await client.get(
        Uri.parse('${_config.effectiveBaseUrl}/v1/models'),
        headers: _config.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((m) => m['id'] as String)
            .toList();
      }
    } catch (_) {}
    return [
      'deepseek-chat',
      'deepseek-coder',
      'gpt-4o',
      'gpt-4o-mini',
      'claude-sonnet-4',
      'claude-opus-4',
    ];
  }
}

class LLMException implements Exception {
  final String message;
  LLMException(this.message);
  @override
  String toString() => 'LLMException: $message';
}

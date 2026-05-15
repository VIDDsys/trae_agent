import 'dart:convert';

enum MessageRole { user, assistant, system, tool }

enum MessageStatus {
  sending,
  streaming,
  completed,
  error,
  cancelled,
}

enum ToolCallStatus { pending, running, completed, failed }

class ToolCall {
  final String id;
  final String type;
  final String name;
  final Map<String, dynamic> arguments;
  ToolCallStatus status;
  dynamic result;
  String? error;

  ToolCall({
    required this.id,
    required this.type,
    required this.name,
    required this.arguments,
    this.status = ToolCallStatus.pending,
    this.result,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    'arguments': arguments,
    'status': status.name,
    'result': result,
    'error': error,
  };

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
    id: json['id'],
    type: json['type'],
    name: json['name'],
    arguments: Map<String, dynamic>.from(json['arguments']),
    status: ToolCallStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ToolCallStatus.pending,
    ),
    result: json['result'],
    error: json['error'],
  );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final MessageRole role;
  MessageStatus status;
  String content;
  final DateTime timestamp;
  final List<String>? codeBlocks;
  final List<ToolCall> toolCalls;
  final Map<String, dynamic>? metadata;
  String? agentName;
  String? errorMessage;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    this.status = MessageStatus.completed,
    this.content = '',
    DateTime? timestamp,
    this.codeBlocks,
    List<ToolCall>? toolCalls,
    this.metadata,
    this.agentName,
    this.errorMessage,
  })  : timestamp = timestamp ?? DateTime.now(),
        toolCalls = toolCalls ?? [];

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get isError => status == MessageStatus.error;

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'role': role.name,
    'status': status.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'toolCalls': toolCalls.map((t) => t.toJson()).toList(),
    'metadata': metadata,
    'agentName': agentName,
    'errorMessage': errorMessage,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    conversationId: json['conversationId'],
    role: MessageRole.values.firstWhere((e) => e.name == json['role']),
    status: MessageStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => MessageStatus.completed,
    ),
    content: json['content'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    toolCalls: (json['toolCalls'] as List?)
        ?.map((t) => ToolCall.fromJson(t))
        .toList() ?? [],
    metadata: json['metadata'] as Map<String, dynamic>?,
    agentName: json['agentName'],
    errorMessage: json['errorMessage'],
  );

  String toMarkdown() {
    final buf = StringBuffer();
    if (role == MessageRole.user) {
      buf.writeln('**User:** $content');
    } else {
      buf.writeln(content);
    }
    if (toolCalls.isNotEmpty) {
      for (final tc in toolCalls) {
        buf.writeln('\n> 🛠 **${tc.name}** — ${tc.status.name}');
        if (tc.result != null) {
          buf.writeln('> ```\n${tc.result}\n```');
        }
      }
    }
    return buf.toString();
  }
}

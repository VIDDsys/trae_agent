import 'package:flutter/material.dart';
import 'dart:convert';

class Skill {
  final String id;
  final String name;
  final String description;
  final String? command;
  final String? commandType;
  final bool enabled;
  final bool isBuiltin;
  final Map<String, dynamic>? parameters;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    this.command,
    this.commandType,
    this.enabled = false,
    this.isBuiltin = false,
    this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'command': command,
    'commandType': commandType,
    'enabled': enabled,
    'isBuiltin': isBuiltin,
    'parameters': parameters,
  };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    command: json['command'],
    commandType: json['commandType'],
    enabled: json['enabled'] ?? false,
    isBuiltin: json['isBuiltin'] ?? false,
    parameters: json['parameters'] as Map<String, dynamic>?,
  );
}

class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modifiedAt;
  final List<FileItem>? children;

  FileItem({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.size = 0,
    DateTime? modifiedAt,
    this.children,
  }) : modifiedAt = modifiedAt ?? DateTime.now();

  String get extension {
    if (isDirectory) return '';
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get languageFromExtension {
    switch (extension) {
      case 'dart': return 'dart';
      case 'py': return 'python';
      case 'js': case 'jsx': case 'ts': case 'tsx': return 'javascript';
      case 'java': return 'java';
      case 'kt': case 'kts': return 'kotlin';
      case 'swift': return 'swift';
      case 'rs': return 'rust';
      case 'go': return 'go';
      case 'rb': return 'ruby';
      case 'php': return 'php';
      case 'c': case 'h': return 'c';
      case 'cpp': case 'cc': case 'cxx': case 'hpp': return 'cpp';
      case 'cs': return 'csharp';
      case 'html': case 'htm': return 'html';
      case 'css': case 'scss': case 'sass': case 'less': return 'css';
      case 'json': return 'json';
      case 'xml': return 'xml';
      case 'yaml': case 'yml': return 'yaml';
      case 'md': return 'markdown';
      case 'sql': return 'sql';
      case 'sh': case 'bash': case 'zsh': return 'bash';
      case 'dockerfile': return 'dockerfile';
      case 'toml': return 'toml';
      case 'gradle': return 'groovy';
      default: return 'plaintext';
    }
  }
}

class LLMConfig {
  String baseUrl;
  String apiKey;
  String model;
  double temperature;
  int maxTokens;
  int topP;
  bool streamResponse;
  String? customHeaders;

  LLMConfig({
    this.baseUrl = 'https://api.deepseek.com',
    this.apiKey = '',
    this.model = 'deepseek-chat',
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.topP = 1,
    this.streamResponse = true,
    this.customHeaders,
  });

  String get effectiveModel => model;
  String get effectiveBaseUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
    if (customHeaders != null) ...Map<String, String>.from(
      jsonDecode(customHeaders!),
    ),
  };

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'topP': topP,
    'streamResponse': streamResponse,
    'customHeaders': customHeaders,
  };

  factory LLMConfig.fromJson(Map<String, dynamic> json) => LLMConfig(
    baseUrl: json['baseUrl'] ?? 'https://api.deepseek.com',
    apiKey: json['apiKey'] ?? '',
    model: json['model'] ?? 'deepseek-chat',
    temperature: (json['temperature'] ?? 0.7).toDouble(),
    maxTokens: json['maxTokens'] ?? 4096,
    topP: json['topP'] ?? 1,
    streamResponse: json['streamResponse'] ?? true,
    customHeaders: json['customHeaders'],
  );

  LLMConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    int? topP,
    bool? streamResponse,
    String? customHeaders,
  }) => LLMConfig(
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    temperature: temperature ?? this.temperature,
    maxTokens: maxTokens ?? this.maxTokens,
    topP: topP ?? this.topP,
    streamResponse: streamResponse ?? this.streamResponse,
    customHeaders: customHeaders ?? this.customHeaders,
  );
}

class AppSettings {
  LLMConfig llmConfig;
  ThemeMode themeMode;
  bool codeWrap;
  int fontSize;
  bool showLineNumbers;
  bool autoSave;
  String? defaultProjectPath;
  String? gitUserName;
  String? gitUserEmail;
  List<String> quickActions;

  AppSettings({
    LLMConfig? llmConfig,
    this.themeMode = ThemeMode.dark,
    this.codeWrap = false,
    this.fontSize = 14,
    this.showLineNumbers = true,
    this.autoSave = true,
    this.defaultProjectPath,
    this.gitUserName,
    this.gitUserEmail,
    List<String>? quickActions,
  })  : llmConfig = llmConfig ?? LLMConfig(),
        quickActions = quickActions ?? [
          'Explain code',
          'Find bugs',
          'Add comments',
          'Optimize',
          'Write tests',
        ];

  Map<String, dynamic> toJson() => {
    'llmConfig': llmConfig.toJson(),
    'themeMode': themeMode.name,
    'codeWrap': codeWrap,
    'fontSize': fontSize,
    'showLineNumbers': showLineNumbers,
    'autoSave': autoSave,
    'defaultProjectPath': defaultProjectPath,
    'gitUserName': gitUserName,
    'gitUserEmail': gitUserEmail,
    'quickActions': quickActions,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    llmConfig: LLMConfig.fromJson(json['llmConfig'] ?? {}),
    themeMode: ThemeMode.values.firstWhere(
      (e) => e.name == json['themeMode'],
      orElse: () => ThemeMode.dark,
    ),
    codeWrap: json['codeWrap'] ?? false,
    fontSize: json['fontSize'] ?? 14,
    showLineNumbers: json['showLineNumbers'] ?? true,
    autoSave: json['autoSave'] ?? true,
    defaultProjectPath: json['defaultProjectPath'],
    gitUserName: json['gitUserName'],
    gitUserEmail: json['gitUserEmail'],
    quickActions: List<String>.from(json['quickActions'] ?? [
      'Explain code', 'Find bugs', 'Add comments', 'Optimize', 'Write tests',
    ]),
  );
}

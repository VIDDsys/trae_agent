import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ToolResult {
  final String toolCallId;
  final String output;
  final String? error;
  final bool success;

  ToolResult({
    required this.toolCallId,
    this.output = '',
    this.error,
    this.success = true,
  });
}

class ToolExecutionService {
  String? _workspacePath;

  set workspacePath(String? path) => _workspacePath = path;
  String? get workspacePath => _workspacePath;

  Future<ToolResult> executeTool(ToolCall toolCall) async {
    toolCall.status = ToolCallStatus.running;

    try {
      switch (toolCall.name) {
        case 'read_file':
          return await _readFile(toolCall);
        case 'write_file':
          return await _writeFile(toolCall);
        case 'edit_file':
          return await _editFile(toolCall);
        case 'search_code':
          return await _searchCode(toolCall);
        case 'list_directory':
          return await _listDirectory(toolCall);
        case 'web_search':
          return await _webSearch(toolCall);
        default:
          return ToolResult(
            toolCallId: toolCall.id,
            error: 'Unknown tool: ${toolCall.name}',
            success: false,
          );
      }
    } catch (e) {
      toolCall.status = ToolCallStatus.failed;
      toolCall.error = e.toString();
      return ToolResult(
        toolCallId: toolCall.id,
        error: e.toString(),
        success: false,
      );
    }
  }

  /// Resolve path relative to workspace if not absolute
  String _resolvePath(String path) {
    // If workspace is set and path is relative, resolve against workspace
    if (_workspacePath != null && !path.startsWith('/')) {
      return '${_workspacePath!}/$path';
    }
    // If file exists as-is, return it
    if (File(path).existsSync() || Directory(path).existsSync()) {
      return File(path).absolute.path;
    }
    return path;
  }

  Future<ToolResult> _readFile(ToolCall tc) async {
    final path = tc.arguments['path'] as String?;
    if (path == null) {
      return ToolResult(toolCallId: tc.id, error: 'Missing path argument', success: false);
    }

    final resolved = _resolvePath(path);
    final file = File(resolved);
    if (!await file.exists()) {
      return ToolResult(toolCallId: tc.id, error: 'File not found: $resolved', success: false);
    }

    final content = await file.readAsString();
    tc.status = ToolCallStatus.completed;
    tc.result = content;
    return ToolResult(toolCallId: tc.id, output: content);
  }

  Future<ToolResult> _writeFile(ToolCall tc) async {
    final path = tc.arguments['path'] as String?;
    final content = tc.arguments['content'] as String?;
    if (path == null || content == null) {
      return ToolResult(
        toolCallId: tc.id,
        error: 'Missing path or content argument',
        success: false,
      );
    }

    final resolved = _resolvePath(path);
    final file = File(resolved);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);

    tc.status = ToolCallStatus.completed;
    tc.result = 'File written: $resolved (${content.length} chars)';
    return ToolResult(
      toolCallId: tc.id,
      output: 'Successfully wrote ${content.length} characters to $resolved',
    );
  }

  Future<ToolResult> _editFile(ToolCall tc) async {
    final path = tc.arguments['path'] as String?;
    final oldStr = tc.arguments['old_string'] as String?;
    final newStr = tc.arguments['new_string'] as String?;
    if (path == null || oldStr == null || newStr == null) {
      return ToolResult(
        toolCallId: tc.id,
        error: 'Missing path, old_string, or new_string',
        success: false,
      );
    }

    final resolved = _resolvePath(path);
    final file = File(resolved);
    if (!await file.exists()) {
      return ToolResult(toolCallId: tc.id, error: 'File not found: $resolved', success: false);
    }

    String content = await file.readAsString();
    if (!content.contains(oldStr)) {
      return ToolResult(toolCallId: tc.id, error: 'old_string not found in file', success: false);
    }

    content = content.replaceFirst(oldStr, newStr);
    await file.writeAsString(content);
    tc.status = ToolCallStatus.completed;
    tc.result = 'File patched: $resolved';
    return ToolResult(toolCallId: tc.id, output: 'Successfully patched $resolved');
  }

  Future<ToolResult> _searchCode(ToolCall tc) async {
    final query = tc.arguments['query'] as String?;
    final path = tc.arguments['path'] as String? ?? _workspacePath;
    if (query == null || path == null) {
      return ToolResult(toolCallId: tc.id, error: 'Missing query or workspace path', success: false);
    }

    final searchDir = Directory(_resolvePath(path));
    if (!await searchDir.exists()) {
      return ToolResult(toolCallId: tc.id, error: 'Directory not found: $path', success: false);
    }

    final results = <String>[];
    await for (final entity in searchDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = entity.path.split('.').last.toLowerCase();
        if (['dart', 'py', 'js', 'ts', 'java', 'kt', 'swift', 'rs', 'go',
            'rb', 'php', 'c', 'cpp', 'h', 'hpp', 'cs', 'html', 'css',
            'json', 'xml', 'yaml', 'yml', 'md', 'sql', 'sh', 'toml']
            .contains(ext)) {
          try {
            final content = await entity.readAsString();
            if (content.contains(query)) {
              final lines = content.split('\n');
              for (int i = 0; i < lines.length; i++) {
                if (lines[i].contains(query)) {
                  results.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
                  if (results.length >= 50) break;
                }
              }
            }
          } catch (_) {}
        }
      }
      if (results.length >= 50) break;
    }

    final output = results.isEmpty
        ? 'No matches found for "$query"'
        : results.join('\n');
    tc.status = ToolCallStatus.completed;
    tc.result = output;
    return ToolResult(toolCallId: tc.id, output: output);
  }

  Future<ToolResult> _listDirectory(ToolCall tc) async {
    final path = tc.arguments['path'] as String? ?? _workspacePath;
    if (path == null) {
      return ToolResult(toolCallId: tc.id, error: 'No path provided and no workspace set', success: false);
    }

    final dir = Directory(_resolvePath(path));
    if (!await dir.exists()) {
      return ToolResult(toolCallId: tc.id, error: 'Directory not found: $path', success: false);
    }

    final entries = <String>[];
    await for (final entity in dir.list(followLinks: false)) {
      final name = entity.path.split('/').last;
      if (name.startsWith('.') && name != '.gitignore') continue;
      if (name == '.git') continue;
      if (entity is Directory) {
        entries.add('📁 $name/');
      } else {
        final file = entity as File;
        final stat = await file.stat();
        final size = _formatSize(stat.size);
        entries.add('📄 $name ($size)');
      }
    }

    final output = entries.join('\n');
    tc.status = ToolCallStatus.completed;
    tc.result = output;
    return ToolResult(toolCallId: tc.id, output: output);
  }

  /// Web search via HTTP (uses a search API or falls back to mock)
  Future<ToolResult> _webSearch(ToolCall tc) async {
    final query = tc.arguments['query'] as String?;
    final count = tc.arguments['count'] as int? ?? 5;

    if (query == null || query.isEmpty) {
      return ToolResult(toolCallId: tc.id, error: 'Missing query argument', success: false);
    }

    try {
      // Try Tavily-style search API (configurable via settings)
      // For now, use a simple HTTP search approach
      // If no custom search endpoint configured, return a helpful message
      final encodedQuery = Uri.encodeQueryComponent(query);

      // Try DuckDuckGo instant answer as a free search option
      final response = await http.get(
        Uri.parse('https://api.duckduckgo.com/?q=$encodedQuery&format=json&no_html=1'),
        headers: {'User-Agent': 'ViasAgent/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final abstractText = data['AbstractText'] as String? ?? '';
        final abstractSource = data['AbstractSource'] as String? ?? '';
        final relatedTopics = data['RelatedTopics'] as List? ?? [];

        final buffer = StringBuffer();
        if (abstractText.isNotEmpty) {
          buffer.writeln('## Search Results: "$query"');
          buffer.writeln();
          buffer.writeln(abstractText);
          if (abstractSource.isNotEmpty) {
            buffer.writeln('Source: $abstractSource');
          }
          buffer.writeln();
        }

        if (relatedTopics.isNotEmpty) {
          int shown = 0;
          for (final topic in relatedTopics) {
            if (shown >= count) break;
            final text = topic['Text'] as String?;
            final url = topic['FirstURL'] as String?;
            if (text != null) {
              buffer.writeln('- $text');
              if (url != null) buffer.writeln('  $url');
              shown++;
            }
            // Handle nested topics
            final topics = topic['Topics'] as List?;
            if (topics != null) {
              for (final sub in topics) {
                if (shown >= count) break;
                final subText = sub['Text'] as String?;
                final subUrl = sub['FirstURL'] as String?;
                if (subText != null) {
                  buffer.writeln('- $subText');
                  if (subUrl != null) buffer.writeln('  $subUrl');
                  shown++;
                }
              }
            }
          }
        }

        if (buffer.isEmpty) {
          buffer.writeln('No search results found for "$query".');
          buffer.writeln('Try a different query or check your internet connection.');
        }

        final output = buffer.toString().trim();
        tc.status = ToolCallStatus.completed;
        tc.result = output;
        return ToolResult(toolCallId: tc.id, output: output);
      } else {
        throw Exception('Search API returned ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: return a helpful message
      final output = '⚠️ Web search is not available. '
          'The search API request failed: $e\n\n'
          'To use web search, configure a Tavily API key in Settings. '
          'Without it, I can help with code, files, and general knowledge.';
      tc.status = ToolCallStatus.completed;
      tc.result = output;
      return ToolResult(toolCallId: tc.id, output: output, success: false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

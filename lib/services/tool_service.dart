import 'dart:io';
import 'dart:convert';
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

  /// Execute a tool call and return the result
  Future<ToolResult> executeTool(ToolCall toolCall) async {
    toolCall.status = ToolCallStatus.running;

    try {
      switch (toolCall.name) {
        case 'read_file':
          return await _readFile(toolCall);
        case 'write_file':
          return await _writeFile(toolCall);
        case 'search_code':
          return await _searchCode(toolCall);
        case 'run_command':
          return await _runCommand(toolCall);
        case 'list_directory':
          return await _listDirectory(toolCall);
        case 'git_operation':
          return await _gitOperation(toolCall);
        case 'edit_file':
          return await _editFile(toolCall);
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

  String _resolvePath(String path) {
    final p = File(path).absolute;
    if (p.existsSync()) return p.path;
    if (_workspacePath != null) {
      final resolved = '${_workspacePath!}/$path';
      if (File(resolved).existsSync() || Directory(resolved).existsSync()) {
        return resolved;
      }
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
      return ToolResult(toolCallId: tc.id, error: 'old_string not found', success: false);
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
      return ToolResult(toolCallId: tc.id, error: 'Missing query or path', success: false);
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

  Future<ToolResult> _runCommand(ToolCall tc) async {
    final command = tc.arguments['command'] as String?;
    if (command == null) {
      return ToolResult(toolCallId: tc.id, error: 'Missing command argument', success: false);
    }

    try {
      final process = await Process.start(
        'sh',
        ['-c', command],
        workingDirectory: _workspacePath,
        runInShell: true,
      );

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      final exitCode = await process.exitCode;
      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;

      final output = [
        if (stdout.isNotEmpty) stdout,
        if (stderr.isNotEmpty) 'STDERR:\n$stderr',
        '\nExit code: $exitCode',
      ].join('\n');

      tc.status = exitCode == 0
          ? ToolCallStatus.completed
          : ToolCallStatus.failed;
      tc.result = output;
      if (exitCode != 0) tc.error = stderr;

      return ToolResult(
        toolCallId: tc.id,
        output: output,
        error: exitCode != 0 ? stderr : null,
        success: exitCode == 0,
      );
    } catch (e) {
      return ToolResult(
        toolCallId: tc.id,
        error: 'Command execution failed: $e',
        success: false,
      );
    }
  }

  Future<ToolResult> _listDirectory(ToolCall tc) async {
    final path = tc.arguments['path'] as String? ?? _workspacePath;
    if (path == null) {
      return ToolResult(toolCallId: tc.id, error: 'No path provided', success: false);
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

  Future<ToolResult> _gitOperation(ToolCall tc) async {
    final operation = tc.arguments['operation'] as String? ?? 'status';
    final args = tc.arguments['args'] as String? ?? '';

    final gitCmd = 'git $operation $args';
    try {
      final process = await Process.start(
        'sh',
        ['-c', gitCmd],
        workingDirectory: _workspacePath,
        runInShell: true,
      );

      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      final output = [
        if (stdout.isNotEmpty) stdout,
        if (stderr.isNotEmpty) 'STDERR:\n$stderr',
        '\nExit code: $exitCode',
      ].join('\n');

      tc.status = ToolCallStatus.completed;
      tc.result = output;
      return ToolResult(toolCallId: tc.id, output: output);
    } catch (e) {
      return ToolResult(
        toolCallId: tc.id,
        error: 'Git operation failed: $e',
        success: false,
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

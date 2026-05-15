import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'syntax_highlighter.dart';

class CodeEditor extends StatefulWidget {
  final String code;
  final String language;
  final String? filePath;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final int fontSize;

  const CodeEditor({
    super.key,
    required this.code,
    required this.language,
    this.filePath,
    this.readOnly = false,
    this.onChanged,
    this.fontSize = 14,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;
  late ScrollController _verticalScroll;
  late ScrollController _horizontalScroll;
  final LineNumberController _lineNumberController = LineNumberController();
  bool _showLineNumbers = true;
  bool _wrapCode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    _verticalScroll = ScrollController();
    _horizontalScroll = ScrollController();
    _verticalScroll.addListener(_syncLineNumbers);
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code && widget.code != _controller.text) {
      _controller.text = widget.code;
    }
  }

  @override
  void dispose() {
    _verticalScroll.removeListener(_syncLineNumbers);
    _controller.dispose();
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _syncLineNumbers() {
    _lineNumberController.offset = _verticalScroll.offset;
  }

  int get _lineCount => '\n'.allMatches(_controller.text).length + 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header bar
          if (widget.filePath != null) _buildFileHeader(),
          // Editor body
          Expanded(
            child: _wrapCode ? _buildWrappedEditor() : _buildScrollingEditor(),
          ),
          // Status bar
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildFileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1B2E),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(widget.filePath!),
            color: AppColors.fileIcon,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.filePath!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Language badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.language.toUpperCase(),
              style: const TextStyle(
                color: AppColors.accentBlue,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollingEditor() {
    return Scrollbar(
      controller: _verticalScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScroll,
        child: SingleChildScrollView(
          controller: _horizontalScroll,
          scrollDirection: Axis.horizontal,
          child: _buildEditorContent(),
        ),
      ),
    );
  }

  Widget _buildWrappedEditor() {
    return Scrollbar(
      controller: _verticalScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScroll,
        child: _buildEditorContent(),
      ),
    );
  }

  Widget _buildEditorContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers
        if (_showLineNumbers)
          _buildLineNumbers(),
        // Code area
        widget.readOnly ? _buildHighlightedCode() : _buildEditableCode(),
      ],
    );
  }

  Widget _buildLineNumbers() {
    return Container(
      width: 48,
      padding: const EdgeInsets.only(top: 8, right: 8),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_lineCount, (index) {
          return SizedBox(
            height: 20,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppColors.textMuted.withOpacity(0.6),
                fontSize: widget.fontSize - 1,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHighlightedCode() {
    final highlighted = SyntaxHighlighter.highlight(
      _controller.text,
      widget.language,
    );

    return Container(
      padding: const EdgeInsets.only(left: 12, top: 8, right: 16, bottom: 8),
      constraints: _wrapCode
          ? BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 64,
      )
          : null,
      child: RichText(
        text: highlighted,
        maxLines: _wrapCode ? null : _lineCount,
      ),
    );
  }

  Widget _buildEditableCode() {
    return SizedBox(
      width: _wrapCode
          ? null
          : (_controller.text.length * 8.0).clamp(200, 3000),
      child: TextField(
        controller: _controller,
        maxLines: null,
        style: TextStyle(
          color: Colors.transparent,
          fontSize: widget.fontSize.toDouble(),
          fontFamily: 'monospace',
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(left: 12, top: 8, right: 16, bottom: 8),
          isDense: true,
        ),
        keyboardType: TextInputType.multiline,
        onChanged: (value) {
          setState(() {});
          widget.onChanged?.call(value);
        },
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1B2E),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Ln ${_getCursorLine()}, Col ${_getCursorColumn()}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_lineCount} lines',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          if (widget.readOnly)
            const Text(
              'READ ONLY',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  int _getCursorLine() {
    final text = _controller.text;
    final pos = _controller.selection.baseOffset;
    if (pos <= 0) return 1;
    return '\n'.allMatches(text.substring(0, pos.clamp(0, text.length))).length + 1;
  }

  int _getCursorColumn() {
    final text = _controller.text;
    final pos = _controller.selection.baseOffset.clamp(0, text.length);
    final lastNewline = text.lastIndexOf('\n', pos - 1);
    return pos - lastNewline;
  }

  IconData _getFileIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart': return Icons.code;
      case 'py': return Icons.code;
      case 'js': case 'ts': return Icons.javascript;
      case 'json': return Icons.data_object;
      case 'md': return Icons.description;
      case 'yaml': case 'yml': return Icons.settings;
      case 'html': return Icons.language;
      case 'css': return Icons.palette;
      case 'java': case 'kt': return Icons.code;
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'svg': return Icons.image;
      case 'pdf': return Icons.picture_as_pdf;
      case 'sh': case 'bash': return Icons.terminal;
      case 'sql': return Icons.storage;
      default: return Icons.insert_drive_file;
    }
  }
}

class LineNumberController {
  double offset = 0;
}

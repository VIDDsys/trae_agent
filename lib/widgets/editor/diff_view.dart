import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'syntax_highlighter.dart';

/// Unified Diff View — renders git-style diff output with syntax highlighting
class DiffView extends StatelessWidget {
  final String diffText;
  final String? language;
  final double fontSize;

  const DiffView({
    super.key,
    required this.diffText,
    this.language,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final lines = diffText.split('\n');
    final parsed = _parseDiff(lines);

    return Container(
      color: AppColors.backgroundCode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1B2E),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, color: AppColors.accentBlue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Diff View',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${parsed.additions} additions, ${parsed.deletions} deletions',
                  style: TextStyle(
                    color: parsed.additions > 0 ? AppColors.success : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Diff content
          Expanded(
            child: ListView.builder(
              itemCount: parsed.lines.length,
              itemBuilder: (context, index) {
                final line = parsed.lines[index];
                return _buildLine(line, language, fontSize);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(DiffLine line, String? lang, double fontSize) {
    Color bgColor;
    Color textColor;
    String prefix;
    Color lineNumColor;

    switch (line.type) {
      case DiffType.addition:
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        prefix = '+';
        lineNumColor = AppColors.success.withOpacity(0.5);
      case DiffType.deletion:
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        prefix = '-';
        lineNumColor = AppColors.error.withOpacity(0.5);
      case DiffType.header:
        bgColor = AppColors.accentBlue.withOpacity(0.05);
        textColor = AppColors.accentBlue;
        prefix = ' ';
        lineNumColor = AppColors.accentBlue.withOpacity(0.3);
      case DiffType.hunk:
        bgColor = AppColors.accentPurple.withOpacity(0.08);
        textColor = AppColors.accentPurpleLight;
        prefix = '@';
        lineNumColor = const Color(0x00000000);
      case DiffType.context:
        bgColor = Colors.transparent;
        textColor = AppColors.textPrimary;
        prefix = ' ';
        lineNumColor = AppColors.textMuted.withOpacity(0.3);
      default:
        bgColor = Colors.transparent;
        textColor = AppColors.textPrimary;
        prefix = ' ';
        lineNumColor = AppColors.textMuted;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers
          SizedBox(
            width: 56,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: line.oldLineNum != null
                      ? Text(
                    line.oldLineNum.toString(),
                    style: TextStyle(
                      color: lineNumColor,
                      fontSize: fontSize - 1,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  )
                      : const SizedBox(),
                ),
                SizedBox(
                  width: 28,
                  child: line.newLineNum != null
                      ? Text(
                    line.newLineNum.toString(),
                    style: TextStyle(
                      color: lineNumColor,
                      fontSize: fontSize - 1,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
          // Prefix
          SizedBox(
            width: 16,
            child: Text(
              prefix,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
          // Content
          Expanded(
            child: line.type == DiffType.addition || line.type == DiffType.deletion
                ? RichText(
              text: SyntaxHighlighter.highlight(line.content, lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
                : Text(
              line.content,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontFamily: 'monospace',
                height: 1.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _ParsedDiff _parseDiff(List<String> lines) {
    final parsedLines = <DiffLine>[];
    int additions = 0;
    int deletions = 0;
    int oldLine = 0;
    int newLine = 0;

    for (final line in lines) {
      if (line.startsWith('---') || line.startsWith('+++')) {
        parsedLines.add(DiffLine(DiffType.header, line, null, null));
        continue;
      }
      if (line.startsWith('@@')) {
        // Parse hunk header: @@ -oldStart,oldCount +newStart,newCount @@
        final match = RegExp(r'@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@').firstMatch(line);
        if (match != null) {
          oldLine = int.parse(match.group(1)!);
          newLine = int.parse(match.group(2)!);
        }
        parsedLines.add(DiffLine(DiffType.hunk, line, null, null));
        continue;
      }
      if (line.startsWith('+')) {
        parsedLines.add(DiffLine(DiffType.addition, line.substring(1), null, newLine));
        additions++;
        newLine++;
      } else if (line.startsWith('-')) {
        parsedLines.add(DiffLine(DiffType.deletion, line.substring(1), oldLine, null));
        deletions++;
        oldLine++;
      } else {
        parsedLines.add(DiffLine(DiffType.context, line, oldLine, newLine));
        oldLine++;
        newLine++;
      }
    }

    return _ParsedDiff(parsedLines, additions, deletions);
  }
}

enum DiffType { addition, deletion, header, hunk, context, normal }

class DiffLine {
  final DiffType type;
  final String content;
  final int? oldLineNum;
  final int? newLineNum;

  DiffLine(this.type, this.content, this.oldLineNum, this.newLineNum);
}

class _ParsedDiff {
  final List<DiffLine> lines;
  final int additions;
  final int deletions;

  _ParsedDiff(this.lines, this.additions, this.deletions);
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/colors.dart';
import '../../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isTool = message.role == MessageRole.tool;

    if (isTool && (message.content.isEmpty || message.content == 'No output')) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Role label
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_outline : Icons.auto_awesome,
                  size: 14,
                  color: isUser ? AppColors.accentBlue : AppColors.accentPurple,
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? 'You' : (isTool ? 'Tool' : 'Vias'),
                  style: TextStyle(
                    color: isUser ? AppColors.accentBlue : AppColors.accentPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Message content
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.accentBlue.withOpacity(0.15)
                  : (isTool
                      ? AppColors.surfaceLight
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
              border: isTool
                  ? Border.all(color: AppColors.border.withOpacity(0.5))
                  : null,
            ),
            child: isUser
                ? Text(
                    message.content,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  )
                : _buildMarkdownContent(),
          ),
          // Tool calls (if any)
          if (message.toolCalls.isNotEmpty)
            ...message.toolCalls.map((tc) => _buildToolCallCard(tc)),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent() {
    final content = message.content;
    if (content.isEmpty) return const SizedBox.shrink();

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
        h1: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
        h2: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
        h3: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        code: const TextStyle(
          color: AppColors.textCode,
          fontSize: 13,
          fontFamily: 'monospace',
          backgroundColor: Color(0xFF1E293B),
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.05),
          border: const Border(left: BorderSide(color: AppColors.accentBlue, width: 3)),
        ),
        a: const TextStyle(color: AppColors.accentBlue, decoration: TextDecoration.underline),
        del: const TextStyle(color: AppColors.textMuted, decoration: TextDecoration.lineThrough),
        strong: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        em: const TextStyle(color: AppColors.textPrimary, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildToolCallCard(ToolCall tc) {
    IconData icon;
    Color color;
    String label;

    switch (tc.name) {
      case 'read_file':
        icon = Icons.description;
        color = AppColors.info;
        label = 'Read file';
      case 'write_file':
        icon = Icons.edit;
        color = AppColors.success;
        label = 'Write file';
      case 'edit_file':
        icon = Icons.find_replace;
        color = AppColors.warning;
        label = 'Edit file';
      case 'search_code':
        icon = Icons.search;
        color = AppColors.info;
        label = 'Search code';
      case 'list_directory':
        icon = Icons.folder_open;
        color = AppColors.info;
        label = 'List directory';
      case 'web_search':
        icon = Icons.language;
        color = AppColors.accentPurple;
        label = 'Web search';
      default:
        icon = Icons.code;
        color = AppColors.textMuted;
        label = tc.name;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            tc.status == ToolCallStatus.running
                ? Icons.hourglass_top
                : (tc.status == ToolCallStatus.completed
                    ? Icons.check_circle
                    : Icons.error),
            size: 12,
            color: tc.status == ToolCallStatus.completed
                ? AppColors.success
                : (tc.status == ToolCallStatus.failed ? AppColors.error : AppColors.warning),
          ),
        ],
      ),
    );
  }
}

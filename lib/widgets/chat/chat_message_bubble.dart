import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/colors.dart';
import '../../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserMessage(context);
    }
    return _buildAssistantMessage(context);
  }

  Widget _buildUserMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4079FF), Color(0xFF5B8DEF)],
            ),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: Radius.zero,
            ),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: AppColors.userBubbleText,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent name header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                'Trae Agent',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message.isStreaming) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentBlue,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Error state
          if (message.isError)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.errorMessage ?? 'An error occurred',
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Tool calls
          if (message.toolCalls.isNotEmpty)
            ...message.toolCalls.map((tc) => _buildToolCallCard(tc)),

          // Content
          if (message.content.isNotEmpty)
            _buildMarkdownContent(context),

          // Streaming indicator
          if (message.isStreaming && message.content.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Thinking...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MarkdownBody(
        data: message.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          // Text styles
          p: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
          h1: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
          h2: const TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.bold, height: 1.4),
          h3: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
          h4: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
          h5: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
          h6: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),

          // List



          listBullet: const TextStyle(color: AppColors.accentBlue),

          // Code blocks
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
          // codeblockTextStyle removed for compatibility
            color: AppColors.textCode,
            fontSize: 13,
            fontFamily: 'monospace',
            height: 1.5,
          ),
          codeblockPadding: const EdgeInsets.all(16),

          // Inline code
          codeblockAlignment: Alignment.centerLeft,

          // Blockquote
          blockquoteDecoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.05),
            border: const Border(
              left: BorderSide(color: AppColors.accentBlue, width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          blockquote: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),

          // Links
          a: const TextStyle(color: AppColors.accentBlue, decoration: TextDecoration.underline),

          // Tables
          tableBorder: TableBorder.all(color: AppColors.border, width: 1),
          tableHead: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          tableBody: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          tableCellsPadding: const EdgeInsets.all(8),
          tableColumnWidth: const FlexColumnWidth(),

          // Horizontal rule
          horizontalRuleDecoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),

          // Del (strikethrough)
          del: const TextStyle(color: AppColors.textMuted, decoration: TextDecoration.lineThrough),

          // Strong
          strong: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),

          // Emphasis
          em: const TextStyle(color: AppColors.textPrimary, fontStyle: FontStyle.italic),

          // Checkbox
          checkbox: const TextStyle(color: AppColors.accentBlue),
        ),
        onTapLink: (text, href, title) {
          // Handle link taps
        },
      ),
    );
  }

  Widget _buildToolCallCard(ToolCall tc) {
    IconData icon;
    Color color;
    switch (tc.name) {
      case 'read_file':
        icon = Icons.description;
        color = AppColors.info;
        break;
      case 'write_file':
        icon = Icons.edit;
        color = AppColors.success;
        break;
      case 'search_code':
        icon = Icons.search;
        color = AppColors.warning;
        break;
      case 'run_command':
        icon = Icons.terminal;
        color = const Color(0xFF00FF00);
        break;
      case 'git_operation':
        icon = Icons.call_split;
        color = AppColors.accentPurple;
        break;
      case 'list_directory':
        icon = Icons.folder;
        color = AppColors.folderIcon;
        break;
      default:
        icon = Icons.build;
        color = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            tc.name.replaceAll('_', ' '),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(tc.status),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _statusLabel(tc.status),
            style: TextStyle(
              color: _statusColor(tc.status),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.pending: return AppColors.textMuted;
      case ToolCallStatus.running: return AppColors.warning;
      case ToolCallStatus.completed: return AppColors.success;
      case ToolCallStatus.failed: return AppColors.error;
    }
  }

  String _statusLabel(ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.pending: return 'pending';
      case ToolCallStatus.running: return 'running...';
      case ToolCallStatus.completed: return 'done';
      case ToolCallStatus.failed: return 'failed';
    }
  }
}

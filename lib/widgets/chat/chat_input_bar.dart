import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onRetry;
  final bool isSending;
  final bool isInitialized;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onRetry,
    required this.isSending,
    required this.isInitialized,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: widget.isSending ? null : (_) => _send(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          // Send / Stop button
          Padding(
            padding: const EdgeInsets.all(6),
            child: GestureDetector(
              onTap: widget.isSending ? null : _send,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isSending
                      ? AppColors.textMuted.withOpacity(0.2)
                      : AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isSending ? Icons.stop : Icons.arrow_upward,
                  color: widget.isSending ? AppColors.textMuted : Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

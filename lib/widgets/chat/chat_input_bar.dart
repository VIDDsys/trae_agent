import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ChatInputBar extends StatefulWidget {
  final void Function(String) onSend;
  final bool isProcessing;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final bool apiKeyConfigured;
  final VoidCallback onConfigureApi;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.isProcessing,
    required this.onCancel,
    required this.onRetry,
    required this.apiKeyConfigured,
    required this.onConfigureApi,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isProcessing) return;

    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSurface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // API key warning
          if (!widget.apiKeyConfigured)
            GestureDetector(
              onTap: widget.onConfigureApi,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.warning.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'API key not configured. Tap to set up.',
                        style: TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: AppColors.warning, size: 12),
                  ],
                ),
              ),
            ),

          // Input row
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: widget.apiKeyConfigured ? 12 : 8,
              bottom: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach files button
                _buildIconButton(Icons.attach_file, () {
                  // TODO: File picker
                }),
                const SizedBox(width: 4),

                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundInput,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _hasText ? AppColors.accentBlue : AppColors.border,
                        width: _hasText ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Ask me anything...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _handleSend(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Send / Cancel button
                if (widget.isProcessing)
                  _buildIconButton(Icons.stop_circle_outlined, widget.onCancel,
                      color: AppColors.error)
                else
                  _buildIconButton(
                    _hasText ? Icons.arrow_upward : Icons.mic_none,
                    _hasText ? _handleSend : () {},
                    color: _hasText ? AppColors.accentBlue : AppColors.textMuted,
                    filled: _hasText,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onTap,
      {Color color = AppColors.textMuted, bool filled = false}) {
    return Material(
      color: filled ? AppColors.accentBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: filled ? Colors.white : color,
            size: 22,
          ),
        ),
      ),
    );
  }
}

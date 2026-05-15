import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/colors.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_input_bar.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final messages = chatProvider.currentMessages;

        return Column(
          children: [
            // Messages list
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ChatMessageBubble(message: msg);
                      },
                    ),
            ),
            // Input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ChatInputBar(
                onSend: (text) => chatProvider.sendMessage(text),
                onRetry: () => chatProvider.retry(),
                isSending: chatProvider.isSending,
                isInitialized: chatProvider.isInitialized,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: AppColors.accentBlue.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'How can I help you?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me to write code, debug issues, or search the web',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

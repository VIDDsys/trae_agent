import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/colors.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    // Auto-scroll when messages update
    context.read<ChatProvider>().addListener(_onMessagesChanged);
  }

  @override
  void dispose() {
    context.read<ChatProvider>().removeListener(_onMessagesChanged);
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessagesChanged() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, SettingsProvider>(
      builder: (context, chat, settings, _) {
        return Column(
          children: [
            // Messages area
            Expanded(
              child: chat.messages.isEmpty
                  ? _buildEmptyState(chat)
                  : _buildMessageList(chat),
            ),
            // Quick actions
            if (chat.messages.isEmpty && !chat.isProcessing)
              _buildQuickActions(chat),
            // Input bar
            ChatInputBar(
              onSend: (text) => chat.sendMessageStream(text),
              isProcessing: chat.isProcessing,
              onCancel: () => chat.cancelProcessing(),
              onRetry: () => chat.retryLastMessage(),
              apiKeyConfigured: settings.hasApiKey,
              onConfigureApi: () {
                context.read<SettingsProvider>().load();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ChatProvider chat) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo / illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Trae Agent',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered coding assistant\nAsk me anything about your code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Suggested prompts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _suggestionChip('Explain this code', chat),
              _suggestionChip('Find bugs', chat),
              _suggestionChip('Write unit tests', chat),
              _suggestionChip('Optimize performance', chat),
              _suggestionChip('Refactor', chat),
              _suggestionChip('Add documentation', chat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String label, ChatProvider chat) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentBlue,
          fontSize: 13,
        ),
      ),
      backgroundColor: AppColors.accentBlue.withOpacity(0.1),
      side: const BorderSide(color: AppColors.accentBlue, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => chat.sendMessageStream(label),
    );
  }

  Widget _buildMessageList(ChatProvider chat) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        return ChatMessageBubble(message: message);
      },
    );
  }

  Widget _buildQuickActions(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _quickActionChip('💡 Explain', () => chat.sendMessageStream('Explain the current file')),
          const SizedBox(width: 8),
          _quickActionChip('🐛 Debug', () => chat.sendMessageStream('Find and fix bugs in the current file')),
          const SizedBox(width: 8),
          _quickActionChip('📝 Refactor', () => chat.sendMessageStream('Refactor the current file for better code quality')),
        ],
      ),
    );
  }

  Widget _quickActionChip(String label, VoidCallback onTap) {
    return Material(
      color: AppColors.backgroundHover,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

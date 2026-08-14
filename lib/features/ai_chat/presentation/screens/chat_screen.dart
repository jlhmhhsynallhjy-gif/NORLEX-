import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/model_selector.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';

class ChatScreen extends ConsumerWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider(conversationId));
    final controller = ref.read(chatControllerProvider(conversationId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(chatState.conversation?.title ?? 'Chat'),
        actions: [
          ModelSelector(conversationId: conversationId),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'regenerate') controller.regenerateLast();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'regenerate', child: Text('Regenerate')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.error != null) ErrorBanner(message: chatState.error!),
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isLoading
                ? ChatEmptyState(onSuggestionTap: (s) => controller.sendMessage(s))
                : ListView.builder(
                    reverse: false,
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return MessageBubble(
                        message: msg,
                        onRetry: msg.isFailed ? () => controller.retryMessage(msg.id) : null,
                        onRegenerate: !msg.isUser ? () => controller.regenerateLast() : null,
                        onDelete: () => controller.deleteMessage(msg.id),
                      );
                    },
                  ),
          ),
          ChatComposer(
            isStreaming: chatState.isStreaming,
            onSend: controller.sendMessage,
            onStop: controller.cancelGeneration,
            onAttach: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File attachment - foundation ready, implementation next phase')));
            },
            onVoice: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice input - foundation ready')));
            },
          ),
        ],
      ),
    );
  }
}

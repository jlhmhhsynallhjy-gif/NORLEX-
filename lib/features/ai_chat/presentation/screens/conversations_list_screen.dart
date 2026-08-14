import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_providers.dart';
import '../../../ai_chat/domain/usecases/create_conversation_usecase.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(filteredConversationsProvider);
    final searchQuery = ref.watch(conversationsSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NORLEX Chats'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search conversations...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => ref.read(conversationsSearchProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: conversationsAsync.when(
        data: (convs) {
          if (convs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(searchQuery.isEmpty ? 'No conversations yet' : 'No results for "\$searchQuery"'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _createNewChat(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('New Chat'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: convs.length,
            itemBuilder: (context, i) {
              final c = convs[i];
              return ListTile(
                title: Text(c.title),
                subtitle: Text(c.updatedAt.toString()),
                trailing: PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    const PopupMenuItem(value: 'archive', child: Text('Archive')),
                  ],
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final repo = ref.read(conversationRepositoryProvider);
                      await repo.deleteConversation(c.id);
                      ref.invalidate(conversationsProvider);
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id)));
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: \$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewChat(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNewChat(BuildContext context, WidgetRef ref) async {
    final usecase = ref.read(createConversationUseCaseProvider);
    final result = await usecase.call(userId: 'local_user', title: 'New Chat \${DateTime.now().hour}:\${DateTime.now().minute}');
    result is Success ? ref.invalidate(conversationsProvider) : null;
    if (result is Success) {
      final conv = (result as Success).data as dynamic;
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id)));
      }
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import 'chat_screen.dart';
import '../../../../core/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(filteredConversationsProvider);
    final searchQuery = ref.watch(conversationsSearchProvider);
    final authState = ref.watch(authControllerProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'محادثات نورلكس' : 'NORLEX Chats'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.push(AppRoutes.profile), tooltip: 'Profile'),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.welcome);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'logout', child: Text(isRtl ? 'تسجيل خروج' : 'Logout')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(hintText: isRtl ? 'بحث...' : 'Search conversations...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder()),
              onChanged: (v) => ref.read(conversationsSearchProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (authState.user != null)
            ListTile(
              leading: CircleAvatar(child: Text(authState.user!.email[0].toUpperCase())),
              title: Text(authState.user!.email),
              subtitle: Text(authState.user!.fullName ?? ''),
              dense: true,
            ),
          Expanded(
            child: conversationsAsync.when(
              data: (convs) {
                if (convs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64),
                        const SizedBox(height: 16),
                        Text(searchQuery.isEmpty ? (isRtl ? 'لا توجد محادثات' : 'No conversations yet') : 'No results'),
                        const SizedBox(height: 16),
                        FilledButton.icon(onPressed: () => _createNewChat(context, ref), icon: const Icon(Icons.add), label: Text(isRtl ? 'محادثة جديدة' : 'New Chat')),
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
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c.id))),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: \$e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _createNewChat(context, ref), child: const Icon(Icons.add)),
    );
  }

  Future<void> _createNewChat(BuildContext context, WidgetRef ref) async {
    final usecase = ref.read(createConversationUseCaseProvider);
    final authState = ref.read(authControllerProvider);
    final userId = authState.user?.id ?? 'unknown';
    final result = await usecase.call(userId: userId, title: 'New Chat \${DateTime.now().hour}:\${DateTime.now().minute}');
    if (result.isSuccess) {
      ref.invalidate(conversationsProvider);
      final conv = result.dataOrNull as dynamic;
      if (conv != null && context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id)));
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_controller.dart';
import '../providers/chat_providers.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import '../../auth/providers/auth_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(userConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: conversationsState.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start a new chat by searching for another user.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewChatScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('Start new chat'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final currentUser = ref.watch(authStateProvider).value;

              final title = currentUser == null
                  ? 'Chat'
                  : conversation.displayNameFor(currentUser.uid);

              final subtitle = currentUser == null
                  ? ''
                  : conversation.lastMessage ??
                        conversation.displayEmailFor(currentUser.uid);

              return ListTile(
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: conversation.id,
                        chatTitle: 'Chat',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load conversations.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your connection or try again shortly.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
        },
        icon: const Icon(Icons.chat),
        label: const Text('New Chat'),
      ),
    );
  }
}

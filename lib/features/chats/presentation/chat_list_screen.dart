import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_controller.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(userConversationsProvider);
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
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

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];

              final title = currentUser == null
                  ? 'Chat'
                  : conversation.displayNameFor(currentUser.uid);

              final subtitle = currentUser == null
                  ? ''
                  : conversation.lastMessage ??
                        conversation.displayEmailFor(currentUser.uid);

              final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(child: Text(initial)),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: conversation.id,
                          chatTitle: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Unable to load conversations. Please try again.',
              textAlign: TextAlign.center,
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

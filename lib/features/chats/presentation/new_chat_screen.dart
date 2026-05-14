import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import 'chat_screen.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startConversation({required String otherUserId}) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    final conversationId = await ref
        .read(chatRepositoryProvider)
        .createOrGetConversation(
          currentUserId: currentUser.uid,
          otherUserId: otherUserId,
        );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(conversationId: conversationId, chatTitle: 'New Chat'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(userSearchQueryProvider);
    final searchResults = ref.watch(searchedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.trim().isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(userSearchQueryProvider.notifier).clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(userSearchQueryProvider.notifier).updateQuery(value);
              },
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? const _SearchPrompt()
                : searchResults.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return const _EmptySearchResult();
                      }
                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];

                          // final displayName =
                          //     user['displayName'] as String? ?? 'User';
                          // final email = user['email'] as String? ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(user.displayName),
                            subtitle: Text(user.email),
                            trailing: const Icon(Icons.chat_bubble_outline),
                            onTap: () {
                              _startConversation(otherUserId: user.uid);
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => const _SearchError(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 56),
            SizedBox(height: 16),
            Text(
              'Search for someone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Enter an email address to find a user and start a conversation.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 56),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Check the email address and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56),
            SizedBox(height: 16),
            Text(
              'Unable to search users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

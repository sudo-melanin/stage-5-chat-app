import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../../../core/utils/time_formatter.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.chatTitle,
  });

  final String conversationId;
  final String chatTitle;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  Timer? _typingTimer;

  @override
  void dispose() {
    _textController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    await ref
        .read(chatRepositoryProvider)
        .setTypingStatus(
          conversationId: widget.conversationId,
          userId: currentUser.uid,
          isTyping: false,
        );

    await ref
        .read(chatRepositoryProvider)
        .sendTextMessage(
          conversationId: widget.conversationId,
          senderId: currentUser.uid,
          text: text,
        );
  }

  void _handleTyping(String value) {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    ref
        .read(chatRepositoryProvider)
        .setTypingStatus(
          conversationId: widget.conversationId,
          userId: currentUser.uid,
          isTyping: true,
        );

    _typingTimer?.cancel();

    _typingTimer = Timer(const Duration(seconds: 2), () {
      ref
          .read(chatRepositoryProvider)
          .setTypingStatus(
            conversationId: widget.conversationId,
            userId: currentUser.uid,
            isTyping: false,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final messagesState = ref.watch(messagesProvider(widget.conversationId));
    final conversationState = ref.watch(
      conversationProvider(widget.conversationId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.chatTitle)),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hello 👋'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == currentUser?.uid;

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(message.text),
                            const SizedBox(height: 4),
                            Text(
                              TimeFormatter.relative(message.createdAt),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
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
                    'Unable to load messages. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          conversationState.when(
            data: (conversation) {
              if (conversation == null || currentUser == null) {
                return const SizedBox.shrink();
              }

              final isTyping = conversation.isOtherUserTyping(currentUser.uid);

              if (!isTyping) return const SizedBox.shrink();

              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Typing...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),

              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _handleTyping,
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,

                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

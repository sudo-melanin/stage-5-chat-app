import 'dart:async';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_formatter.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/message.dart';
import '../providers/chat_providers.dart';

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
  int _recordSeconds = 0;
  Timer? _recordTimer;

  bool _isSearching = false;
  String _searchQuery = '';
  final _recorder = AudioRecorder();
  bool _isRecording = false;

  DateTime? _recordStart;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textController.dispose();
    _recorder.dispose();
    _recordTimer?.cancel();
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

  void _showReactionPicker(Message message) {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: emojis.map((emoji) {
                final isCurrentReaction =
                    message.reactions[currentUser.uid] == emoji;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    Navigator.pop(dialogContext);

                    if (isCurrentReaction) {
                      await ref
                          .read(chatRepositoryProvider)
                          .removeReaction(
                            conversationId: widget.conversationId,
                            messageId: message.id,
                            userId: currentUser.uid,
                          );
                    } else {
                      await ref
                          .read(chatRepositoryProvider)
                          .setReaction(
                            conversationId: widget.conversationId,
                            messageId: message.id,
                            userId: currentUser.uid,
                            emoji: emoji,
                          );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showMessageActions({required Message message, required bool isMine}) {
    if (message.deletedForEveryone) return;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReactionPicker(message);
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit message'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditMessageDialog(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete for me'),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  final currentUser = ref.read(authStateProvider).value;
                  if (currentUser == null) return;

                  await ref
                      .read(chatRepositoryProvider)
                      .deleteMessageForMe(
                        conversationId: widget.conversationId,
                        messageId: message.id,
                        userId: currentUser.uid,
                      );
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Delete for everyone'),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await ref
                        .read(chatRepositoryProvider)
                        .deleteMessageForEveryone(
                          conversationId: widget.conversationId,
                          messageId: message.id,
                        );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditMessageDialog(Message message) {
    final editController = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: editController,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Update your message',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final updatedText = editController.text.trim();
                if (updatedText.isEmpty) return;

                Navigator.pop(dialogContext);

                await ref
                    .read(chatRepositoryProvider)
                    .editMessage(
                      conversationId: widget.conversationId,
                      messageId: message.id,
                      text: updatedText,
                    );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReactionBadge(Message message, bool isMine) {
    if (message.reactions.isEmpty || message.deletedForEveryone) {
      return const SizedBox.shrink();
    }

    return Transform.translate(
      offset: const Offset(0, -6),
      child: Container(
        margin: EdgeInsets.only(left: isMine ? 0 : 14, right: isMine ? 14 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.reactions.values.toSet().join(' '),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required Message message,
    required bool isMine,
    required String currentUserId,
  }) {
    return GestureDetector(
      onLongPress: () => _showMessageActions(message: message, isMine: isMine),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isAudio && message.audioUrl != null)
                    AudioMessageBubble(
                      audioUrl: message.audioUrl!,
                      durationMs: message.audioDurationMs ?? 0,
                    )
                  else
                    HighlightedMessageText(
                      text: message.visibleText,
                      query: _searchQuery,
                    ),
                  if (message.isEdited && !message.deletedForEveryone) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Edited',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TimeFormatter.relative(message.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 6),
                        Text(
                          message.statusFor(currentUserId),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _buildReactionBadge(message, isMine),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) return;

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: filePath);

    _recordStart = DateTime.now();
    _recordSeconds = 0;

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
      });
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording({required bool send}) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    final path = await _recorder.stop();

    _recordTimer?.cancel();

    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (!send || path == null) return;

    final duration = DateTime.now().difference(_recordStart ?? DateTime.now());

    await ref
        .read(chatRepositoryProvider)
        .sendAudioMessage(
          conversationId: widget.conversationId,
          senderId: currentUser.uid,
          filePath: path,
          durationMs: duration.inMilliseconds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final messagesState = ref.watch(messagesProvider(widget.conversationId));
    final conversationState = ref.watch(
      conversationProvider(widget.conversationId),
    );

    if (currentUser != null) {
      ref
          .read(chatRepositoryProvider)
          .markMessagesDeliveredAndSeen(
            conversationId: widget.conversationId,
            userId: currentUser.uid,
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(widget.chatTitle),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchQuery = '';
              });
            },
          ),
        ],
      ),
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

                final visibleMessages = _searchQuery.trim().isEmpty
                    ? messages
                    : messages
                          .where(
                            (message) => message.matchesSearch(_searchQuery),
                          )
                          .toList();

                if (visibleMessages.isEmpty) {
                  return const Center(
                    child: Text('No matching messages found.'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleMessages.length,
                  itemBuilder: (context, index) {
                    final message = visibleMessages[index];
                    final currentUserId = currentUser?.uid ?? '';

                    if (message.isDeletedFor(currentUserId)) {
                      return const SizedBox.shrink();
                    }

                    final isMine = message.senderId == currentUserId;

                    return _buildMessageBubble(
                      message: message,
                      isMine: isMine,
                      currentUserId: currentUserId,
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
              child: _isRecording
                  ? RecordingBar(
                      seconds: _recordSeconds,
                      onCancel: () => _stopRecording(send: false),
                      onSend: () => _stopRecording(send: true),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onChanged: _handleTyping,
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
                        IconButton(
                          icon: const Icon(Icons.mic),
                          onPressed: _startRecording,
                        ),
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

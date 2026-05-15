import 'package:flutter/material.dart';

import '../../../core/utils/time_formatter.dart';
import '../models/message.dart';
import 'widgets.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.currentUserId,
    required this.searchQuery,
    required this.onLongPress,
  });

  final Message message;
  final bool isMine;
  final String currentUserId;
  final String searchQuery;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
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
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMine
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.deletedForEveryone)
                    const Text(
                      'This message was deleted.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  else if (message.isAudio && message.audioUrl != null)
                    AudioMessageBubble(
                      audioUrl: message.audioUrl!,
                      durationMs: message.audioDurationMs ?? 0,
                    )
                  else
                    HighlightedMessageText(
                      text: message.visibleText,
                      query: searchQuery,
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
            _ReactionBadge(message: message, isMine: isMine),
          ],
        ),
      ),
    );
  }
}

class _ReactionBadge extends StatelessWidget {
  const _ReactionBadge({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
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
}

import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onStartRecording,
    required this.onSendMessage,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onStartRecording;
  final VoidCallback onSendMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: 'Type a message',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Record voice note',
          icon: const Icon(Icons.mic),
          onPressed: onStartRecording,
        ),
        IconButton.filled(
          tooltip: 'Send message',
          icon: const Icon(Icons.send),
          onPressed: onSendMessage,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class RecordingBar extends StatelessWidget {
  const RecordingBar({
    super.key,
    required this.seconds,
    required this.onCancel,
    required this.onSend,
  });

  final int seconds;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  String get _formattedTime {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bars = [10.0, 18.0, 12.0, 24.0, 16.0, 28.0, 14.0, 20.0];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancel recording',
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onCancel,
          ),
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
          const SizedBox(width: 8),
          Text(
            _formattedTime,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bars.map((height) {
                return Container(
                  width: 4,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            tooltip: 'Send recording',
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

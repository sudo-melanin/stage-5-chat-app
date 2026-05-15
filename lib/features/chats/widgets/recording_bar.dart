import 'dart:math';
import 'package:flutter/material.dart';

class RecordingBar extends StatefulWidget {
  const RecordingBar({
    super.key,
    required this.seconds,
    required this.onCancel,
    required this.onSend,
  });

  final int seconds;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  State<RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<RecordingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _time {
    final m = widget.seconds ~/ 60;
    final s = widget.seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: widget.onCancel,
          ),

          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
          const SizedBox(width: 8),

          Text(
            'Recording... $_time',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(12, (i) {
                    final height =
                        8 + (sin(_controller.value * pi * 2 + i) * 10).abs();

                    return Container(
                      width: 3,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: widget.onSend,
          ),
        ],
      ),
    );
  }
}

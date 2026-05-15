import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioMessageBubble extends StatefulWidget {
  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationMs,
  });

  final String audioUrl;
  final int durationMs;

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final _player = AudioPlayer();

  double _speed = 1.0;
  bool _hasLoadedAudio = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    _player.playerStateStream.listen((state) async {
      if (!mounted) return;

      if (state.processingState == ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
        setState(() => _position = Duration.zero);
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }

    if (!_hasLoadedAudio) {
      await _player.setUrl(widget.audioUrl);
      _hasLoadedAudio = true;
    }

    await _player.setSpeed(_speed);
    await _player.play();
  }

  Future<void> _toggleSpeed() async {
    _speed = _speed == 1.0 ? 2.0 : 1.0;
    await _player.setSpeed(_speed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = Duration(milliseconds: widget.durationMs);
    final remaining = total - _position;
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_player.playing ? Icons.pause_circle : Icons.play_circle),
          onPressed: _togglePlayback,
        ),
        Text(_formatDuration(safeRemaining)),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _toggleSpeed,
          child: Text('${_speed.toStringAsFixed(0)}x'),
        ),
      ],
    );
  }
}

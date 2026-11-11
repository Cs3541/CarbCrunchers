import 'dart:async';

import 'package:flutter/material.dart';

class TimerChip extends StatefulWidget {
  final int seconds;
  final VoidCallback? onDone;

  const TimerChip({super.key, required this.seconds, this.onDone});

  @override
  State<TimerChip> createState() => _TimerChipState();
}

class _TimerChipState extends State<TimerChip> {
  late int _remaining = widget.seconds;
  Timer? _ticker;
  DateTime? _endsAt;

  bool get _running => _ticker?.isActive ?? false;
  bool get _done => _remaining <= 0;

  void reset(int seconds) {
    _ticker?.cancel();
    setState(() {
      _remaining = seconds;
      _endsAt = null;
    });
  }

  void pause() {
    _ticker?.cancel();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void start() {
    if (_running || _done) return;
    _endsAt = DateTime.now().add(Duration(seconds: _remaining));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _endsAt!.difference(DateTime.now()).inSeconds;
      // Only clamp at zero, so reset() with a larger value still works.
      setState(() => _remaining = left < 0 ? 0 : left);
      // Called outside setState so the parent can safely update itself.
      if (_done) {
        _ticker?.cancel();
        widget.onDone?.call();
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (_running) {
              pause();
            } else {
              start();
            }
          },
        ),
        Chip(
          label: Text(
            '$minutes:${seconds.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

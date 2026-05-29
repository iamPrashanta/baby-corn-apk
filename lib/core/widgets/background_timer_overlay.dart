import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class BackgroundTimerOverlay extends StatefulWidget {
  const BackgroundTimerOverlay({super.key});

  @override
  State<BackgroundTimerOverlay> createState() => _BackgroundTimerOverlayState();
}

class _BackgroundTimerOverlayState extends State<BackgroundTimerOverlay> {
  DateTime? _startTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map && event['type'] == 'timer_sync') {
        final ms = event['startTimeMs'] as int;
        setState(() {
          _startTime = DateTime.fromMillisecondsSinceEpoch(ms);
        });
        _startTick();
      }
    });
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_startTime == null) return const SizedBox.shrink();

    final duration = DateTime.now().difference(_startTime!);
    final durationStr = _formatDuration(duration);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                durationStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await FlutterOverlayWindow.closeOverlay();
                },
                child: const Icon(Icons.close_rounded, color: Colors.red, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

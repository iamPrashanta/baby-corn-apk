import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TimerOverlay(),
  ));
}

class TimerOverlay extends StatefulWidget {
  const TimerOverlay({super.key});

  @override
  State<TimerOverlay> createState() => _TimerOverlayState();
}

class _TimerOverlayState extends State<TimerOverlay> {
  DateTime? _startTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start listening to data sent from the main app
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event != null && event is Map) {
        if (event['type'] == 'timer_sync') {
          final startTimeMs = event['startTimeMs'] as int?;
          if (startTimeMs != null) {
            setState(() {
              _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
            });
          }
        }
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        setState(() {}); // Trigger rebuild to update elapsed time
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Bring app to foreground when clicked
        // Note: FlutterOverlayWindow doesn't have an explicit 'openApp' but we can share a 'click' event
        // or close the overlay
        await FlutterOverlayWindow.closeOverlay();
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                _startTime != null
                    ? _formatDuration(DateTime.now().difference(_startTime!))
                    : '00:00',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/core/design/layouts/floating_timer_overlay.dart

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../features/records/presentation/providers/active_session_provider.dart';
import '../../../features/records/domain/models/active_session_model.dart';
import '../../../core/local_storage/hive_manager.dart';
import '../tokens/colors.dart';
import '../../../core/services/haptic_service.dart';
import '../components/dialogs/timer_full_sheet.dart';
import '../components/dialogs/save_success_overlay.dart';

class FloatingTimerOverlay extends ConsumerStatefulWidget {
  const FloatingTimerOverlay({super.key});

  @override
  ConsumerState<FloatingTimerOverlay> createState() =>
      _FloatingTimerOverlayState();
}

class _FloatingTimerOverlayState extends ConsumerState<FloatingTimerOverlay>
    with SingleTickerProviderStateMixin {
  bool _showSuccess = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isMinimized = false;
  bool _hideTemporarily = false;
  Offset _position = const Offset(16, 100); 
  bool _isDragging = false;
  
  Timer? _minimizeTimer;
  Timer? _pulsePeriodicTimer;
  String? _lastSessionId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pulse only once every 60 seconds
    _pulsePeriodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
         _pulseController.forward().then((_) => _pulseController.reverse());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final box = HiveManager.getSettingsBox();
      final double? x = box.get('floating_timer_x');
      final double? y = box.get('floating_timer_y');

      setState(() {
        if (x != null && y != null) {
          _position = Offset(x, y);
        } else {
          // Default position: bottom right above nav bar
          _position = Offset(size.width - 120, size.height - 150);
        }
      });
    });
  }

  @override
  void dispose() {
    _minimizeTimer?.cancel();
    _pulsePeriodicTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? "$hours:$minutes:$seconds"
        : "$minutes:$seconds";
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('feed')) return Icons.water_drop_rounded;
    if (t.contains('sleep')) return Icons.bedtime_rounded;
    if (t.contains('tummy')) return Icons.child_care_rounded;
    return Icons.timer_rounded;
  }

  Color _getColorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('feed')) return AppColors.feeding;
    if (t.contains('sleep')) return AppColors.sleep;
    if (t.contains('tummy')) return AppColors.tertiary;
    return AppColors.primary;
  }

  Future<void> _handleStop() async {
    final record =
        await ref.read(activeSessionProvider.notifier).stopAndSaveSession();
    if (record != null && mounted) {
      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
         setState(() {
            _showSuccess = false;
            _hideTemporarily = false;
            _isMinimized = false;
            _lastSessionId = null;
         });
      }
    }
  }

  void _openFullSheet() {
    HapticService.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TimerFullSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;

    if (_showSuccess) {
      return const SaveSuccessOverlay();
    }

    final recoveredSession = ref.watch(recoveredSessionProvider);
    if (recoveredSession != null) {
       return _TimerRecoveryOverlay(session: recoveredSession);
    }

    // Listen for open action from notifications
    ref.listen(timerSheetOpenProvider, (previous, next) {
      if (next == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(timerSheetOpenProvider.notifier).state = false;
        });
        _openFullSheet();
      }
    });

    if (activeSession == null) {
      _lastSessionId = null;
      _isMinimized = false;
      _hideTemporarily = false;
      _minimizeTimer?.cancel();
      return const SizedBox.shrink();
    }

    if (activeSession.id != _lastSessionId) {
      _lastSessionId = activeSession.id;
      _isMinimized = false;
      _hideTemporarily = false;
      _minimizeTimer?.cancel();
      _minimizeTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _isMinimized = true);
      });
    }

    if (_hideTemporarily) {
      return const SizedBox.shrink();
    }

    final duration = activeSession.currentDuration;
    final durationStr = _formatDuration(duration);
    final accentColor = _getColorForType(activeSession.type);
    final icon = _getIconForType(activeSession.type);
    final isPaused = !activeSession.isRunning;

    if (!_isMinimized) {
      // FULL EXPANDED BANNER
      return Positioned(
        top: topPadding + 8,
        left: 16,
        right: 16,
        child: GestureDetector(
          onTap: _openFullSheet,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
              setState(() => _isMinimized = true);
              _minimizeTimer?.cancel();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accentColor, size: 20),
                        ),
                        if (!isPaused)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: FadeTransition(
                              opacity: _pulseAnimation,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isPaused
                                ? '${activeSession.type} (Paused)'
                                : activeSession.type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightTextSecondary,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            durationStr,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                          onPressed: () {
                            HapticService.selectionClick();
                            if (isPaused) {
                              ref.read(activeSessionProvider.notifier).resumeSession();
                            } else {
                              ref.read(activeSessionProvider.notifier).pauseSession();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop_rounded,
                              color: Colors.redAccent),
                          onPressed: () {
                            HapticService.mediumImpact();
                            _handleStop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .slideY(begin: -1.0, duration: 400.ms, curve: Curves.easeOutBack)
            .fadeIn(),
      );
    }

    // FLOATING MINIMIZED PILL
    final bool isSnappedRight = !_isDragging && _position.dx >= size.width / 2;
    final bool isSnappedLeft = !_isDragging && _position.dx < size.width / 2;

    return Positioned(
      left: isSnappedRight ? null : (isSnappedLeft ? 16 : _position.dx),
      right: isSnappedRight ? 16 : null,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() => _isDragging = true);
        },
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (details) {
          setState(() => _isDragging = false);
          final velocity = details.velocity.pixelsPerSecond;
          
          if (velocity.dx > 1500 || velocity.dx < -1500) {
            setState(() => _hideTemporarily = true);
            return;
          }
          
          double newY = _position.dy;
          if (newY < topPadding + 16) newY = topPadding + 16;
          if (newY > size.height - 100) newY = size.height - 100;
          
          setState(() {
            _position = Offset(_position.dx, newY);
          });
          
          final box = HiveManager.getSettingsBox();
          box.put('floating_timer_x', _position.dx);
          box.put('floating_timer_y', _position.dy);
        },
        onTap: _openFullSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_isDragging ? 1.05 : 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(icon, color: accentColor, size: 20),
                        if (!isPaused)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: FadeTransition(
                              opacity: _pulseAnimation,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      durationStr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}

class _TimerRecoveryOverlay extends ConsumerStatefulWidget {
  final ActiveSessionModel session;
  const _TimerRecoveryOverlay({required this.session});
  
  @override
  ConsumerState<_TimerRecoveryOverlay> createState() => _TimerRecoveryOverlayState();
}

class _TimerRecoveryOverlayState extends ConsumerState<_TimerRecoveryOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(activeSessionProvider.notifier).finalizeRecoveredSession(widget.session);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final startTimeStr = "${widget.session.startTime.hour % 12 == 0 ? 12 : widget.session.startTime.hour % 12}:${widget.session.startTime.minute.toString().padLeft(2, '0')} ${widget.session.startTime.hour >= 12 ? 'PM' : 'AM'}";
      
      final finalEndTimeStr = widget.session.metadata['finalEndTime'];
      final endTime = finalEndTimeStr != null ? DateTime.parse(finalEndTimeStr) : DateTime.now();
      final endTimeStr = "${endTime.hour % 12 == 0 ? 12 : endTime.hour % 12}:${endTime.minute.toString().padLeft(2, '0')} ${endTime.hour >= 12 ? 'PM' : 'AM'}";
      
      final duration = endTime.difference(widget.session.startTime) - Duration(seconds: widget.session.totalPausedDurationSeconds);
      final durationStr = "${duration.inMinutes}m";

      return Positioned(
         top: MediaQuery.of(context).padding.top + 8,
         left: 16,
         right: 16,
         child: Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: isDark ? Colors.black87 : Colors.white,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: Colors.greenAccent, width: 2),
             boxShadow: [
               BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 20),
             ],
           ),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.cloud_done_rounded, color: Colors.greenAccent, size: 32),
               const SizedBox(height: 8),
               Text('${widget.session.type} Session Recovered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
               const SizedBox(height: 4),
               Text('Started: $startTimeStr | Stopped: $endTimeStr\nDuration: $durationStr', 
                 textAlign: TextAlign.center,
                 style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, height: 1.4)),
               const SizedBox(height: 8),
               Text('[Auto-saving in 3s...]', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
             ],
           )
         ).animate().slideY(begin: -1.0, curve: Curves.easeOutBack).fadeIn()
      );
  }
}


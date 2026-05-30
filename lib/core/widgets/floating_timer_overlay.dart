// core/widgets/floating_timer_overlay.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/records/presentation/providers/active_session_provider.dart';
import '../constants/app_colors.dart';
import '../services/haptic_service.dart';
import 'timer_full_sheet.dart';
import 'save_success_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
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
    final record = await ref
        .read(activeSessionProvider.notifier)
        .stopAndSaveSession();
    if (record != null && mounted) {
      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _showSuccess = false);
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

    if (_showSuccess) {
      return const SaveSuccessOverlay();
    }

    if (activeSession == null) {
      return const SizedBox.shrink();
    }

    final duration = activeSession.currentDuration;
    final durationStr = _formatDuration(duration);
    final accentColor = _getColorForType(activeSession.type);
    final icon = _getIconForType(activeSession.type);
    final isPaused = !activeSession.isRunning;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _openFullSheet,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.6)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
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
                  // Icon with pulsing dot
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
                  // Title & Timer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isPaused ? '${activeSession.type} (Paused)' : activeSession.type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
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
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quick Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: isDark ? Colors.white : AppColors.textPrimary,
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
                        icon: const Icon(Icons.stop_rounded, color: Colors.redAccent),
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
      ).animate().slideY(begin: -1.0, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }
}

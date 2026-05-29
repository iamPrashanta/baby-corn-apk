// core/widgets/floating_timer_overlay.dart



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/records/presentation/providers/active_session_provider.dart';
import '../constants/app_colors.dart';
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
  // Position state for dragging
  double _xPos = 16;
  double _yPos = 100;
  bool _isDragging = false;
  bool _showSuccess = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
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

  void _snapToEdge(Size screenSize) {
    final centerX = _xPos + 90; // half of capsule width ~180
    setState(() {
      if (centerX < screenSize.width / 2) {
        _xPos = 12;
      } else {
        _xPos = screenSize.width - 192; // capsule width + margin
      }
    });
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
    HapticFeedback.lightImpact();
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
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show success overlay
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

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _xPos = (_xPos + details.delta.dx)
                .clamp(0, screenSize.width - 192);
            _yPos = (_yPos + details.delta.dy)
                .clamp(MediaQuery.of(context).padding.top + 8,
                    screenSize.height - 200);
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _snapToEdge(screenSize);
        },
        onTap: _openFullSheet,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = activeSession.isRunning
                  ? _pulseAnimation.value
                  : 1.0;

              return Transform.scale(
                scale: _isDragging ? 1.08 : scale,
                child: child,
              );
            },
            child: _buildCapsule(
              isDark: isDark,
              accentColor: accentColor,
              icon: icon,
              durationStr: durationStr,
              isRunning: activeSession.isRunning,
              activeSession: activeSession,
            ),
          ),
        ),
      )
          .animate()
          .scaleXY(begin: 0.5, end: 1.0, duration: 300.ms,
              curve: Curves.easeOutBack)
          .fadeIn(duration: 200.ms),
    );
  }

  Widget _buildCapsule({
    required bool isDark,
    required Color accentColor,
    required IconData icon,
    required String durationStr,
    required bool isRunning,
    required dynamic activeSession,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark
            ? const Color(0xFF1E1C20).withOpacity(0.92)
            : const Color(0xFFFFFEFB).withOpacity(0.92),
        border: Border.all(
          width: 0.8,
          color: accentColor.withOpacity(isDark ? 0.3 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isRunning ? 0.15 : 0.08),
            blurRadius: isRunning ? 20 : 12,
            spreadRadius: isRunning ? 1 : -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Activity icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 8),

          // Timer display
          Text(
            durationStr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),

          // Pause/Play button
          _MiniButton(
            icon: isRunning
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: accentColor,
            onTap: () {
              HapticFeedback.selectionClick();
              if (isRunning) {
                ref.read(activeSessionProvider.notifier).pauseSession();
              } else {
                ref.read(activeSessionProvider.notifier).resumeSession();
              }
            },
          ),
          const SizedBox(width: 4),

          // Stop button
          _MiniButton(
            icon: Icons.stop_rounded,
            color: const Color(0xFFFF6B6B),
            onTap: _handleStop,
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

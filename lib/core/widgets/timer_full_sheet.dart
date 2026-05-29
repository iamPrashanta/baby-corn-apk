// core/widgets/timer_full_sheet.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/records/presentation/providers/active_session_provider.dart';
import '../constants/app_colors.dart';
import 'save_success_overlay.dart';

class TimerFullSheet extends ConsumerStatefulWidget {
  const TimerFullSheet({super.key});

  @override
  ConsumerState<TimerFullSheet> createState() => _TimerFullSheetState();
}

class _TimerFullSheetState extends ConsumerState<TimerFullSheet>
    with SingleTickerProviderStateMixin {
  final _notesController = TextEditingController();
  late AnimationController _ringController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Load existing notes from session metadata
    final session = ref.read(activeSessionProvider);
    if (session != null && session.metadata['note'] != null) {
      _notesController.text = session.metadata['note'] as String;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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

  String _getDisplayName(String type) {
    final t = type.toLowerCase();
    if (t.contains('left') && t.contains('feed')) return 'Left Breast Feeding';
    if (t.contains('right') && t.contains('feed')) return 'Right Breast Feeding';
    if (t.contains('feed')) return 'Feeding';
    if (t.contains('sleep')) return 'Sleep';
    if (t.contains('tummy')) return 'Tummy Time';
    return type;
  }

  bool _isFeeding(String type) {
    return type.toLowerCase().contains('feed');
  }

  Future<void> _handleStop() async {
    // Save notes before stopping
    if (_notesController.text.isNotEmpty) {
      ref.read(activeSessionProvider.notifier).updateMetadata({
        'note': _notesController.text,
      });
    }

    final record =
        await ref.read(activeSessionProvider.notifier).stopAndSaveSession();
    if (record != null && mounted) {
      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _switchFeedingSide() {
    final session = ref.read(activeSessionProvider);
    if (session == null) return;

    HapticFeedback.selectionClick();
    final currentSide = session.metadata['side'] as String? ?? 'Left Breast';
    final newSide =
        currentSide == 'Left Breast' ? 'Right Breast' : 'Left Breast';

    ref.read(activeSessionProvider.notifier).updateMetadata({
      'side': newSide,
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showSuccess) {
      return const SaveSuccessOverlay();
    }

    if (activeSession == null) {
      // Session was stopped externally
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final duration = activeSession.currentDuration;
    final durationStr = _formatDuration(duration);
    final accentColor = _getColorForType(activeSession.type);
    final displayName = _getDisplayName(activeSession.type);
    final icon = _getIconForType(activeSession.type);
    final isFeeding = _isFeeding(activeSession.type);
    final currentSide =
        activeSession.metadata['side'] as String? ?? 'Left Breast';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1820).withOpacity(0.92)
              : const Color(0xFFFFFDF9).withOpacity(0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          left: 28,
          right: 28,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Activity icon + title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.1, end: 0, duration: 300.ms),

            const SizedBox(height: 32),

            // Timer ring + display
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated progress ring
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: _TimerRingPainter(
                          progress: (duration.inSeconds % 60) / 60.0,
                          color: accentColor,
                          isRunning: activeSession.isRunning,
                          glowOpacity:
                              0.3 + 0.2 * math.sin(_ringController.value * 2 * math.pi),
                        ),
                      );
                    },
                  ),
                  // Timer text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        durationStr,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeSession.isRunning
                              ? accentColor.withOpacity(0.12)
                              : Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activeSession.isRunning ? 'Running' : 'Paused',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: activeSession.isRunning
                                ? accentColor
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .scaleXY(begin: 0.8, end: 1.0, duration: 400.ms,
                    curve: Curves.easeOutBack)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 28),

            // Feeding side switch
            if (isFeeding) ...[
              _FeedingSideSwitch(
                currentSide: currentSide,
                accentColor: accentColor,
                isDark: isDark,
                onSwitch: _switchFeedingSide,
              ),
              const SizedBox(height: 20),
            ],

            // Controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause/Resume button
                _ControlButton(
                  icon: activeSession.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: activeSession.isRunning ? 'Pause' : 'Resume',
                  color: accentColor,
                  isDark: isDark,
                  size: 64,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (activeSession.isRunning) {
                      ref.read(activeSessionProvider.notifier).pauseSession();
                    } else {
                      ref.read(activeSessionProvider.notifier).resumeSession();
                    }
                  },
                ),
                const SizedBox(width: 24),
                // Stop/Save button
                _ControlButton(
                  icon: Icons.stop_rounded,
                  label: 'Save',
                  color: const Color(0xFFFF6B6B),
                  isDark: isDark,
                  size: 56,
                  onTap: _handleStop,
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 200.ms),

            const SizedBox(height: 24),

            // Notes field
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: TextField(
                controller: _notesController,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.25)
                        : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.shade400,
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(activeSessionProvider.notifier)
                      .updateMetadata({'note': value});
                },
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 300.ms),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TIMER RING PAINTER
// ─────────────────────────────────────────────────────────
class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isRunning;
  final double glowOpacity;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.isRunning,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color.withOpacity(isRunning ? 0.8 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow dot at progress tip
    if (isRunning && progress > 0) {
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final glowPaint = Paint()
        ..color = color.withOpacity(glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(dotCenter, 5, glowPaint);
      canvas.drawCircle(dotCenter, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}

// ─────────────────────────────────────────────────────────
// FEEDING SIDE SWITCH
// ─────────────────────────────────────────────────────────
class _FeedingSideSwitch extends StatelessWidget {
  final String currentSide;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onSwitch;

  const _FeedingSideSwitch({
    required this.currentSide,
    required this.accentColor,
    required this.isDark,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = currentSide == 'Left Breast';

    return GestureDetector(
      onTap: onSwitch,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SideChip(
              label: 'Left',
              isActive: isLeft,
              color: accentColor,
              isDark: isDark,
            ),
            const SizedBox(width: 4),
            _SideChip(
              label: 'Right',
              isActive: !isLeft,
              color: accentColor,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SideChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final bool isDark;

  const _SideChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive
              ? color
              : (isDark ? Colors.white38 : Colors.grey.shade500),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CONTROL BUTTON
// ─────────────────────────────────────────────────────────
class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final double size;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.size,
    required this.onTap,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: widget.size * 0.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// core/widgets/save_success_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

/// Animated success checkmark overlay shown after saving a timer record.
/// Auto-appears with scale + fade animation, then fades out.
class SaveSuccessOverlay extends StatelessWidget {
  const SaveSuccessOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1C20).withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF4CAF50),
                size: 30,
              ),
            )
                .animate()
                .scaleXY(
                    begin: 0.0,
                    end: 1.0,
                    duration: 400.ms,
                    curve: Curves.easeOutBack)
                .fadeIn(duration: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Saved',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideY(begin: 0.3, end: 0, duration: 300.ms, delay: 200.ms),
          ],
        ),
      )
          .animate()
          .scaleXY(
              begin: 0.6, end: 1.0, duration: 350.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 200.ms)
          .then(delay: 800.ms)
          .fadeOut(duration: 300.ms),
    );
  }
}

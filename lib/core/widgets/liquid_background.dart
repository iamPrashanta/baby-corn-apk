// core/widgets/liquid_background.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/glass_system/glass_colors.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background color
        Container(
          color: isDark ? GlassColors.warmCharcoal : GlassColors.creamWhite,
        ),
        
        // Floating Blob 1 (Top Right) — wrapped in RepaintBoundary
        Positioned(
          top: -100,
          right: -100,
          child: RepaintBoundary(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? GlassColors.mutedLavender : GlassColors.blushPink).withOpacity(0.5),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.2, duration: 4000.ms, curve: Curves.easeInOutSine)
             .moveX(begin: 0, end: -30, duration: 5000.ms, curve: Curves.easeInOutSine),
          ),
        ),

        // Floating Blob 2 (Bottom Left) — wrapped in RepaintBoundary
        Positioned(
          bottom: -50,
          left: -100,
          child: RepaintBoundary(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? GlassColors.softBrownBlack : GlassColors.peach).withOpacity(0.6),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.3, duration: 6000.ms, curve: Curves.easeInOutSine)
             .moveY(begin: 0, end: -40, duration: 5500.ms, curve: Curves.easeInOutSine),
          ),
        ),

        // Removed unnecessary BackdropFilter — it was using ColorFilter.mode 
        // which doesn't actually blur anything but forces rasterization, 
        // hurting performance on low-end devices.
        
        // Foreground Content
        child,
      ],
    );
  }
}

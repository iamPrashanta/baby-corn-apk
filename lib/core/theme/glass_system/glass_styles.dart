import 'package:flutter/material.dart';
import 'glass_colors.dart';

class GlassStyles {
  /// Base decoration for a warm light-mode glass container
  static BoxDecoration lightGlassDecoration({double borderRadius = 24.0}) {
    return BoxDecoration(
      color: GlassColors.lightGlassSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: GlassColors.lightGlassBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: GlassColors.lightGlassGlow,
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Base decoration for a cozy dark-mode glass container
  static BoxDecoration darkGlassDecoration({double borderRadius = 24.0}) {
    return BoxDecoration(
      color: GlassColors.darkGlassSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: GlassColors.darkGlassBorder,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: GlassColors.darkGlassGlow,
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Adaptive decoration based on Theme mode
  static BoxDecoration adaptiveGlassDecoration(BuildContext context, {double borderRadius = 24.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
      ? darkGlassDecoration(borderRadius: borderRadius)
      : lightGlassDecoration(borderRadius: borderRadius);
  }

  /// Adaptive gradient highlight overlay (for liquid shine effect)
  static BoxDecoration adaptiveLiquidHighlight(BuildContext context, {double borderRadius = 24.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: isDark ? GlassColors.darkLiquidHighlight : GlassColors.lightLiquidHighlight,
    );
  }
}

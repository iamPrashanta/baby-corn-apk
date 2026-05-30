import 'dart:ui';
import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final bool useGlass;
  final double sigma;
  final Color? glassColorLight;
  final Color? glassColorDark;
  final Color? solidColorLight;
  final Color? solidColorDark;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.useGlass = false,
    this.sigma = 18.0,
    this.glassColorLight,
    this.glassColorDark,
    this.solidColorLight,
    this.solidColorDark,
    this.borderColor,
    this.padding = const EdgeInsets.only(left: 24, right: 24, top: 16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define colors
    final bgLight = useGlass
        ? (glassColorLight ?? const Color(0xFFFFFDF9).withOpacity(0.92))
        : (solidColorLight ?? const Color(0xFFFDFBF7));
    final bgDark = useGlass
        ? (glassColorDark ?? const Color(0xFF1A1820).withOpacity(0.92))
        : (solidColorDark ?? const Color(0xFF1A1820));

    final bgColor = isDark ? bgDark : bgLight;

    // Border
    final border = Border(
      top: BorderSide(
        color: borderColor ??
            (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        width: 0.5,
      ),
    );

    // Padding that accounts for keyboard and safe area
    final EdgeInsets mergedPadding = EdgeInsets.only(
      left: padding.resolve(Directionality.of(context)).left,
      right: padding.resolve(Directionality.of(context)).right,
      top: padding.resolve(Directionality.of(context)).top,
      bottom: MediaQuery.of(context).viewInsets.bottom +
          MediaQuery.of(context).padding.bottom +
          24,
    );

    Widget content = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: border,
      ),
      padding: mergedPadding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ],
        ),
      ),
    );

    if (useGlass) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: content,
      );
    } else {
      return content;
    }
  }
}

import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/shadows.dart';

enum AppButtonType { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildContent() {
      if (isLoading) {
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: type == AppButtonType.outline || type == AppButtonType.text
                ? (color ?? AppColors.primary)
                : Colors.white,
          ),
        );
      }

      if (icon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text),
          ],
        );
      }

      return Text(text);
    }

    ButtonStyle getStyle() {
      switch (type) {
        case AppButtonType.primary:
          return ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // Handled by Ink
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
        case AppButtonType.secondary:
          return ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.surfaceHighlight,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
        case AppButtonType.outline:
          return OutlinedButton.styleFrom(
            foregroundColor: color ?? AppColors.primaryBlue,
            side: BorderSide(color: color ?? AppColors.primaryBlue, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
        case AppButtonType.text:
          return TextButton.styleFrom(
            foregroundColor: color ?? AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
      }
    }

    Widget button;
    
    if (type == AppButtonType.outline) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: getStyle(),
        child: buildContent(),
      );
    } else if (type == AppButtonType.text) {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: getStyle(),
        child: buildContent(),
      );
    } else if (type == AppButtonType.primary) {
      button = Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.buttonBorder,
          gradient: LinearGradient(
            colors: [
              color ?? AppColors.primaryBlue,
              (color ?? AppColors.primaryBlue).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppShadows.glowShadow,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: getStyle(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: buildContent(),
          ),
        ),
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: getStyle(),
        child: buildContent(),
      );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

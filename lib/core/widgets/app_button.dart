import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

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
            backgroundColor: color ?? AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
        case AppButtonType.secondary:
          return ElevatedButton.styleFrom(
            backgroundColor: color ?? (isDark ? AppColors.darkSurface : AppColors.secondaryContainer),
            foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
        case AppButtonType.outline:
          return OutlinedButton.styleFrom(
            foregroundColor: color ?? AppColors.primary,
            side: BorderSide(color: color ?? AppColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
        case AppButtonType.text:
          return TextButton.styleFrom(
            foregroundColor: color ?? AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorder),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
          );
      }
    }

    final button = type == AppButtonType.outline
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: getStyle(),
            child: buildContent(),
          )
        : type == AppButtonType.text
            ? TextButton(
                onPressed: isLoading ? null : onPressed,
                style: getStyle(),
                child: buildContent(),
              )
            : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: getStyle(),
                child: buildContent(),
              );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

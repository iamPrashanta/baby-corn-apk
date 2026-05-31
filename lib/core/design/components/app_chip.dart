import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';

class AppChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool isOutlined;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  const AppChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.isOutlined = false,
    this.onTap,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = color ?? AppColors.primary;

    final backgroundColor = isOutlined
        ? Colors.transparent
        : baseColor.withOpacity(0.15);
    final textColor = baseColor;
    final borderColor = isOutlined ? baseColor : baseColor.withOpacity(0.3);

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: textColor,
            fontSize: 13,
          ),
        ),
        if (onDeleted != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            child: Icon(Icons.close, size: 16, color: textColor),
          ),
        ],
      ],
    );

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.buttonBorder,
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonBorder,
        child: content,
      );
    }

    return content;
  }
}

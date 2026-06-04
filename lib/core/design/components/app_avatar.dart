// lib/core/design/components/app_avatar.dart

import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/shadows.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initial;
  final double radius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.initial,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceHighlight,
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: AppShadows.glowShadow,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          color: AppColors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

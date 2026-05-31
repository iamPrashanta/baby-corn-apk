// core/design/tokens/theme.dart

import 'package:flutter/material.dart';
import 'colors.dart';
import 'radius.dart';
import 'typography.dart';
import 'shadows.dart';

class AppTheme {
  // Premium Dark Theme - Used globally
  static ThemeData get _premiumDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        primaryContainer: AppColors.primaryBlue,
        secondary: AppColors.successGreen,
        secondaryContainer: AppColors.successGreen,
        surface: AppColors.surface,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.white,
        error: AppColors.errorRed,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.getTextTheme(isDark: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonBorder,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHighlight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.white.withOpacity(0.5),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get lightTheme => _premiumDarkTheme;
  static ThemeData get darkTheme => _premiumDarkTheme;
}

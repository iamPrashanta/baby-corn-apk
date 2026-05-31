import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (from user)
  static const Color primary = Color(0xFFFF7A59);
  static const Color secondary = Color(0xFF6C63FF);

  // Semantic Colors (from user)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Surface and Background (from user)
  static const Color background = Color(0xFFF8F8FA);
  static const Color surface = Color(0xFFFFFFFF);

  // Text Colors (from user)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  
  // Legacy Colors (Kept temporarily to prevent compile errors during migration)
  static const Color primaryContainer = Color(0xFFFFD8D3);
  static const Color secondaryContainer = Color(0xFFCBF1F5);
  static const Color tertiary = Color(0xFFE2D5F8);
  static const Color tertiaryContainer = Color(0xFFF1EBFE);
  
  static const Color border = Color(0xFFE8E9F1);
  
  static const Color feeding = Color(0xFFFFB2A6);
  static const Color sleep = Color(0xFFA6E3E9);
  static const Color diaper = Color(0xFFE2D5F8);
  static const Color urination = Color(0xFFFFF2CD);
  static const Color stool = Color(0xFFE6D5C3);
  static const Color mood = Color(0xFFC4E8C2);
  static const Color vaccine = Color(0xFF81C784);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFDFBF7);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
}

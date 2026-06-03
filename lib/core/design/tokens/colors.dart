import 'package:flutter/material.dart';

class AppColors {
  // --- STRICT OFFICIAL COLOR SYSTEM ---
  
  // Primary Background
  static const Color background = Color(0xFF001524);
  
  // White
  static const Color white = Color(0xFFFFFFFF);
  
  // Primary Blue
  static const Color primaryBlue = Color(0xFF3472F6);
  
  // Success Green
  static const Color successGreen = Color(0xFF2FAF62);
  
  // Error Red
  static const Color errorRed = Color(0xFF881D1A);

  // --- SEMANTIC ALIASES ---
  static const Color primary = primaryBlue;
  static const Color secondary = successGreen;
  
  static const Color success = successGreen;
  static const Color warning = errorRed; // No yellow/orange allowed
  static const Color error = errorRed;
  static const Color info = primaryBlue;

  // Surface and Background
  static const Color surface = Color(0xFF001524); // Same as background
  static const Color surfaceHighlight = Color(0x0CFFFFFF); // 5% white for cards
  
  // Text Colors
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color lightTextPrimary = Colors.black87;
  static const Color lightTextSecondary = Colors.black54;
  
  // --- LEGACY MAPPINGS (To prevent compile errors during Phase 3 migration) ---
  static const Color primaryContainer = primaryBlue;
  static const Color secondaryContainer = successGreen;
  static const Color tertiary = primaryBlue;
  static const Color tertiaryContainer = successGreen;
  
  static const Color border = Color(0x1AFFFFFF); // 10% white
  
  // Legacy Feature Colors mapped to strict colors
  static const Color feeding = primaryBlue;
  static const Color sleep = primaryBlue;
  static const Color diaper = primaryBlue;
  static const Color urination = successGreen;
  static const Color stool = successGreen;
  static const Color mood = successGreen;
  static const Color vaccine = primaryBlue;
  
  // Dark theme colors mapped to strict background
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkTextPrimary = textPrimary;
  static const Color darkTextSecondary = textSecondary;
}

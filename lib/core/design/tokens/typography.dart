import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  static TextTheme getTextTheme({required bool isDark}) {
    final color = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final colorSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(
        color: color,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.nunito(
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.nunito(
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.nunito(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.nunito(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.nunito(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.nunito(
        color: color,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.nunito(
        color: colorSecondary,
        fontSize: 14,
      ),
      bodySmall: GoogleFonts.nunito(
        color: colorSecondary,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.nunito(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

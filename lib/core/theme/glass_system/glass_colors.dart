import 'package:flutter/material.dart';

class GlassColors {
  // Light Mode - Warm & Calming
  static const Color creamWhite = Color(0xFFFCF9F2);
  static const Color blushPink = Color(0xFFFBE4E6);
  static const Color peach = Color(0xFFFEE8D6);
  static const Color softLavender = Color(0xFFE9E5F9);
  
  static const Color lightGlassSurface = Color(0x99FFFFFF); // 60% white (milk glass)
  static const Color lightGlassBorder = Color(0x1AFFFFFF); // 10% white (soft edge)
  static const Color lightGlassGlow = Color(0x0A000000); // 4% black for very soft depth

  // Dark Mode - Cozy & Bedtime Friendly
  static const Color warmCharcoal = Color(0xFF2C2A2F);
  static const Color softBrownBlack = Color(0xFF1F1C1B);
  static const Color mutedLavender = Color(0xFF4A4458);
  
  static const Color darkGlassSurface = Color(0x661E1C20); // 40% warm dark
  static const Color darkGlassBorder = Color(0x1AFFFFFF); // 10% white
  static const Color darkGlassGlow = Color(0x26000000); // 15% black for depth

  // Liquid Highlight Gradients
  static const LinearGradient lightLiquidHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x99FFFFFF), // 60% white highlight
      Color(0x1AFFFFFF), // 10% white
    ],
  );

  static const LinearGradient darkLiquidHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4DFFFFFF), // 30% white highlight
      Color(0x00FFFFFF), // 0% white
    ],
  );
}

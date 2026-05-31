import 'package:flutter/material.dart';

class AppShadows {
  static final List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> glowShadow = [
    BoxShadow(
      color: const Color(0xFF3472F6).withOpacity(0.2), // Primary blue glow
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> getCardShadow(bool isDark) {
    return premiumShadow;
  }
}

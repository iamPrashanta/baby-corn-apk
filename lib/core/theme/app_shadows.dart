import 'package:flutter/material.dart';

class AppShadows {
  static final List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> getCardShadow(bool isDark) {
    return isDark ? darkCardShadow : lightCardShadow;
  }
}

import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static final BorderRadius small = BorderRadius.circular(sm);
  static final BorderRadius medium = BorderRadius.circular(md);
  static final BorderRadius large = BorderRadius.circular(lg);
  static final BorderRadius extraLarge = BorderRadius.circular(xl);
  
  // Legacy mappings for backwards compatibility during migration
  static final BorderRadius cardBorder = BorderRadius.circular(24.0);
  static final BorderRadius buttonBorder = BorderRadius.circular(16.0);
  static final BorderRadius dialogBorder = BorderRadius.circular(24.0);
}

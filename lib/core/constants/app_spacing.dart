// core/constants/app_spacing.dart

import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0; // Global horizontal padding
  static const double lg = 24.0; // Form horizontal padding
  static const double xl = 32.0; // Section breathing space
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets formHorizontal = EdgeInsets.symmetric(horizontal: lg);
  
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}

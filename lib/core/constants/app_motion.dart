// core/constants/app_motion.dart

import 'package:flutter/material.dart';

class AppMotion {
  // Duration tiers
  static const Duration tactile = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration gentle = Duration(milliseconds: 600);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.easeOutBack;
  static const Curve gentleCurve = Curves.easeOutQuint;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutSine;

  // Spring physics constants (for custom SpringSimulation usage)
  static const double springDamping = 0.75;
  static const double springStiffness = 300.0;
  static const double springMass = 1.0;
}

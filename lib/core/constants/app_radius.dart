// core/constants/app_radius.dart

import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double button = 20.0;
  static const double card = 24.0;
  static const double xl = 32.0;

  static const Radius smRadius = Radius.circular(sm);
  static const Radius buttonRadius = Radius.circular(button);
  static const Radius cardRadius = Radius.circular(card);
  
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius buttonBorder = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
}

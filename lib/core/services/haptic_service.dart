import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// A robust haptic feedback service that uses the `vibration` plugin for reliable 
/// feedback across Android and iOS, falling back to Flutter's native `HapticFeedback` 
/// if the plugin is unsupported or fails.
class HapticService {
  static bool? _hasVibrator;
  static bool? _hasCustomVibrationsSupport;

  /// Initialize and cache capabilities
  static Future<void> init() async {
    _hasVibrator = await Vibration.hasVibrator();
    if (_hasVibrator == true) {
      _hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
    }
  }

  static Future<void> lightImpact() async {
    if (_hasVibrator == null) await init();
    
    if (_hasVibrator == true) {
      if (_hasCustomVibrationsSupport == true) {
        Vibration.vibrate(duration: 30, amplitude: 64);
      } else {
        Vibration.vibrate(duration: 30);
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static Future<void> mediumImpact() async {
    if (_hasVibrator == null) await init();

    if (_hasVibrator == true) {
      if (_hasCustomVibrationsSupport == true) {
        Vibration.vibrate(duration: 50, amplitude: 128);
      } else {
        Vibration.vibrate(duration: 50);
      }
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static Future<void> heavyImpact() async {
    if (_hasVibrator == null) await init();

    if (_hasVibrator == true) {
      if (_hasCustomVibrationsSupport == true) {
        Vibration.vibrate(duration: 100, amplitude: 255);
      } else {
        Vibration.vibrate(duration: 100);
      }
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static Future<void> selectionClick() async {
    if (_hasVibrator == null) await init();

    if (_hasVibrator == true) {
      if (_hasCustomVibrationsSupport == true) {
        Vibration.vibrate(duration: 15, amplitude: 64);
      } else {
        Vibration.vibrate(duration: 15);
      }
    } else {
      HapticFeedback.selectionClick();
    }
  }

  static Future<void> vibrate() async {
    if (_hasVibrator == null) await init();

    if (_hasVibrator == true) {
      Vibration.vibrate(duration: 400); // Standard vibration
    } else {
      HapticFeedback.vibrate();
    }
  }
}

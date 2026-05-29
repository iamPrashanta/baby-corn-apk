import 'dart:io';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

/// Centralized security service for Baby Corn.
/// Handles privacy features like screenshot protection.
class SecurityService {

  /// Enables FLAG_SECURE on Android to prevent screenshots and
  /// screen recording leakage in recent-apps preview.
  /// Useful as an optional privacy feature in baby tracking apps.
  static Future<void> enableScreenshotProtection() async {
    if (Platform.isAndroid) {
      await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    }
  }
  
  /// Disables FLAG_SECURE on Android to allow screenshots again.
  static Future<void> disableScreenshotProtection() async {
    if (Platform.isAndroid) {
      await FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    }
  }
}

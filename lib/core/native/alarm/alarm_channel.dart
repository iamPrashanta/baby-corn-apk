// lib/core/native/alarm/alarm_channel.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AlarmChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/alarm');

  static Future<void> setAlarm() async {
    try {
      await _channel.invokeMethod('setAlarm');
    } on PlatformException catch (e) {
      debugPrint("Failed to set alarm: '${e.message}'.");
    }
  }

  static Future<void> cancelAlarm() async {
    try {
      await _channel.invokeMethod('cancelAlarm');
    } on PlatformException catch (e) {
      debugPrint("Failed to cancel alarm: '${e.message}'.");
    }
  }
}

import 'package:flutter/services.dart';

class NotificationChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/notification');

  static Future<void> showNotification() async {
    try {
      await _channel.invokeMethod('showNotification');
    } on PlatformException catch (e) {
      print("Failed to show notification: '${e.message}'.");
    }
  }
}

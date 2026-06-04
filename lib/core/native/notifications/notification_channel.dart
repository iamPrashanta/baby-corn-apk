import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class NotificationChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/notification');

  static Future<void> showNotification() async {
    try {
      await _channel.invokeMethod('showNotification');
    } on PlatformException catch (e) {
      debugPrint("Failed to show notification: '${e.message}'.");
    }
  }
}

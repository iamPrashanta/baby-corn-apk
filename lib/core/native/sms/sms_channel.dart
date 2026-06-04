// lib/core/native/sms/sms_channel.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class SmsChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/sms');

  static Future<void> sendSms(String number, String message) async {
    try {
      await _channel.invokeMethod('sendSms', {'number': number, 'message': message});
    } on PlatformException catch (e) {
      debugPrint("Failed to send sms: '${e.message}'.");
    }
  }
}

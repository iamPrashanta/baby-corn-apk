import 'package:flutter/services.dart';

class SmsChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/sms');

  static Future<void> sendSms(String number, String message) async {
    try {
      await _channel.invokeMethod('sendSms', {'number': number, 'message': message});
    } on PlatformException catch (e) {
      print("Failed to send sms: '${e.message}'.");
    }
  }
}

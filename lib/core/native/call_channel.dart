import 'package:flutter/services.dart';

class CallChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/call');

  static Future<void> makeCall(String number) async {
    try {
      await _channel.invokeMethod('makeCall', {'number': number});
    } on PlatformException catch (e) {
      print("Failed to make call: '${e.message}'.");
    }
  }
}

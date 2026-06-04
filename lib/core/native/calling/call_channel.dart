// lib/core/native/calling/call_channel.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class CallChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/call');

  static Future<void> makeCall(String number) async {
    try {
      await _channel.invokeMethod('makeCall', {'number': number});
    } on PlatformException catch (e) {
      debugPrint("Failed to make call: '${e.message}'.");
    }
  }
}

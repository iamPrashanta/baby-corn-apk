import 'package:flutter/services.dart';

class ContactChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/contact');

  static Future<void> pickContact() async {
    try {
      await _channel.invokeMethod('pickContact');
    } on PlatformException catch (e) {
      print("Failed to pick contact: '${e.message}'.");
    }
  }
}

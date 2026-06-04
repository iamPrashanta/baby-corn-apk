// lib/core/native/contacts/contact_channel.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class ContactChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/contact');

  static Future<void> pickContact() async {
    try {
      await _channel.invokeMethod('pickContact');
    } on PlatformException catch (e) {
      debugPrint("Failed to pick contact: '${e.message}'.");
    }
  }
}

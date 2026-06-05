// lib/core/native/alarm/ringtone_channel.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class RingtoneChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/ringtone_picker');

  static Future<Map<String, String>?> pickRingtone({
    String? currentUri,
    bool isAlarm = true,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('pickRingtone', {
        'currentUri': currentUri,
        'isAlarm': isAlarm,
      });
      if (result != null) {
        return {
          'uri': result['uri'] as String? ?? '',
          'title': result['title'] as String? ?? 'Custom Tone',
        };
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint("Failed to pick ringtone: '${e.message}'.");
      return null;
    }
  }
}

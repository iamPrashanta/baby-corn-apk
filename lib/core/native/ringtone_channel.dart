import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class RingtoneChannel {
  static const MethodChannel _channel = MethodChannel('com.babycorn.app/ringtone_picker');

  static Future<String?> pickRingtone({
    String? currentUri,
    bool isAlarm = true,
  }) async {
    try {
      final String? result = await _channel.invokeMethod('pickRingtone', {
        'currentUri': currentUri,
        'isAlarm': isAlarm,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to pick ringtone: '${e.message}'.");
      return null;
    }
  }
}

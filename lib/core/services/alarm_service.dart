// lib/core/services/alarm_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:alarm/alarm.dart';
import 'package:go_router/go_router.dart';
import '../../features/reminders/domain/models/alarm_profile_model.dart';
import '../router/app_router.dart';

class AlarmService {
  static bool _initialized = false;
  static StreamSubscription<AlarmSettings>? _ringSubscription;
  static Function(AlarmSettings)? onRing;

  static Future<void> init() async {
    if (_initialized) return;
    
    // alarm package is already initialized in main.dart via Alarm.init()
    
    _ringSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
      debugPrint('[ALARM TRIGGERED] Alarm with id ${alarmSettings.id} is ringing!');
      
      final payload = alarmSettings.notificationSettings.body;

      // DO NOT STOP the alarm here. Let the native alarm package loop audio, 
      // wake the screen, and vibrate until the user acts on the AlarmScreen.
      
      // Route to AlarmScreen
      if (rootNavigatorKey.currentContext != null) {
        rootNavigatorKey.currentContext!.push('/alarm', extra: payload);
      }

      if (onRing != null) {
        onRing!(alarmSettings);
      }
    });
    
    _initialized = true;
    debugPrint('[ALARM INITIALIZED] AlarmService is ready.');
  }

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required AlarmProfile profile,
    String? payload, // Extra data e.g. 'medication|123'
  }) async {
    final ringtonePath = (profile.ringtoneUri != null && profile.ringtoneUri!.startsWith('content://')) 
        ? profile.ringtoneUri! 
        : 'assets/audio/alarm.wav';

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: ringtonePath,
      loopAudio: true,
      vibrate: profile.vibrationEnabled,
      notificationSettings: NotificationSettings(
        title: title,
        body: payload ?? "general",
      ),
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(milliseconds: 3000),
        volumeEnforced: true,
      ),
      androidFullScreenIntent: true,
      warningNotificationOnKill: true,
      payload: profile.ringtoneUri, // Pass URI here for retrieval on ring
    );

    await Alarm.set(alarmSettings: alarmSettings);
    debugPrint('[ALARM CREATED] Scheduled exact alarm id: $id at $dateTime with tone $ringtonePath');
  }

  static Future<void> snoozeAlarm(int originalId, AlarmProfile profile) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: profile.snoozeMinutes));
    
    await Alarm.stop(originalId);
    
    await scheduleAlarm(
      id: originalId,
      dateTime: snoozeTime,
      title: 'Snoozed Alarm',
      profile: profile,
    );
    debugPrint('[ALARM SNOOZED] Alarm $originalId snoozed until $snoozeTime');
  }

  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    debugPrint('[ALARM DISMISSED] Alarm $id stopped.');
  }

  static Future<void> stopAll() async {
    await Alarm.stopAll();
    debugPrint('[ALARM DISMISSED] All alarms stopped.');
  }

  static Future<List<AlarmSettings>> getActiveAlarms() async {
    return Alarm.getAlarms();
  }
}

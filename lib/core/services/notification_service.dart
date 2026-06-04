// lib/core/services/notification_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse details) async {
  debugPrint('[NOTIFICATION TAPPED] Payload: ${details.payload}');
  // Handle simple tap actions if needed
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[NOTIFICATION TAPPED Foreground] ${details.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'baby_corn_general',
            'General Notifications',
            description: 'Non-intrusive reminders',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'baby_corn_confirmation',
            'Confirmation Notifications',
            description: 'Silent confirmation messages',
            importance: Importance.high,
            playSound: false,
            enableVibration: false,
          ),
        );
      }
    }

    _initialized = true;
    debugPrint('[NOTIFICATION SERVICE INITIALIZED]');
  }

  static Future<void> scheduleNotification({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = const AndroidNotificationDetails(
      'baby_corn_general',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    
    debugPrint('[NOTIFICATION CREATED] Scheduled notification id: $id at $scheduledDate');
  }

  static Future<void> showConfirmationNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = const AndroidNotificationDetails(
      'baby_corn_confirmation',
      'Confirmation Notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: false,
      enableVibration: false,
    );

    await _plugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

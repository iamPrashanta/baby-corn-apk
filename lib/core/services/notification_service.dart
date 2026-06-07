// lib/core/services/notification_service.dart

import 'dart:io' show Platform;
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../local_storage/hive_manager.dart';
import '../../features/records/domain/models/active_session_model.dart';

@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse details) async {
  debugPrint('[NOTIFICATION TAPPED Background] ActionId: ${details.actionId}');
  final action = details.actionId;
  if (action == null) return;

  final SendPort? sendPort = IsolateNameServer.lookupPortByName('timer_action_port');
  if (sendPort != null) {
    sendPort.send(action);
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await HiveManager.init();
    final box = HiveManager.getActiveSessionBox();
    if (box.isEmpty) return;

    ActiveSessionModel? session = box.getAt(0);
    if (session == null) return;

    if (action == 'stop') {
      // Safe Background Recovery: Just mutate the session snapshot
      final metadata = Map<String, dynamic>.from(session.metadata);
      metadata['needsFinalization'] = true;
      metadata['finalEndTime'] = DateTime.now().toIso8601String();

      session = session.copyWith(
        isRunning: false,
        metadata: metadata,
      );
      await box.putAt(0, session);

      final plugin = FlutterLocalNotificationsPlugin();
      final androidImpl = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.stopForegroundService();
      }
      await plugin.cancel(id: NotificationService.timerNotificationId);
    }
  } catch (e) {
    debugPrint('[Background Tap Error]: $e');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  static const int timerNotificationId = 999;

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
        debugPrint('[NOTIFICATION TAPPED Foreground] ${details.payload} Action: ${details.actionId}');
        if (details.actionId != null) {
          final SendPort? sendPort = IsolateNameServer.lookupPortByName('timer_action_port');
          if (sendPort != null) sendPort.send(details.actionId);
        }
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
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'baby_corn_engagement',
            'Engagement Notifications',
            description: 'Daily check-ins',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'baby_corn_ongoing',
            'Ongoing Sessions',
            description: 'Active timer notifications',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );
      }
    }

    _initialized = true;
    debugPrint('[NOTIFICATION SERVICE INITIALIZED]');
  }

  static Future<void> showOngoingSessionNotification(ActiveSessionModel session) async {
    if (!_initialized) return;

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      if (d.inHours > 0) {
        return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
      }
      return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
    }
    
    final durationStr = formatDuration(session.currentDuration);
    String title = '⏱️ Active Session';
    final t = session.type.toLowerCase();
    
    if (t.contains('feed')) {
      final side = session.metadata['side'];
      if (side == 'left') {
        title = '🍼 Left Feeding';
      } else if (side == 'right') {
        title = '🍼 Right Feeding';
      } else {
        title = '🍼 Feeding Active';
      }
    } else if (t.contains('sleep')) {
      title = '😴 Sleep Tracking';
    } else if (t.contains('tummy')) {
      title = '🤸 Tummy Time';
    }

    if (!session.isRunning) {
       title += ' (Paused)';
    }

    final androidDetails = AndroidNotificationDetails(
      'baby_corn_ongoing',
      'Ongoing Sessions',
      channelDescription: 'Active timer notifications',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/launcher_icon',
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      category: AndroidNotificationCategory.service,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open',
          'Open',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'stop',
          '⏹ Stop',
          showsUserInterface: false,
        ),
      ],
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        // According to flutter_local_notifications 21.0.0, startForegroundService uses named arguments too
        await androidImpl.startForegroundService(
          id: timerNotificationId,
          title: title,
          body: durationStr,
          notificationDetails: androidDetails,
          payload: 'timer',
        );
        return;
      }
    }

    await _plugin.show(
      id: timerNotificationId,
      title: title,
      body: durationStr,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: 'timer',
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    String? payload,
    String channelId = 'baby_corn_general',
    String channelName = 'General Notifications',
    Importance importance = Importance.max,
    Priority priority = Priority.high,
    bool playSound = true,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      icon: '@mipmap/launcher_icon',
      playSound: playSound,
      enableVibration: playSound,
      fullScreenIntent: playSound,
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
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.stopForegroundService();
    }
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

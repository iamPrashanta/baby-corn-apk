// lib/core/services/reminder_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/settings/domain/models/reminder_settings_model.dart';

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Initialize Timezones
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
      debugPrint("ReminderService: Local timezone initialized to ${timeZone.identifier}");
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint("ReminderService: Failed to get local timezone, defaulting to UTC");
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap
      },
    );

    // Create Notification Channel for Android
    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        const channel = AndroidNotificationChannel(
          'baby_corn_reminders_v2', // id
          'Reminders', // name
          description: 'Notifications for baby feeding, sleep, and diapers', // description
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidImplementation.createNotificationChannel(channel);
        debugPrint("ReminderService: Android notification channel created (v2).");
      }
    }

    _initialized = true;
    debugPrint("ReminderService: Initialization complete.");
  }

  static Future<bool> requestPermissions() async {
    bool granted = false;
    if (Platform.isIOS) {
      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final result = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final result =
          await androidImplementation?.requestNotificationsPermission();
          
      // Also request exact alarm permission if Android 12+
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      final canExact = await androidImplementation?.canScheduleExactNotifications() ?? false;
      
      debugPrint("ReminderService [Permissions]: Notification allowed=$result, ExactAlarm status=$exactAlarmStatus, canScheduleExact=$canExact");
      
      granted = result ?? false;
    }
    return granted;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  static Future<void> updateSchedules(ReminderSettingsModel settings) async {
    // 1. Clear existing schedules
    await cancelAll();

    // 2. If master toggle is OFF, stop here.
    if (!settings.isMasterEnabled) {
      debugPrint("ReminderService: Master toggle is OFF, skipping schedules.");
      return;
    }

    // 3. Request/Verify permissions before scheduling
    final allowed = await requestPermissions();
    if (!allowed) {
      debugPrint("ReminderService: Reminder permissions denied. Skipping schedules.");
      return;
    }

    // Check if we can actually schedule exact alarms on Android
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await androidImplementation?.canScheduleExactNotifications() ?? false;
      if (!canExact) {
         debugPrint("ReminderService: WARNING - Cannot schedule exact notifications! Permissions denied.");
      }
    }

    // 3. Schedule Categories
    await _scheduleCategory(
        0, 'Feeding Reminder', 'Time for a feeding session!', settings.feeding);
    await _scheduleCategory(100, 'Sleep Reminder',
        'Time for baby to catch some Zzzs.', settings.sleep);
    await _scheduleCategory(
        200, 'Diaper Reminder', 'Time for a fresh diaper!', settings.diaper);
        
    // Debug log pending count
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint("ReminderService: Total pending scheduled notifications = ${pending.length}");
  }

  static Future<void> _scheduleCategory(int baseId, String title, String body,
      ReminderCategorySettings category) async {
    if (!category.isEnabled) return;

    final androidDetails = const AndroidNotificationDetails(
      'baby_corn_reminders_v2',
      'Reminders',
      channelDescription: 'Notifications for baby feeding, sleep, and diapers',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    if (category.isRepeat) {
      // Schedule multiple future alarms to simulate "repeat every X hours" reliably.
      // E.g., next 12 instances.
      final now = tz.TZDateTime.now(tz.local);
      for (int i = 1; i <= 12; i++) {
        final scheduledDate =
            now.add(Duration(hours: category.repeatHours * i));
        await _notificationsPlugin.zonedSchedule(
          id: baseId + i,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
      debugPrint("ReminderService: Scheduled repeat category '$title' next trigger at ${now.add(Duration(hours: category.repeatHours))}");
    } else {
      // Exact time daily
      final now = tz.TZDateTime.now(tz.local);
      final parts = category.exactTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id: baseId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      );
      debugPrint("ReminderService: Scheduled exact category '$title' next trigger at $scheduledDate");
    }
  }

  // Fallback direct schedule
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
    final androidDetails = const AndroidNotificationDetails(
      'baby_corn_reminders_v2',
      'Reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint("ReminderService: Scheduled diagnostic reminder '$title' for $scheduledDate");
  }
}

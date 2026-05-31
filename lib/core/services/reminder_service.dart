// lib/core/services/reminder_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/settings/domain/models/reminder_settings_model.dart';
import '../../features/medication/domain/models/medication_model.dart';
import '../../features/medication/domain/models/medication_log_model.dart';
import '../../core/local_storage/hive_manager.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  if (details.payload == null || details.actionId == null) return;

  // payload format: "medicationId|scheduledTimeMillis"
  final parts = details.payload!.split('|');
  if (parts.length != 2) return;

  final medId = parts[0];
  final sTimeMillis = int.tryParse(parts[1]);
  if (sTimeMillis == null) return;

  final sTime = DateTime.fromMillisecondsSinceEpoch(sTimeMillis);
  final now = DateTime.now();

  // Background needs Hive initialized
  await HiveManager.init();
  final boxMed = HiveManager.getMedicationsBox();
  final boxLog = HiveManager.getMedicationLogsBox();

  final med = boxMed.get(medId);
  if (med == null) return;

  if (details.actionId == 'taken') {
    debugPrint("ReminderService: Reminder Completed (Taken) for med $medId");
    final log = MedicationLogModel(
      id: now.millisecondsSinceEpoch.toString(),
      medicationId: medId,
      scheduledTime: sTime,
      actualTime: now,
      status: 'taken',
      takenBy: 'Caregiver',
    );
    await boxLog.put(log.id, log);

    final updatedMed = med.copyWith(
      remainingQuantity: (med.remainingQuantity - med.doseAmount) >= 0
          ? (med.remainingQuantity - med.doseAmount)
          : 0,
    );
    await boxMed.put(med.id, updatedMed);
  } else if (details.actionId == 'skip') {
    debugPrint("ReminderService: Reminder Missed (Skipped) for med $medId");
    final log = MedicationLogModel(
      id: now.millisecondsSinceEpoch.toString(),
      medicationId: medId,
      scheduledTime: sTime,
      actualTime: now,
      status: 'skipped',
      note: 'Skipped from notification',
    );
    await boxLog.put(log.id, log);
  } else if (details.actionId == 'snooze_5' ||
      details.actionId == 'snooze_15') {
    debugPrint("ReminderService: Reminder Snoozed (${details.actionId}) for med $medId");
    final mins = details.actionId == 'snooze_5' ? 5 : 15;
    // We cannot easily call ReminderService.scheduleMedication here because it resets daily alarms.
    // Instead, we just schedule a one-off diagnostic alarm for the snooze.
    await ReminderService.scheduleReminder(
      id: 99999 + DateTime.now().millisecond, // random id for snooze
      title: 'Snoozed: ${med.name}',
      body: 'Time for ${med.doseAmount} ${med.doseUnit}',
      delay: Duration(minutes: mins),
    );
  }
}

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
      debugPrint(
          "ReminderService: Local timezone initialized to ${timeZone.identifier}");
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint(
          "ReminderService: Failed to get local timezone, defaulting to UTC");
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
        // Handle tap in foreground/background (when app is open)
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Notification Channels for Android
    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_createChannel('baby_corn_feeding', 'Feeding Reminders', 'Notifications for baby feeding'));
        await androidImplementation.createNotificationChannel(_createChannel('baby_corn_sleep', 'Sleep Reminders', 'Notifications for baby sleep'));
        await androidImplementation.createNotificationChannel(_createChannel('baby_corn_diaper', 'Diaper Reminders', 'Notifications for baby diaper changes'));
        await androidImplementation.createNotificationChannel(_createChannel('baby_corn_medication', 'Medication Reminders', 'Notifications for baby medications'));
        await androidImplementation.createNotificationChannel(_createChannel('baby_corn_reminders_v2', 'General Reminders', 'General reminders')); // Fallback

        debugPrint("ReminderService: Android notification channels created.");
      }
    }

    _initialized = true;
    debugPrint("ReminderService: Initialization complete.");
  }

  static AndroidNotificationChannel _createChannel(String id, String name, String description) {
    return AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
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
      final canExact =
          await androidImplementation?.canScheduleExactNotifications() ?? false;

      debugPrint(
          "ReminderService [Permissions]: Notification allowed=$result, ExactAlarm status=$exactAlarmStatus, canScheduleExact=$canExact");

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

  static Future<ReminderSettingsModel> updateSchedules(ReminderSettingsModel settings) async {
    // 1. Clear existing schedules
    await cancelAll();

    // 2. If master toggle is OFF, stop here.
    if (!settings.isMasterEnabled) {
      debugPrint("ReminderService: Master toggle is OFF, skipping schedules.");
      return settings;
    }

    // 3. Request/Verify permissions before scheduling
    final allowed = await requestPermissions();
    if (!allowed) {
      debugPrint("ReminderService: Reminder permissions denied. Skipping schedules.");
      return settings;
    }

    // Check if we can actually schedule exact alarms on Android
    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canExact =
          await androidImplementation?.canScheduleExactNotifications() ?? false;
      if (!canExact) {
        debugPrint(
            "ReminderService: WARNING - Cannot schedule exact notifications! Permissions denied.");
      }
    }

    // 3. Schedule Categories and capture updated settings
    final updatedFeeding = await _scheduleCategory(0, 'baby_corn_feeding', 'Feeding Reminder', 'Time for a feeding session!', settings.feeding, 'feeding');
    final updatedSleep = await _scheduleCategory(100, 'baby_corn_sleep', 'Sleep Reminder', 'Time for baby to catch some Zzzs.', settings.sleep, 'sleep');
    final updatedDiaper = await _scheduleCategory(200, 'baby_corn_diaper', 'Diaper Reminder', 'Time for a fresh diaper!', settings.diaper, 'diaper');

    // 4. Reschedule all active medications
    try {
      final box = HiveManager.getMedicationsBox();
      for (final med in box.values) {
        if (med.isActive) {
          await scheduleMedication(med);
        }
      }
    } catch (e) {
      debugPrint("ReminderService: Failed to reschedule medications. Error: $e");
    }

    // Debug log pending count
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint("ReminderService: Total pending scheduled notifications = ${pending.length}");

    // Return the updated settings with correct nextScheduledTime
    return settings.copyWith(
      feeding: updatedFeeding,
      sleep: updatedSleep,
      diaper: updatedDiaper,
    );
  }

  static Future<ReminderCategorySettings> _scheduleCategory(
      int baseId, String channelId, String title, String body, ReminderCategorySettings category, String type) async {
    if (!category.isEnabled) {
      return category.copyWith(clearNextScheduledTime: true);
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      '$title Channel',
      channelDescription: 'Notifications for $title',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      timeoutAfter: 30 * 60 * 1000, // 30 minutes
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    DateTime? nextScheduled;

    if (category.mode == 'smart') {
      // Smart Feeding Mode (query Hive for latest record)
      try {
        final box = HiveManager.getRecordsBox();
        final latestRecord = box.values
            .where((r) => r.type.toLowerCase() == type)
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (latestRecord.isNotEmpty) {
          final lastTime = tz.TZDateTime.from(latestRecord.first.timestamp, tz.local);
          var scheduledDate = lastTime.add(Duration(hours: category.repeatHours));

          // If calculated time is in the past, fall back to "now + interval"
          if (scheduledDate.isBefore(now)) {
            scheduledDate = now.add(Duration(hours: category.repeatHours));
          }

          nextScheduled = scheduledDate;
          await _notificationsPlugin.zonedSchedule(
            id: baseId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          debugPrint("ReminderService: Reminder Scheduled (SMART) category '$title' next trigger at $scheduledDate");
        } else {
          // Fallback if no records exist: behave like repeat
          final scheduledDate = now.add(Duration(hours: category.repeatHours));
          nextScheduled = scheduledDate;
          await _notificationsPlugin.zonedSchedule(
            id: baseId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          debugPrint("ReminderService: Reminder Scheduled (SMART fallback - no records). '$title' at $scheduledDate");
        }
      } catch (e) {
        debugPrint("ReminderService: Error in SMART mode calculation: $e");
      }
    } else if (category.mode == 'repeat') {
      // Repeat interval
      nextScheduled = now.add(Duration(hours: category.repeatHours));
      for (int i = 1; i <= 12; i++) {
        final scheduledDate = now.add(Duration(hours: category.repeatHours * i));
        await _notificationsPlugin.zonedSchedule(
          id: baseId + i,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
      debugPrint("ReminderService: Reminder Scheduled (REPEAT) category '$title' next trigger at $nextScheduled");
    } else {
      // Exact time
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

      // Smart Catch-up Scheduling
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      nextScheduled = scheduledDate;

      await _notificationsPlugin.zonedSchedule(
        id: baseId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      );
      debugPrint("ReminderService: Reminder Scheduled (EXACT) category '$title' next trigger at $scheduledDate");
    }

    return category.copyWith(nextScheduledTime: nextScheduled);
  }

  // Fallback direct schedule (used by snooze and diagnostics)
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

  static Future<void> scheduleMedication(MedicationModel med) async {
    if (!med.isActive) return;

    final androidDetails = const AndroidNotificationDetails(
      'baby_corn_medication',
      'Medication Reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      timeoutAfter: 30 * 60 * 1000,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('taken', 'Taken', showsUserInterface: true),
        AndroidNotificationAction('snooze_5', 'Snooze 5 min', showsUserInterface: true),
        AndroidNotificationAction('snooze_15', 'Snooze 15 min', showsUserInterface: true),
        AndroidNotificationAction('skip', 'Skip', showsUserInterface: true),
      ],
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < med.times.length; i++) {
      final timeStr = med.times[i];
      final parts = timeStr.split(' ');
      if (parts.length != 2) continue;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) continue;

      int hour = int.tryParse(timeParts[0]) ?? 8;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      if (parts[1].toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

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

      final uniqueId = 10000 + (med.id.hashCode.abs() % 10000) + i;
      final payload = '${med.id}|${scheduledDate.millisecondsSinceEpoch}';

      await _notificationsPlugin.zonedSchedule(
        id: uniqueId,
        title: 'Medication: ${med.name}',
        body: 'Time for ${med.doseAmount} ${med.doseUnit}',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
        payload: payload,
      );
      debugPrint("ReminderService: Reminder Scheduled (Medication) '${med.name}' at $scheduledDate (ID: $uniqueId)");
    }
  }

  static Future<void> cancelMedication(MedicationModel med) async {
    for (int i = 0; i < med.times.length; i++) {
      final uniqueId = 10000 + (med.id.hashCode.abs() % 10000) + i;
      await _notificationsPlugin.cancel(id: uniqueId);
    }
  }
}

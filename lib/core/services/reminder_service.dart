// lib/core/services/reminder_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/settings/domain/models/reminder_settings_model.dart';
import '../../features/medication/domain/models/medication_model.dart';
import '../../core/local_storage/hive_manager.dart';
import 'alarm_service.dart';
import 'notification_service.dart';

class ReminderService {
  static Future<void> init() async {
    await NotificationService.init();
    await AlarmService.init();
    debugPrint("ReminderService: Orchestrator initialized.");
  }

  static Future<bool> requestPermissions() async {
    // Request Alarm permissions
    if (Platform.isAndroid) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      final notificationStatus = await Permission.notification.request();
      // Android 13+ WAKE_LOCK, SYSTEM_ALERT_WINDOW
      await Permission.systemAlertWindow.request();
      
      debugPrint("ReminderService: Permissions requested. Alarm=$exactAlarmStatus, Notifications=$notificationStatus");
      return notificationStatus.isGranted || exactAlarmStatus.isGranted;
    }
    return true;
  }

  static Future<void> cancelAll() async {
    await NotificationService.cancelAll();
    await AlarmService.stopAll();
  }

  static Future<void> cancelReminder(int id) async {
    await NotificationService.cancel(id);
    await AlarmService.stopAlarm(id);
  }

  static Future<ReminderSettingsModel> updateSchedules(ReminderSettingsModel settings) async {
    await cancelAll();

    if (!settings.isMasterEnabled) {
      return settings;
    }

    final updatedFeeding = await _scheduleCategory(0, 'Feeding Reminder', 'Time for a feeding session!', settings.feeding, 'feeding');
    final updatedSleep = await _scheduleCategory(100, 'Sleep Reminder', 'Time for baby to catch some Zzzs.', settings.sleep, 'sleep');
    final updatedDiaper = await _scheduleCategory(200, 'Diaper Reminder', 'Time for a fresh diaper!', settings.diaper, 'diaper');

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

    return settings.copyWith(
      feeding: updatedFeeding,
      sleep: updatedSleep,
      diaper: updatedDiaper,
    );
  }

  static Future<ReminderCategorySettings> _scheduleCategory(
      int baseId, String title, String body, ReminderCategorySettings category, String type) async {
    if (!category.isEnabled) {
      return category.copyWith(clearNextScheduledTime: true);
    }

    final now = DateTime.now();
    DateTime? nextScheduled;

    if (category.mode == 'smart') {
      try {
        final box = HiveManager.getRecordsBox();
        final latestRecord = box.values
            .where((r) => r.type.toLowerCase() == type)
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (latestRecord.isNotEmpty) {
          final lastTime = latestRecord.first.timestamp;
          var scheduledDate = lastTime.add(Duration(hours: category.repeatHours));

          if (scheduledDate.isBefore(now)) {
            scheduledDate = now.add(Duration(hours: category.repeatHours));
          }

          nextScheduled = scheduledDate;
          await _executeSchedule(baseId, scheduledDate, title, body, category, 'alarm|$type|${latestRecord.first.id}|$baseId');
        } else {
          final scheduledDate = now.add(Duration(hours: category.repeatHours));
          nextScheduled = scheduledDate;
          await _executeSchedule(baseId, scheduledDate, title, body, category, 'alarm|$type|fallback|$baseId');
        }
      } catch (e) {
        debugPrint("ReminderService: Error in SMART mode calculation: $e");
      }
    } else if (category.mode == 'repeat') {
      nextScheduled = now.add(Duration(hours: category.repeatHours));
      // For alarms, scheduling 12 upfront might exceed alarm package constraints or pollute DB.
      // But we will schedule a few to emulate repeat.
      for (int i = 1; i <= 4; i++) {
        final scheduledDate = now.add(Duration(hours: category.repeatHours * i));
        await _executeSchedule(baseId + i, scheduledDate, title, body, category, 'alarm|$type|repeat|${baseId + i}');
      }
    } else {
      final parts = category.exactTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      nextScheduled = scheduledDate;

      await _executeSchedule(baseId, scheduledDate, title, body, category, 'alarm|$type|exact|$baseId');
    }

    return category.copyWith(nextScheduledTime: nextScheduled);
  }

  static Future<void> _executeSchedule(int id, DateTime dateTime, String title, String body, ReminderCategorySettings category, String payload) async {
    if (category.profile.alarmType == 'notification') {
      await NotificationService.scheduleNotification(id: id, dateTime: dateTime, title: title, body: body, payload: payload);
    } else {
      await AlarmService.scheduleAlarm(id: id, dateTime: dateTime, title: title, profile: category.profile, payload: payload);
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    final scheduledDate = DateTime.now().add(delay);
    await NotificationService.scheduleNotification(id: id, dateTime: scheduledDate, title: title, body: body);
  }

  static Future<void> scheduleMedication(MedicationModel med) async {
    if (!med.isActive) return;

    final now = DateTime.now();

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
      } else if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;

      DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final uniqueId = 10000 + (med.id.hashCode.abs() % 10000) + i;
      final payload = 'alarm|medication|${med.id}|$uniqueId|${scheduledDate.millisecondsSinceEpoch}';

      // Always use full alarm for medications by default
      // TODO: read medication specific profiles in future
      await NotificationService.scheduleNotification(id: uniqueId, dateTime: scheduledDate, title: 'Medication: ${med.name}', body: 'Time for ${med.doseAmount} ${med.doseUnit}', payload: payload);
    }
  }

  static Future<void> cancelMedication(MedicationModel med) async {
    for (int i = 0; i < med.times.length; i++) {
      final uniqueId = 10000 + (med.id.hashCode.abs() % 10000) + i;
      await cancelReminder(uniqueId);
    }
  }
}

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/settings/domain/models/reminder_settings_model.dart';
import '../../features/medication/domain/models/medication_model.dart';
import '../../core/local_storage/hive_manager.dart';
import '../../features/reminders/domain/models/alarm_profile_model.dart';
import 'alarm_service.dart';
import 'notification_service.dart';
import 'permission_service.dart';

class ReminderService {
  static Future<void> init() async {
    await NotificationService.init();
    await AlarmService.init();
    debugPrint("ReminderService: Orchestrator initialized.");
  }

  /// Requests all alarm-related permissions using the full permission suite.
  /// Includes: notifications, exact alarm, battery optimization, FSI (Android 14+).
  /// Requires a BuildContext for rationale dialogs — call from a widget.
  static Future<bool> requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      return PermissionService.requestAlarmPermissions(context);
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

  static Future<ReminderSettingsModel> updateSchedules(ReminderSettingsModel settings, {bool is24Hour = false}) async {
    debugPrint('[SCHEDULE] updateSchedules called. master=${settings.isMasterEnabled}');
    
    // Selectively cancel non-medication alarms
    await NotificationService.cancelAll();
    final activeAlarms = await AlarmService.getActiveAlarms();
    for (final alarm in activeAlarms) {
      if (alarm.payload?.contains('medication') != true) {
        await AlarmService.stopAlarm(alarm.id);
      }
    }
    debugPrint('[CANCEL] Existing category alarms cancelled.');

    if (!settings.isMasterEnabled) {
      debugPrint('[SCHEDULE] Master is disabled. No alarms scheduled.');
      return settings;
    }

    final updatedFeeding = await _scheduleCategory(0, 'Feeding Reminder', 'Time for a feeding session!', settings.feeding, 'feeding', is24Hour);
    final updatedSleep = await _scheduleCategory(100, 'Sleep Reminder', 'Time for baby to catch some Zzzs.', settings.sleep, 'sleep', is24Hour);
    final updatedDiaper = await _scheduleCategory(200, 'Diaper Reminder', 'Time for a fresh diaper!', settings.diaper, 'diaper', is24Hour);

    try {
      final box = HiveManager.getMedicationsBox();
      final keysBox = HiveManager.getScheduledNotificationKeysBox();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Cleanup old fingerprints
      final keysToRemove = <String>[];
      for (final key in keysBox.keys) {
        final parts = key.toString().split('_');
        if (parts.length >= 2) {
          final timeMs = int.tryParse(parts[1]) ?? 0;
          if (timeMs < nowMs) {
            keysToRemove.add(key.toString());
          }
        }
      }
      for (final k in keysToRemove) {
        await keysBox.delete(k);
      }

      int expectedCount = 0;
      final activeMeds = <MedicationModel>[];
      final expectedFingerprints = <String>{};
      
      for (final med in box.values) {
        if (med.isActive) {
          activeMeds.add(med);
          
          final now = DateTime.now();
          for (final timeStr in med.times) {
            final parts = timeStr.split(' ');
            if (parts.length != 2) continue;
            final timeParts = parts[0].split(':');
            int hour = int.tryParse(timeParts[0]) ?? 8;
            final minute = int.tryParse(timeParts[1]) ?? 0;

            if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
            if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;

            DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
            if (scheduledDate.isBefore(now)) {
              scheduledDate = scheduledDate.add(const Duration(days: 1));
            }
            
            final fingerprint = '${med.id}_${scheduledDate.millisecondsSinceEpoch}_${med.doseAmount}';
            expectedFingerprints.add(fingerprint);
            expectedCount++;
          }
        }
      }

      bool needsRebuild = false;
      for (final fp in expectedFingerprints) {
        if (!keysBox.containsKey(fp)) {
          needsRebuild = true;
          break;
        }
      }

      debugPrint('[MEDICATION RESTORE CHECK] expectedCount=$expectedCount, expectedFingerprints=${expectedFingerprints.length}');

      if (!needsRebuild && expectedCount > 0) {
        debugPrint('[MEDICATION RESTORE SKIPPED] All medications already scheduled.');
      } else {
        debugPrint('[MEDICATION RESTORE REBUILD] Scheduling missing medication alarms.');
        for (final med in activeMeds) {
          await scheduleMedication(med, is24Hour: is24Hour);
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
      int baseId, String title, String body, ReminderCategorySettings category, String type, bool is24Hour) async {
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
      // RC-3: Schedule only the NEXT alarm. When the user acts on AlarmScreen
      // (Done / Snooze / Skip), AlarmScreen._rescheduleNext() schedules the
      // following one. This gives infinite repeat without a hardcoded limit.
      final scheduledDate = now.add(Duration(hours: category.repeatHours));
      nextScheduled = scheduledDate;
      await _executeSchedule(baseId, scheduledDate, title, body, category, 'alarm|$type|repeat|$baseId');
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

    if (nextScheduled != null) {
      final timeStr = is24Hour ? DateFormat('HH:mm').format(nextScheduled) : DateFormat('h:mm a').format(nextScheduled);
      NotificationService.showConfirmationNotification(
        title: 'Reminder Scheduled',
        body: '$title scheduled for $timeStr',
      );
      debugPrint('[REMINDER SCHEDULED] $title | Type: $type | Time: $nextScheduled | ID: $baseId');
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

  /// Schedules medication reminders as standard push notifications.
  /// Replaces the previous invasive full-screen alarm behavior.
  static Future<void> scheduleMedication(MedicationModel med, {bool is24Hour = false}) async {
    if (!med.isActive) return;

    final now = DateTime.now();

    final List<DateTime> expectedDoses = [];
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

      expectedDoses.add(DateTime(now.year, now.month, now.day, hour, minute));
    }
    
    expectedDoses.sort();

    final recordsBox = HiveManager.getRecordsBox();
    final logs = recordsBox.values.where((r) {
      if (r.type != 'medication' || r.metadata['medicationId'] != med.id) return false;
      final ts = r.timestamp;
      return ts.year == now.year && ts.month == now.month && ts.day == now.day &&
             (r.metadata['status'] == 'taken' || r.metadata['status'] == 'skipped' || r.metadata['status'] == 'missed');
    }).toList();
    
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final fulfilledDoses = <DateTime>{};
    int takenCount = 0;
    for (var log in logs) {
      if (takenCount < expectedDoses.length) {
        fulfilledDoses.add(expectedDoses[takenCount]);
        takenCount++;
      }
    }

    for (final expectedDose in expectedDoses) {
      DateTime scheduledDate = expectedDose;
      bool hasLog = fulfilledDoses.contains(scheduledDate);

      // If a log exists for today's dose or it has already passed, schedule for tomorrow
      if (hasLog || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      DateTime notifyTime = scheduledDate.subtract(Duration(minutes: med.notifyBeforeMinutes));
      
      // If the notification time has already passed, we missed the window. Schedule for tomorrow.
      if (notifyTime.isBefore(now)) {
        debugPrint('[MEDICATION NOTIFICATION SKIPPED] reason=trigger_time_in_past for ${med.name}');
        notifyTime = notifyTime.add(const Duration(days: 1));
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      debugPrint('[MEDICATION NEXT DOSE] ${med.name} scheduled for dose at $scheduledDate');

      final notificationId = Object.hash(med.id, expectedDose.hour, expectedDose.minute) & 0x7FFFFFFF;
      
      await NotificationService.cancel(notificationId);

      final payload = 'notification|medication|${med.id}|$notificationId|${notifyTime.millisecondsSinceEpoch}';
      final bodyText = med.notifyBeforeMinutes > 0 
          ? '${med.name} is due in ${med.notifyBeforeMinutes} minutes.' 
          : '${med.name} is due now.';

      await NotificationService.scheduleNotification(
        id: notificationId,
        dateTime: notifyTime,
        title: 'Medicine Reminder',
        body: bodyText,
        payload: payload,
      );

      debugPrint('[MEDICATION NOTIFICATION SCHEDULED] Medication ${med.name} | Time: $notifyTime | ID: $notificationId');
    }
  }

  static Future<void> cancelMedication(MedicationModel med) async {
    final now = DateTime.now();
    for (int dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      for (int i = 0; i < med.times.length; i++) {
        final timeStr = med.times[i];
        final parts = timeStr.split(' ');
        if (parts.length != 2) continue;
        final timeParts = parts[0].split(':');
        if (timeParts.length != 2) continue;

        int hour = int.tryParse(timeParts[0]) ?? 8;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
        if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;

        final notificationId = Object.hash(med.id, date.year, date.month, date.day, hour, minute) & 0x7FFFFFFF;
        await cancelReminder(notificationId);
      }
    }
  }
}

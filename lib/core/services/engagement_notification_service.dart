// lib/core/services/engagement_notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/settings/domain/models/reminder_settings_model.dart';
import '../local_storage/hive_manager.dart';
import 'dart:convert';
import 'notification_service.dart';

class EngagementNotificationService {
  static const _morningId = 999901;
  static const _eveningId = 999902;

  static Future<void> init() async {
    await checkAndSchedule();
  }

  static Future<void> checkAndSchedule() async {
    try {
      final box = HiveManager.getSettingsBox();
      final jsonStr = box.get('reminder_settings_json') as String?;
      
      bool shouldSchedule = true; // Default to true if no settings exist
      
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        final settings = ReminderSettingsModel.fromJson(decoded);
        
        // If master is enabled AND at least one category is active, stop engagement.
        if (settings.isMasterEnabled && 
            (settings.feeding.isEnabled || settings.sleep.isEnabled || settings.diaper.isEnabled)) {
          shouldSchedule = false;
        }
      }

      if (shouldSchedule) {
        debugPrint('[ENGAGEMENT] Reminders not fully configured. Scheduling engagement notifications.');
        await _scheduleDaily(box);
      } else {
        debugPrint('[ENGAGEMENT] Reminders configured. Canceling engagement notifications.');
        await box.delete('engagement_start_date');
        await cancelAll();
      }
    } catch (e) {
      debugPrint('[ENGAGEMENT ERROR] $e');
    }
  }

  static Future<void> _scheduleDaily(dynamic box) async {
    final now = DateTime.now();
    
    // Track how many days the user has been receiving engagement notifications
    String? startStr = box.get('engagement_start_date') as String?;
    DateTime startDate;
    if (startStr == null) {
      startDate = now;
      await box.put('engagement_start_date', startDate.toIso8601String());
    } else {
      startDate = DateTime.parse(startStr);
    }
    
    final daysActive = now.difference(startDate).inDays;
    final scheduleMorning = daysActive < 2; // Day 1 and Day 2 only
    
    // Morning: 9 AM (Only first 2 days)
    if (scheduleMorning) {
      var morning = DateTime(now.year, now.month, now.day, 9, 0);
      if (morning.isBefore(now)) morning = morning.add(const Duration(days: 1));
      
      await NotificationService.scheduleNotification(
        id: _morningId,
        dateTime: morning,
        title: "Good Morning! ☀️",
        body: "👶 Track today's feeding and sleep activities.",
        channelId: 'baby_corn_engagement',
        channelName: 'Engagement Notifications',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
      );
    } else {
      await NotificationService.cancel(_morningId);
    }

    // Evening: 7 PM (Always)
    var evening = DateTime(now.year, now.month, now.day, 19, 0);
    if (evening.isBefore(now)) evening = evening.add(const Duration(days: 1));

    await NotificationService.scheduleNotification(
      id: _eveningId,
      dateTime: evening,
      title: "Evening Check-in 🌙",
      body: "📊 Build your baby's growth history with today's records.",
      channelId: 'baby_corn_engagement',
      channelName: 'Engagement Notifications',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
    );
  }

  static Future<void> cancelAll() async {
    await NotificationService.cancel(_morningId);
    await NotificationService.cancel(_eveningId);
  }
}

import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/settings/domain/models/reminder_settings_model.dart';

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Initialize Timezones
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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

    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    bool granted = false;
    if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidImplementation?.requestNotificationsPermission();
      // Also request exact alarm permission if Android 12+
      await Permission.scheduleExactAlarm.request();
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
      return;
    }

    // 3. Schedule Categories
    await _scheduleCategory(0, 'Feeding Reminder', 'Time for a feeding session!', settings.feeding);
    await _scheduleCategory(100, 'Sleep Reminder', 'Time for baby to catch some Zzzs.', settings.sleep);
    await _scheduleCategory(200, 'Diaper Reminder', 'Time for a fresh diaper!', settings.diaper);
  }

  static Future<void> _scheduleCategory(int baseId, String title, String body, ReminderCategorySettings category) async {
    if (!category.isEnabled) return;

    final androidDetails = const AndroidNotificationDetails(
      'baby_corn_reminders',
      'Reminders',
      channelDescription: 'Notifications for baby feeding, sleep, and diapers',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    if (category.isRepeat) {
      // Schedule multiple future alarms to simulate "repeat every X hours" reliably.
      // E.g., next 12 instances.
      final now = tz.TZDateTime.now(tz.local);
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
      'baby_corn_reminders',
      'Reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

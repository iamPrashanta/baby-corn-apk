// lib/features/settings/presentation/screens/alarm_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/bouncing_button.dart';
import '../../../../features/settings/domain/models/reminder_settings_model.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  final String
      payload; // e.g. "alarm|feeding|fallback|0" or "alarm|medication|med123|10001|time"

  const AlarmScreen({super.key, required this.payload});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _isCanceled = false;

  late String _type = 'general';
  late int _notificationId = 0;
  String _title = "Reminder";
  String _emoji = "⏰";
  String _subtitle = "Time for action!";
  Color _color = AppColors.primaryContainer;

  @override
  void initState() {
    super.initState();
    _parsePayload();

    // Update the clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _parsePayload() {
    debugPrint('[ALARM SCREEN] Raw payload: "${widget.payload}"');
    final parts = widget.payload.split('|');
    debugPrint('[ALARM SCREEN] Payload parts: $parts (count=${parts.length})');

    if (parts.length >= 2) {
      _type = parts[1].toLowerCase();
      // ID is in parts[3] for most payloads, parts[3] for medication too
      if (parts.length >= 4) {
        _notificationId = int.tryParse(parts[3]) ?? 0;
      }
    }

    if (_type == 'feeding') {
      _title = "Feeding Reminder";
      _subtitle = "Time to feed your baby! 🍼";
      _emoji = "🍼";
      _color = AppColors.feeding;
    } else if (_type == 'sleep') {
      _title = "Sleep Reminder";
      _subtitle = "Help baby get some rest.";
      _emoji = "😴";
      _color = AppColors.sleep;
    } else if (_type == 'diaper') {
      _title = "Diaper Reminder";
      _subtitle = "Time for a fresh change!";
      _emoji = "🧷";
      _color = AppColors.diaper;
    } else if (_type == 'medication') {
      _title = "Medication Reminder";
      _subtitle = "Time for baby's medicine.";
      _emoji = "💊";
      _color = AppColors.primary;
      // Medication: alarm|medication|medId|alarmId|timestamp
      if (parts.length >= 4) {
        _notificationId = int.tryParse(parts[3]) ?? 0;
      }
    } else if (_type == 'vaccination') {
      _title = "Vaccination Due";
      _subtitle = "Check baby's vaccine schedule.";
      _emoji = "💉";
      _color = Colors.teal;
    } else if (_type == 'appointment') {
      _title = "Doctor Appointment";
      _subtitle = "Don't miss the appointment!";
      _emoji = "🏥";
      _color = Colors.blue;
    } else if (_type == 'test') {
      _title = "Alarm Test";
      _subtitle = "Alarm system is working! ✅";
      _emoji = "⏱️";
      _color = Colors.orange;
    } else {
      _title = "Reminder";
      _subtitle = "Time for action!";
      _emoji = "⏰";
      _color = AppColors.primaryContainer;
    }

    debugPrint('[ALARM SCREEN] Parsed → type=$_type | title=$_title | id=$_notificationId');
  }

  void _stopAlarmSound() {
    if (!_isCanceled) {
      _isCanceled = true;
      AlarmService.stopAlarm(_notificationId);
      NotificationService.cancel(_notificationId);
    }
  }

  void _onDone() {
    _stopAlarmSound();
    _rescheduleNext(); // RC-3: schedule next repeat cycle if applicable
    if (_type == 'feeding') {
      context.go('/feeding-entry');
    } else if (_type == 'medication') {
      context.go('/medications');
    } else if (_type == 'sleep') {
      context.go('/entry/sleep');
    } else if (_type == 'diaper') {
      context.go('/entry/diaper');
    } else {
      context.go('/home');
    }
  }

  void _onSnooze(int minutes) {
    _stopAlarmSound();
    _rescheduleNext(); // RC-3: keep the series alive even when snoozed
    NotificationService.scheduleNotification(
      id: _notificationId + 1000,
      title: "Snoozed: $_title",
      body: "Reminding you again in $minutes minutes",
      dateTime: DateTime.now().add(Duration(minutes: minutes)),
    );
    context.go('/home');
  }

  void _onSkip() {
    _stopAlarmSound();
    _rescheduleNext(); // RC-3: keep the series alive even when skipped
    context.go('/home');
  }

  /// RC-3: Schedules the next alarm for repeat-mode reminders.
  /// Called after every user action (Done / Snooze / Skip) so that
  /// repeat reminders continue indefinitely without a hardcoded limit.
  /// For exact-time and smart modes this is a no-op — they are
  /// rescheduled by updateSchedules() on the next app startup.
  Future<void> _rescheduleNext() async {
    // Only repeat-mode categories need self-rescheduling.
    const repeatTypes = {'feeding', 'sleep', 'diaper'};
    if (!repeatTypes.contains(_type)) return;

    try {
      final box = HiveManager.getSettingsBox();
      final jsonStr = box.get('reminder_settings_json') as String?;
      if (jsonStr == null) return;

      final settings =
          ReminderSettingsModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      if (!settings.isMasterEnabled) return;

      ReminderCategorySettings? cat;
      int baseId = 0;
      String title = '';

      if (_type == 'feeding' &&
          settings.feeding.isEnabled &&
          settings.feeding.mode == 'repeat') {
        cat = settings.feeding;
        baseId = 0;
        title = 'Feeding Reminder';
      } else if (_type == 'sleep' &&
          settings.sleep.isEnabled &&
          settings.sleep.mode == 'repeat') {
        cat = settings.sleep;
        baseId = 100;
        title = 'Sleep Reminder';
      } else if (_type == 'diaper' &&
          settings.diaper.isEnabled &&
          settings.diaper.mode == 'repeat') {
        cat = settings.diaper;
        baseId = 200;
        title = 'Diaper Reminder';
      }

      if (cat != null) {
        final nextTime =
            DateTime.now().add(Duration(hours: cat.repeatHours));
        await AlarmService.scheduleAlarm(
          id: baseId,
          dateTime: nextTime,
          title: title,
          profile: cat.profile,
          payload: 'alarm|$_type|repeat|$baseId',
        );
        debugPrint(
            '[REPEAT RESCHEDULE] Next $_type alarm at $nextTime (every ${cat.repeatHours}h)');
      }
    } catch (e) {
      debugPrint('[REPEAT RESCHEDULE ERROR] $e');
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    if (!_isCanceled) {
      _stopAlarmSound();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A24),
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Glassmorphism Blur Filter
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section
                  Column(
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(_now),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('hh:mm').format(_now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        DateFormat('a').format(_now),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Middle section (Activity Info)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child:
                            Text(_emoji, style: const TextStyle(fontSize: 64)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Bottom section (Actions)
                  Column(
                    children: [
                      BouncingButton(
                        onPressed: _onDone,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: _color,
                            borderRadius: BorderRadius.circular(4.0),
                            boxShadow: [
                              BoxShadow(
                                color: _color.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _getPrimaryActionText(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: BouncingButton(
                              onPressed: () => _onSnooze(_getSnoozeDuration1()),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Center(
                                  child: Text(
                                    'Snooze ${_getSnoozeDuration1()}m',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_getSnoozeDuration2() != null) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: BouncingButton(
                                onPressed: () =>
                                    _onSnooze(_getSnoozeDuration2()!),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Snooze ${_getSnoozeDuration2()!}m',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _onSkip,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _getSkipActionText(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPrimaryActionText() {
    if (_type == 'feeding') return '🍼 Feed Now';
    if (_type == 'medication') return '💊 Taken';
    if (_type == 'sleep') return '😴 Start Sleep';
    if (_type == 'diaper') return '🧷 Log Diaper';
    return 'Done';
  }

  int _getSnoozeDuration1() {
    if (_type == 'medication') return 10;
    if (_type == 'sleep') return 15;
    return 15; // default feeding/diaper
  }

  int? _getSnoozeDuration2() {
    if (_type == 'sleep') return 30;
    if (_type == 'medication') return null; // Only one snooze for meds
    return 30;
  }

  String _getSkipActionText() {
    if (_type == 'medication') return '❌ Missed';
    return '❌ Skip';
  }
}

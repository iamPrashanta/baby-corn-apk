// lib/features/settings/presentation/providers/reminder_settings_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alarm/alarm.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/engagement_notification_service.dart';

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettingsModel>(
        (ref) {
  return ReminderSettingsNotifier();
});

class ReminderSettingsNotifier extends StateNotifier<ReminderSettingsModel> {
  static const _settingsKey = 'reminder_settings_json';

  // RC-2: Serialise saves so concurrent toggles never interleave cancelAll().
  bool _saving = false;
  ReminderSettingsModel? _pendingSave;
  bool _pendingIs24Hour = false;

  ReminderSettingsNotifier() : super(const ReminderSettingsModel()) {
    _loadSettings();
  }

  // ---------------------------------------------------------------------------
  // Load / Restore
  // ---------------------------------------------------------------------------

  void _loadSettings() {
    final box = HiveManager.getSettingsBox();
    final jsonStr = box.get(_settingsKey) as String?;
    debugPrint('[REMINDER LOAD] key=$_settingsKey present=${jsonStr != null}');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        state = ReminderSettingsModel.fromJson(decoded);
        debugPrint('[REMINDER LOAD] Restored: master=${state.isMasterEnabled} '
            'feeding=${state.feeding.isEnabled}/${state.feeding.mode} '
            'sleep=${state.sleep.isEnabled}/${state.sleep.mode} '
            'diaper=${state.diaper.isEnabled}/${state.diaper.mode}');
        debugPrint('[REMINDER SETTINGS RESTORED]');
        debugPrint('[MASTER STATE] isMasterEnabled=${state.isMasterEnabled}');
        // RC-1: Rebuild Android AlarmManager entries after every app restart.
        if (state.isMasterEnabled) {
          _rescheduleAsync();
        }
      } catch (e) {
        debugPrint('[REMINDER LOAD ERROR] Failed to parse stored settings: $e');
      }
    } else {
      debugPrint('[REMINDER LOAD] No stored settings found. Using defaults.');
    }
  }

  /// Rebuilds all Android AlarmManager entries from the current state.
  /// Called after app restart (RC-1 fix).
  Future<void> _rescheduleAsync() async {
    try {
      debugPrint('[REMINDER RESCHEDULE START]');
      // Emergency Reminder Recovery
      int expectedAlarms = 0;
      if (state.feeding.isEnabled) expectedAlarms++;
      if (state.sleep.isEnabled) expectedAlarms++;
      if (state.diaper.isEnabled) expectedAlarms++;

      final updatedSettings = await ReminderService.updateSchedules(state);
      state = updatedSettings;
      final box = HiveManager.getSettingsBox();
      await box.put(_settingsKey, jsonEncode(updatedSettings.toJson()));
      
      final activeAlarms = await Alarm.getAlarms();
      debugPrint('[ACTIVE ALARMS COUNT] ${activeAlarms.length} active alarms found.');
      
      if (expectedAlarms > 0 && activeAlarms.length < expectedAlarms) {
        debugPrint('[ALARM RECOVERY] Mismatch detected: Expected $expectedAlarms but found ${activeAlarms.length}.');
        debugPrint('[ALARM RECOVERY] Some alarms were lost during scheduling. Retrying...');
        // Force one more rebuild
        await ReminderService.updateSchedules(state);
      } else {
        debugPrint('[ALARM RECOVERY] State matches AlarmManager (${activeAlarms.length} active). Syncing next schedules...');
      }

      debugPrint('[REMINDER RESTORE] Rescheduling complete. '
          'feeding.next=${updatedSettings.feeding.nextScheduledTime} '
          'sleep.next=${updatedSettings.sleep.nextScheduledTime} '
          'diaper.next=${updatedSettings.diaper.nextScheduledTime}');
    } catch (e) {
      debugPrint('[REMINDER RESTORE ERROR] $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Save (RC-2: mutex + queue)
  // ---------------------------------------------------------------------------

  Future<void> _saveSettings(
      ReminderSettingsModel newSettings, bool is24Hour) async {
    // Optimistic UI update so the toggle feels instant.
    state = newSettings;
    debugPrint('[REMINDER SAVE] Queuing: master=${newSettings.isMasterEnabled} '
        'feeding=${newSettings.feeding.isEnabled}/${newSettings.feeding.mode} '
        'sleep=${newSettings.sleep.isEnabled}/${newSettings.sleep.mode} '
        'diaper=${newSettings.diaper.isEnabled}/${newSettings.diaper.mode}');

    if (_saving) {
      // A save is already in flight. Buffer the latest state; the running loop
      // will pick it up after the current updateSchedules() completes.
      _pendingSave = newSettings;
      _pendingIs24Hour = is24Hour;
      debugPrint('[REMINDER SAVE] Buffered (save in flight).');
      return;
    }

    _saving = true;
    try {
      var toSave = newSettings;
      var toSave24h = is24Hour;
      do {
        _pendingSave = null;
        debugPrint('[REMINDER SAVE] Executing updateSchedules...');
        final updated =
            await ReminderService.updateSchedules(toSave, is24Hour: toSave24h);
        state = updated;
        final box = HiveManager.getSettingsBox();
        final jsonToSave = jsonEncode(updated.toJson());
        await box.put(_settingsKey, jsonToSave);
        
        // Persistence Validation
        final readBack = box.get(_settingsKey) as String?;
        if (readBack == jsonToSave) {
          debugPrint('[REMINDER SAVE VERIFIED]');
        } else {
          debugPrint('[REMINDER SAVE ERROR] Validation failed: readback mismatch.');
        }
        
        debugPrint('[MASTER STATE] isMasterEnabled=${updated.isMasterEnabled}');

        debugPrint('[REMINDER SAVE SUCCESS] '
            'feeding.next=${updated.feeding.nextScheduledTime} '
            'sleep.next=${updated.sleep.nextScheduledTime}');

        // If another save was buffered while we were awaiting, process it now.
        if (_pendingSave != null) {
          toSave = _pendingSave!;
          toSave24h = _pendingIs24Hour;
          debugPrint('[REMINDER SAVE] Flushing buffered save...');
        }
      } while (_pendingSave != null);
    } catch (e, st) {
      debugPrint('[REMINDER SAVE ERROR] $e\n$st');
    } finally {
      _saving = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void toggleMaster(bool isEnabled, {bool is24Hour = false}) {
    _saveSettings(state.copyWith(isMasterEnabled: isEnabled), is24Hour).then((_) {
      EngagementNotificationService.checkAndSchedule();
    });
  }

  void updateFeeding(ReminderCategorySettings settings,
      {bool is24Hour = false}) {
    _saveSettings(state.copyWith(feeding: settings), is24Hour);
  }

  void updateSleep(ReminderCategorySettings settings, {bool is24Hour = false}) {
    _saveSettings(state.copyWith(sleep: settings), is24Hour);
  }

  void updateDiaper(ReminderCategorySettings settings,
      {bool is24Hour = false}) {
    _saveSettings(state.copyWith(diaper: settings), is24Hour);
  }
}

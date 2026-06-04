// lib/features/settings/presentation/providers/reminder_settings_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/services/reminder_service.dart';

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettingsModel>(
        (ref) {
  return ReminderSettingsNotifier();
});

class ReminderSettingsNotifier extends StateNotifier<ReminderSettingsModel> {
  static const _settingsKey = 'reminder_settings_json';

  ReminderSettingsNotifier() : super(const ReminderSettingsModel()) {
    _loadSettings();
  }

  void _loadSettings() {
    final box = HiveManager.getSettingsBox();
    final jsonStr = box.get(_settingsKey) as String?;
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        state = ReminderSettingsModel.fromJson(decoded);
      } catch (e) {
        // Fallback to default
      }
    }
  }

  Future<void> _saveSettings(ReminderSettingsModel newSettings, bool is24Hour) async {
    // 1. Optimistic Update (Instant UI Response)
    state = newSettings;

    // 2. Also trigger actual schedule updates via ReminderService
    final updatedSettings = await ReminderService.updateSchedules(newSettings, is24Hour: is24Hour);

    // 3. Update with exact calculated times
    state = updatedSettings;
    final box = HiveManager.getSettingsBox();
    await box.put(_settingsKey, jsonEncode(updatedSettings.toJson()));
  }

  void toggleMaster(bool isEnabled, {bool is24Hour = false}) {
    _saveSettings(state.copyWith(isMasterEnabled: isEnabled), is24Hour);
  }

  void updateFeeding(ReminderCategorySettings settings, {bool is24Hour = false}) {
    _saveSettings(state.copyWith(feeding: settings), is24Hour);
  }

  void updateSleep(ReminderCategorySettings settings, {bool is24Hour = false}) {
    _saveSettings(state.copyWith(sleep: settings), is24Hour);
  }

  void updateDiaper(ReminderCategorySettings settings, {bool is24Hour = false}) {
    _saveSettings(state.copyWith(diaper: settings), is24Hour);
  }
}

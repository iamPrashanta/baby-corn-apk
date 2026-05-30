// features/settings/presentation/providers/reminder_settings_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../../../core/services/reminder_service.dart';

final reminderSettingsProvider = StateNotifierProvider<ReminderSettingsNotifier, ReminderSettingsModel>((ref) {
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

  Future<void> _saveSettings(ReminderSettingsModel newSettings) async {
    state = newSettings;
    final box = HiveManager.getSettingsBox();
    await box.put(_settingsKey, jsonEncode(newSettings.toJson()));
    
    // Also trigger actual schedule updates via ReminderService if needed
    ReminderService.updateSchedules(newSettings);
  }

  void toggleMaster(bool isEnabled) {
    _saveSettings(state.copyWith(isMasterEnabled: isEnabled));
  }

  void updateFeeding(ReminderCategorySettings settings) {
    _saveSettings(state.copyWith(feeding: settings));
  }

  void updateSleep(ReminderCategorySettings settings) {
    _saveSettings(state.copyWith(sleep: settings));
  }

  void updateDiaper(ReminderCategorySettings settings) {
    _saveSettings(state.copyWith(diaper: settings));
  }
}

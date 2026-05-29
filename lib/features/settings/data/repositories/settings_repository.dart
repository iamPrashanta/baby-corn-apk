// features/settings/data/repositories/settings_repository.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local_storage/hive_manager.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsRepository {
  Future<void> saveThemeMode(ThemeMode mode) async {
    final box = HiveManager.getSettingsBox();
    await box.put('theme_mode', mode.index);
  }

  ThemeMode getThemeMode() {
    final box = HiveManager.getSettingsBox();
    final modeIndex = box.get('theme_mode', defaultValue: ThemeMode.system.index) as int;
    return ThemeMode.values[modeIndex];
  }

  Future<void> saveLanguage(String langCode) async {
    final box = HiveManager.getSettingsBox();
    await box.put('language', langCode);
  }

  String getLanguage() {
    final box = HiveManager.getSettingsBox();
    return box.get('language', defaultValue: 'en') as String;
  }
}

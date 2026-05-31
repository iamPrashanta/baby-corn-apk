import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_storage/hive_manager.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const _localeKey = 'selected_locale';

  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final settingsBox = HiveManager.getSettingsBox();
    final languageCode = settingsBox.get(_localeKey, defaultValue: 'en');
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final settingsBox = HiveManager.getSettingsBox();
    await settingsBox.put(_localeKey, locale.languageCode);
  }
}

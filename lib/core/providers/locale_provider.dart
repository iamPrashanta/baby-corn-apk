import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const _localeKey = 'selected_locale';
  SharedPreferences? _prefs;

  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    _prefs = await SharedPreferences.getInstance();
    final languageCode = _prefs?.getString(_localeKey) ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_localeKey, locale.languageCode);
  }
}

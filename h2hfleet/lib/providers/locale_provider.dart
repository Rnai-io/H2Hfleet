import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/i18n/app_strings.dart';

const _key = 'app_locale';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSaved();
    return const Locale('th');
  }

  void _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key) ?? 'th';
      state = Locale(code);
    } catch (_) {}
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
  }

  void toggle() => setLocale(state.languageCode == 'th' ? 'en' : 'th');
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

final strProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale.languageCode);
});

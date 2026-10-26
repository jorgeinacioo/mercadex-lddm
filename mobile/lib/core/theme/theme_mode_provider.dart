import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/core/theme/theme_preferences.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeNotifier({
    this.initialMode = ThemeMode.light,
    ThemePreferences? preferences,
  }) : _preferences = preferences ?? SharedPreferencesThemePreferences();

  final ThemeMode initialMode;
  final ThemePreferences _preferences;

  @override
  ThemeMode build() => initialMode;

  Future<void> setDarkMode(bool enabled) async {
    await _preferences.writeDarkMode(enabled);
    state = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}

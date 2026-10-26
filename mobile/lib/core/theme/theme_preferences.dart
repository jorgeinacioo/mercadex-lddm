import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemePreferences {
  Future<bool> readDarkMode();
  Future<void> writeDarkMode(bool enabled);
}

class SharedPreferencesThemePreferences implements ThemePreferences {
  SharedPreferencesThemePreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'dark_mode';
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> readDarkMode() async =>
      await _preferences.getBool(key) ?? false;

  @override
  Future<void> writeDarkMode(bool enabled) =>
      _preferences.setBool(key, enabled);
}

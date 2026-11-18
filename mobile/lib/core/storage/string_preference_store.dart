import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key-value contract over SharedPreferences, replaceable in tests.
abstract class StringPreferenceStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

class SharedPreferencesStringStore implements StringPreferenceStore {
  SharedPreferencesStringStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

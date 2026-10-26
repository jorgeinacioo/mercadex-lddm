import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/features/auth/domain/auth_session.dart';

abstract class AuthSessionStorage {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

class SecureAuthSessionStorage implements AuthSessionStorage {
  const SecureAuthSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth_session';
  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return null;

    try {
      final data = jsonDecode(saved) as Map<String, dynamic>;
      final username = data['username'] as String;
      final token = data['accessToken'] as String;
      if (username.isEmpty ||
          token.isEmpty ||
          data['mock'] != AppConfig.useMockData ||
          (!AppConfig.useMockData && !_isValidToken(token))) {
        await clear();
        return null;
      }
      return AuthSession(username: username, accessToken: token);
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) => _storage.write(
    key: _key,
    value: jsonEncode({
      'username': session.username,
      'accessToken': session.accessToken,
      'mock': AppConfig.useMockData,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

bool _isValidToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;
    final expiresAt = payload['exp'];
    return expiresAt is int &&
        expiresAt > DateTime.now().millisecondsSinceEpoch ~/ 1000;
  } on FormatException {
    return false;
  } on TypeError {
    return false;
  }
}

import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/auth/data/auth_api.dart';

/// Raised when the username or the password is wrong.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'Usuário ou senha inválidos.';
}

/// Accounts accepted in the offline demo. They match the backend seed.
const demoAccounts = {
  'admin': 'admin',
  'jorge': 'mercadex',
  'fernando': 'mercadex',
};

const mockAccessToken = 'mock-access-token';

class AuthRepository {
  const AuthRepository({this.api = const AuthApi(), this.useMockData});

  final AuthApi api;
  final bool? useMockData;

  bool get _useMockData => useMockData ?? AppConfig.useMockData;

  Future<({String accessToken, String username})> login({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (_useMockData) {
      if (demoAccounts[normalized] != password) {
        throw const InvalidCredentialsException();
      }
      return (accessToken: mockAccessToken, username: normalized);
    }

    try {
      return await api.login(username: normalized, password: password);
    } on ApiException catch (error) {
      if (error.isUnauthorized || error.statusCode == 400) {
        throw const InvalidCredentialsException();
      }
      rethrow;
    }
  }
}

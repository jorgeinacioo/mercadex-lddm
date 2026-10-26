import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/features/auth/data/auth_api.dart';

class AuthRepository {
  const AuthRepository({this.api = const AuthApi()});

  final AuthApi api;

  Future<String> login({required String username, required String password}) {
    if (AppConfig.useMockData) {
      if (username != 'admin' || password != 'admin') {
        return Future.error(const FormatException('Invalid credentials'));
      }
      return Future.value('mock-access-token');
    }

    return api.login(username: username, password: password);
  }
}

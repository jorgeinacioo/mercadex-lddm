import 'package:mercadex/core/network/api_client.dart';

class AuthApi {
  const AuthApi({this.client = const ApiClient()});

  final ApiClient client;

  /// Returns the access token and the username stored by the server.
  Future<({String accessToken, String username})> login({
    required String username,
    required String password,
  }) async {
    final json =
        await client.postJson('/auth/login', {
              'username': username,
              'password': password,
            })
            as Map<String, dynamic>;
    final user = json['user'] as Map<String, dynamic>?;
    return (
      accessToken: json['accessToken'] as String,
      username: user?['username'] as String? ?? username,
    );
  }
}

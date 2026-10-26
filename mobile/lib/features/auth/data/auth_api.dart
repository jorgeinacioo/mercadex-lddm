import 'dart:convert';

import 'package:mercadex/core/network/api_client.dart';

class AuthApi {
  const AuthApi({this.client = const ApiClient()});

  final ApiClient client;

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await client.post('/auth/login', {
      'username': username,
      'password': password,
    });

    if (response.statusCode != 201) {
      throw StateError('Usuário ou senha inválidos.');
    }

    return (jsonDecode(response.body) as Map<String, dynamic>)['accessToken']
        as String;
  }
}

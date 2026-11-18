import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadex/core/network/api_client.dart';

ApiClient _client(MockClientHandler handler, {Duration? timeout}) => ApiClient(
  baseUrl: 'http://api.test/',
  httpClient: MockClient(handler),
  timeout: timeout ?? const Duration(seconds: 1),
);

void main() {
  test('decodes UTF-8 JSON and sends the token', () async {
    final client = _client((request) async {
      expect(request.url.toString(), 'http://api.test/markets');
      expect(request.headers['Authorization'], 'Bearer abc');
      return http.Response.bytes(
        utf8.encode('[{"name":"Pão de Açúcar"}]'),
        200,
      );
    });
    final json = await client.getJson('markets', accessToken: 'abc');
    expect((json! as List).single, {'name': 'Pão de Açúcar'});
  });

  test('turns HTTP errors into typed exceptions', () async {
    for (final (status, check) in [
      (401, (ApiException e) => e.isUnauthorized),
      (404, (ApiException e) => e.isNotFound),
      (500, (ApiException e) => e.message.contains('indisponível')),
    ]) {
      final client = _client((_) async => http.Response('{}', status));
      await expectLater(
        client.getJson('/x'),
        throwsA(isA<ApiException>().having(check, 'check', isTrue)),
      );
    }
  });

  test('reports an unreachable server as a network error', () async {
    final client = _client(
      (_) async => throw const SocketException('Connection refused'),
    );
    await expectLater(
      client.getJson('/x'),
      throwsA(
        isA<ApiException>().having((e) => e.isNetworkError, 'network', isTrue),
      ),
    );
  });

  test('gives up when the server takes too long', () async {
    final client = _client(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(
      client.getJson('/x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('demorou'),
        ),
      ),
    );
  });
}

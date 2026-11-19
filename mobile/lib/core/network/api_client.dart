import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mercadex/core/config/app_config.dart';

/// Failure of a request to the Mercadex API.
///
/// [statusCode] is null when the server could not be reached.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class ApiClient {
  const ApiClient({this.httpClient, this.baseUrl, this.timeout = _timeout});

  static const _timeout = Duration(seconds: 10);

  /// Injected in tests; the package-level client is used otherwise.
  final http.Client? httpClient;
  final String? baseUrl;
  final Duration timeout;

  Future<Object?> getJson(String path, {String? accessToken}) {
    return _send(
      () => httpClient == null
          ? http.get(_uri(path), headers: _headers(accessToken))
          : httpClient!.get(_uri(path), headers: _headers(accessToken)),
    );
  }

  Future<Object?> postJson(String path, Object body, {String? accessToken}) {
    final encoded = jsonEncode(body);
    return _send(
      () => httpClient == null
          ? http.post(_uri(path), headers: _headers(accessToken), body: encoded)
          : httpClient!.post(
              _uri(path),
              headers: _headers(accessToken),
              body: encoded,
            ),
    );
  }

  Future<Object?> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder.');
    } on SocketException {
      throw const ApiException('Não foi possível conectar ao servidor.');
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response.statusCode),
        statusCode: response.statusCode,
      );
    }
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException(
        'Resposta inválida do servidor.',
        statusCode: response.statusCode,
      );
    }
  }

  Uri _uri(String path) {
    final configured = baseUrl ?? AppConfig.apiUrl;
    if (configured.isEmpty) {
      throw StateError('API_URL is required when mock data is disabled.');
    }

    final base = configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  Map<String, String> _headers(String? accessToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }
}

String _errorMessage(int statusCode) {
  return switch (statusCode) {
    400 => 'Dados inválidos.',
    401 => 'Sua sessão expirou. Entre novamente.',
    404 => 'Não encontrado.',
    _ when statusCode >= 500 => 'O servidor está indisponível no momento.',
    _ => 'Não foi possível concluir a operação.',
  };
}

/// Message for any error thrown while loading or saving data.
String friendlyError(Object error) {
  if (error is ApiException) return error.message;
  return 'Algo deu errado. Tente novamente.';
}

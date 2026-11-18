import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/auth/data/auth_api.dart';
import 'package:mercadex/features/auth/data/auth_repository.dart';

void main() {
  const demo = AuthRepository(useMockData: true);

  test('demo login accepts the demo accounts, ignoring case', () async {
    final result = await demo.login(username: ' Jorge ', password: 'mercadex');
    expect(result.username, 'jorge');
    expect(result.accessToken, mockAccessToken);
    expect(
      (await demo.login(username: 'admin', password: 'admin')).username,
      'admin',
    );
  });

  test('demo login rejects wrong username or password', () async {
    await expectLater(
      demo.login(username: 'someone', password: 'admin'),
      throwsA(isA<InvalidCredentialsException>()),
    );
    await expectLater(
      demo.login(username: 'admin', password: 'wrong'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('API login maps 401 to invalid credentials', () async {
    final repository = AuthRepository(
      useMockData: false,
      api: AuthApi(
        client: ApiClient(
          baseUrl: 'http://api.test',
          httpClient: MockClient(
            (_) async => http.Response('{"statusCode":401}', 401),
          ),
        ),
      ),
    );
    await expectLater(
      repository.login(username: 'jorge', password: 'x'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('API login returns the token and the stored username', () async {
    final repository = AuthRepository(
      useMockData: false,
      api: AuthApi(
        client: ApiClient(
          baseUrl: 'http://api.test',
          httpClient: MockClient((request) async {
            expect(request.body, '{"username":"jorge","password":"mercadex"}');
            return http.Response(
              '{"accessToken":"jwt","user":{"username":"jorge","role":"USER"}}',
              201,
            );
          }),
        ),
      ),
    );
    final result = await repository.login(
      username: 'JORGE',
      password: 'mercadex',
    );
    expect(result.accessToken, 'jwt');
    expect(result.username, 'jorge');
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/prices/data/prices_repository.dart';

void main() {
  test('sends the price with the token and never a user id', () async {
    late http.Request captured;
    final repository = PricesRepository(
      useMockData: false,
      client: ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'id': 'obs-1',
              'price': '15.49',
              'observedAt': '2026-11-20T12:00:00.000Z',
              'submittedBy': 'jorge',
              'market': {'id': 'carrefour', 'name': 'Carrefour'},
              'branch': {
                'id': 'carrefour-centro',
                'name': 'Carrefour Centro',
                'address': 'Av. Central, 1200',
              },
            }),
            201,
          );
        }),
      ),
    );

    final deal = await repository.submit(
      productId: 'cafe-500g',
      branchId: 'carrefour-centro',
      priceCents: 1549,
      accessToken: 'jwt',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/prices');
    expect(captured.headers['Authorization'], 'Bearer jwt');
    expect(jsonDecode(captured.body), {
      'productId': 'cafe-500g',
      'branchId': 'carrefour-centro',
      'price': 15.49,
    });
    expect(deal.priceCents, 1549);
    expect(deal.submittedBy, 'jorge');
  });

  test('refuses to fake a submission in the offline demo', () async {
    const repository = PricesRepository(useMockData: true);
    expect(repository.isAvailable, isFalse);
    await expectLater(
      repository.submit(
        productId: 'cafe-500g',
        branchId: 'carrefour-centro',
        priceCents: 100,
        accessToken: 'x',
      ),
      throwsUnsupportedError,
    );
  });

  test('surfaces an expired session', () async {
    final repository = PricesRepository(
      useMockData: false,
      client: ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((_) async => http.Response('{}', 401)),
      ),
    );
    await expectLater(
      repository.submit(
        productId: 'a',
        branchId: 'b',
        priceCents: 100,
        accessToken: 'old',
      ),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', true)),
    );
  });
}

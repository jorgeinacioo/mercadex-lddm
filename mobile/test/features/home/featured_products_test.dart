import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/home/presentation/providers/home_products_provider.dart';
import 'package:mercadex/features/products/data/products_api.dart';

import '../../helpers/test_catalog.dart';

void main() {
  test('products API reads prices and the cheapest market', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://api.test/products');
      return http.Response(
        jsonEncode([
          {
            'id': 'cafe-500g',
            'name': 'Café Tradicional 500g',
            'brand': 'Pilão',
            'packaging': '500g',
            'category': 'Mercearia',
            'barcode': '2000000000060',
            'lowestPrice': '16.59',
            'highestPrice': '20.99',
            'lowestPriceMarket': {'id': 'assai', 'name': 'Assaí Atacadista'},
            'marketCount': 4,
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final products = await ProductsApi(
      client: ApiClient(httpClient: client, baseUrl: 'http://api.test'),
    ).getProducts();

    final cafe = products.single;
    expect(cafe.name, 'Café Tradicional 500g');
    expect(cafe.lowestPriceCents, 1659);
    expect(cafe.lowestPriceMarketName, 'Assaí Atacadista');
    expect(cafe.savingsCents, 440);
    expect(cafe.savingsPercent, 21);
  });

  test(
    'featured products are the ones where comparing saves the most',
    () async {
      final container = ProviderContainer(overrides: catalogOverrides());
      addTearDown(container.dispose);

      final featured = await container.read(featuredProductsProvider.future);

      // Arroz: 25,00 to 31,49 (21%); café: 16,50 to 19,90 (17%);
      // manteiga: 12,99 to 13,49 (4%).
      expect(featured.map((p) => p.id), [
        'arroz-5kg',
        'cafe-500g',
        'manteiga-200g',
      ]);
      expect(featured.first.lowestPriceMarketName, 'Parcial');
    },
  );
}

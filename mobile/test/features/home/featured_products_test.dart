import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/home/presentation/providers/home_products_provider.dart';
import 'package:mercadex/features/products/data/products_api.dart';

class ProductListClient extends ApiClient {
  @override
  Future<http.Response> get(String path, {String? accessToken}) async {
    expect(path, '/products');
    return http.Response(
      '[{"id":"banana-prata-1kg","name":"Banana Prata","packaging":"1kg"}]',
      200,
    );
  }
}

void main() {
  test('products API maps the backend catalog to product cards', () async {
    final products = await ProductsApi(
      client: ProductListClient(),
    ).getProducts();
    expect(products.single.name, 'Banana Prata');
  });

  test('featured products come from the configured product source', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final products = await container.read(hotTodayProductsProvider.future);

    expect(products, hasLength(6));
    expect(products.map((product) => product.id).toSet(), hasLength(6));
  });
}

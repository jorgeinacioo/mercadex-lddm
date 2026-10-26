import 'dart:convert';

import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/domain/search_product.dart';

class ProductsApi {
  const ProductsApi({this.client = const ApiClient()});

  final ApiClient client;

  Future<List<SearchProduct>> getProducts() async {
    final response = await client.get('/products');

    if (response.statusCode != 200) {
      throw StateError('Não foi possível carregar os produtos.');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => SearchProduct.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SearchProduct>> search(String query) async {
    final response = await client.get(
      '/search?query=${Uri.encodeQueryComponent(query)}',
    );

    if (response.statusCode != 200) {
      throw StateError('Não foi possível carregar os produtos.');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => SearchProduct.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProductDeals> getProductDeals(String productId) async {
    final response = await client.get('/products/$productId/deals');

    if (response.statusCode != 200) {
      throw StateError('Não foi possível carregar as ofertas do produto.');
    }

    return ProductDeals.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

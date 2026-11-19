import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';

class ProductsApi {
  const ProductsApi({this.client = const ApiClient()});

  final ApiClient client;

  Future<List<ProductSummary>> getProducts() async {
    return _summaries(await client.getJson('/products'));
  }

  Future<List<ProductSummary>> search(String query) async {
    return _summaries(
      await client.getJson('/search?query=${Uri.encodeQueryComponent(query)}'),
    );
  }

  /// Returns null when no product uses this barcode.
  Future<ProductSummary?> findByBarcode(String barcode) async {
    try {
      final json = await client.getJson(
        '/products/barcode/${Uri.encodeComponent(barcode)}',
      );
      return ProductSummary.fromJson(json! as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  Future<ProductDeals> getProductDeals(String productId) async {
    final json = await client.getJson(
      '/products/${Uri.encodeComponent(productId)}/deals',
    );
    return ProductDeals.fromJson(json! as Map<String, dynamic>);
  }

  List<ProductSummary> _summaries(Object? json) {
    return [
      for (final item in json! as List<dynamic>)
        ProductSummary.fromJson(item as Map<String, dynamic>),
    ];
  }
}

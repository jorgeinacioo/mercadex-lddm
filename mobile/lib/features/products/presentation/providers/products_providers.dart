import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/products/data/products_repository.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(),
);

/// Every product with at least one active price.
final productsProvider = FutureProvider<List<ProductSummary>>((ref) {
  return ref.watch(productsRepositoryProvider).getProducts();
});

final productSearchProvider =
    FutureProvider.family<List<ProductSummary>, String>(
      (ref, query) => ref.watch(productsRepositoryProvider).search(query),
    );

/// Prices of one product in every market. Shared by the product page, the
/// shopping list and the comparison, and refreshed after a price is reported.
final productDealsProvider = FutureProvider.family<ProductDeals, String>(
  (ref, productId) =>
      ref.watch(productsRepositoryProvider).getProductDeals(productId),
);

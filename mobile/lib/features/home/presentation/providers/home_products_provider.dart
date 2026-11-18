import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/core/storage/string_preference_store.dart';
import 'package:mercadex/features/home/data/recent_products_storage.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';

/// Products with the biggest price difference between markets: where
/// comparing pays off the most.
final featuredProductsProvider = FutureProvider<List<ProductSummary>>((
  ref,
) async {
  final products = await ref.watch(productsProvider.future);
  final ranked =
      [
        for (final product in products)
          if (product.marketCount > 1 && product.savingsCents > 0) product,
      ]..sort((a, b) {
        final bySavings = b.savingsPercent.compareTo(a.savingsPercent);
        return bySavings != 0 ? bySavings : a.name.compareTo(b.name);
      });
  return ranked.take(8).toList();
});

final recentProductsStorageProvider = Provider<RecentProductsStorage>(
  (ref) => RecentProductsStorage(SharedPreferencesStringStore()),
);

final recentProductsProvider =
    AsyncNotifierProvider<RecentProductsNotifier, List<ProductSummary>>(
      RecentProductsNotifier.new,
    );

class RecentProductsNotifier extends AsyncNotifier<List<ProductSummary>> {
  static const limit = 8;

  @override
  Future<List<ProductSummary>> build() async {
    try {
      return await ref.watch(recentProductsStorageProvider).read();
    } on Object catch (error) {
      debugPrint('Recent products load failed: $error');
      return [];
    }
  }

  Future<void> add(ProductSummary product) async {
    // Only identity is kept: a stored price would go stale.
    product = ProductSummary.fromStorageJson(product.toStorageJson());
    final current = await future;
    final updated = [
      product,
      ...current.where((recent) => recent.id != product.id),
    ].take(limit).toList();
    if (!ref.mounted) return;
    state = AsyncData(updated);
    try {
      await ref.read(recentProductsStorageProvider).write(updated);
    } on Object catch (error) {
      // History is a convenience; failing to save it must not block the user.
      debugPrint('Recent products save failed: $error');
    }
  }
}

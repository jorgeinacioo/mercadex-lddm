import 'dart:convert';

import 'package:mercadex/core/storage/string_preference_store.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';

const recentProductsKey = 'recent_products';

/// Keeps the last products the user opened, in SharedPreferences.
class RecentProductsStorage {
  RecentProductsStorage(this._store);

  final StringPreferenceStore _store;

  Future<List<ProductSummary>> read() async {
    final saved = await _store.getString(recentProductsKey);
    if (saved == null) return [];
    try {
      return [
        for (final item in jsonDecode(saved) as List<dynamic>)
          ProductSummary.fromStorageJson(item as Map<String, dynamic>),
      ];
    } on Object {
      // A corrupted value only loses the history, never the app start.
      return [];
    }
  }

  Future<void> write(List<ProductSummary> products) {
    return _store.setString(
      recentProductsKey,
      jsonEncode([for (final product in products) product.toStorageJson()]),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/storage/string_preference_store.dart';
import 'package:mercadex/features/home/data/recent_products_storage.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';

import '../../helpers/test_catalog.dart';

class _MemoryStore implements StringPreferenceStore {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

void main() {
  final repository = testProductsRepository();

  test('search ignores accents and case and matches categories', () async {
    expect((await repository.search('CAFE')).map((p) => p.id), ['cafe-500g']);
    expect((await repository.search('mercearia')).map((p) => p.id), [
      'arroz-5kg',
      'cafe-500g',
    ]);
    expect(await repository.search('   '), isEmpty);
    expect(await repository.search('chocolate'), isEmpty);
  });

  test('finds a product by barcode', () async {
    expect(
      (await repository.findByBarcode(' 7890000000017 '))?.id,
      'arroz-5kg',
    );
    expect(await repository.findByBarcode('000'), isNull);
  });

  test('deals come sorted from the cheapest market', () async {
    final deals = await repository.getProductDeals('cafe-500g');
    expect(deals.deals.map((d) => d.marketName), [
      'Médio',
      'Barato',
      'Parcial',
    ]);
    expect(deals.bestDeal!.priceCents, 1650);
    expect(deals.savingsCents, 340);
  });

  test(
    'recent products survive a restart and a corrupted value is ignored',
    () async {
      final store = _MemoryStore();
      final storage = RecentProductsStorage(store);
      await storage.write([
        const ProductSummary(
          id: 'cafe-500g',
          name: 'Café',
          packaging: '500g',
          category: 'Mercearia',
        ),
      ]);

      final restored = await RecentProductsStorage(store).read();
      expect(restored.single.name, 'Café');
      expect(restored.single.category, 'Mercearia');

      store.values[recentProductsKey] = '{not json';
      expect(await storage.read(), isEmpty);
    },
  );
}

import 'package:flutter_riverpod/misc.dart';
import 'package:mercadex/core/demo/demo_catalog.dart';
import 'package:mercadex/features/markets/data/markets_repository.dart';
import 'package:mercadex/features/markets/presentation/providers/markets_providers.dart';
import 'package:mercadex/features/products/data/products_repository.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';

/// Small, fixed catalog so tests do not depend on the demo data.
///
/// - Barato sells everything at the lowest prices.
/// - Medio sells everything a bit more expensive.
/// - Parcial has the cheapest rice but no butter, so it must never win a
///   basket that contains butter.
final testCatalog = DemoCatalog.fromJson({
  'markets': [
    _market('barato', 'Barato'),
    _market('medio', 'Médio'),
    _market('parcial', 'Parcial'),
  ],
  'products': [
    _product('arroz-5kg', 'Arroz Tipo 1 5kg', 'Mercearia', '7890000000017', {
      'barato-centro': '29.99',
      'medio-centro': '31.49',
      'parcial-centro': '25.00',
    }),
    _product('manteiga-200g', 'Manteiga 200g', 'Laticínios', '7890000000024', {
      'barato-centro': '12.99',
      'medio-centro': '13.49',
    }),
    _product('cafe-500g', 'Café Tradicional 500g', 'Mercearia', null, {
      'barato-centro': '18.00',
      'medio-centro': '16.50',
      'parcial-centro': '19.90',
    }),
  ],
});

Map<String, Object?> _market(String id, String name) => {
  'id': id,
  'name': name,
  'branches': [
    {'id': '$id-centro', 'name': '$name Centro', 'address': 'Rua $name, 1'},
  ],
};

Map<String, Object?> _product(
  String id,
  String name,
  String category,
  String? barcode,
  Map<String, String> prices,
) => {
  'id': id,
  'name': name,
  'brand': 'Marca',
  'packaging': id.split('-').last,
  'category': category,
  'barcode': barcode,
  'prices': prices,
};

ProductsRepository testProductsRepository() =>
    ProductsRepository(useMockData: true, loadCatalog: () async => testCatalog);

MarketsRepository testMarketsRepository() =>
    MarketsRepository(useMockData: true, loadCatalog: () async => testCatalog);

/// Provider overrides that read products and markets from [testCatalog].
List<Override> catalogOverrides() => [
  productsRepositoryProvider.overrideWithValue(testProductsRepository()),
  marketsRepositoryProvider.overrideWithValue(testMarketsRepository()),
];

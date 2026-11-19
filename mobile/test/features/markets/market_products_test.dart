import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/demo/demo_catalog.dart';

import '../../helpers/test_catalog.dart';

void main() {
  test('the offline catalog is the same file the backend seeds', () {
    final asset = File('assets/demo/catalog.json');
    final seed = File('../backend/prisma/seed/catalog.json');
    expect(asset.existsSync(), isTrue);
    if (!seed.existsSync()) {
      markTestSkipped('Backend folder not available.');
      return;
    }
    expect(
      asset.readAsStringSync(),
      seed.readAsStringSync(),
      reason: 'Copy backend/prisma/seed/catalog.json to mobile/assets/demo/.',
    );
  });

  test('every demo price points to a real branch and is positive', () {
    final catalog = DemoCatalog.fromJson(
      jsonDecode(File('assets/demo/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final barcodes = <String>{};
    for (final product in catalog.products) {
      expect(product.pricesByBranch, isNotEmpty, reason: product.id);
      for (final entry in product.pricesByBranch.entries) {
        expect(catalog.branch(entry.key), isNotNull, reason: entry.key);
        expect(entry.value, greaterThan(0));
      }
      if (product.barcode != null) {
        expect(barcodes.add(product.barcode!), isTrue, reason: 'duplicate');
      }
    }
  });

  test('a market lists each product it sells once, with its price', () async {
    final market = await testMarketsRepository().getMarket('parcial');
    expect(market.products.map((p) => p.id), ['arroz-5kg', 'cafe-500g']);
    expect(market.products.first.priceCents, 2500);
    expect(market.branches.single.name, 'Parcial Centro');
  });

  test('markets count the products they sell', () async {
    final markets = await testMarketsRepository().getMarkets();
    expect(
      {for (final m in markets) m.id: m.productCount},
      {'barato': 3, 'medio': 3, 'parcial': 2},
    );
  });
}

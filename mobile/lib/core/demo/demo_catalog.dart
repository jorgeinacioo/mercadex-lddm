import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mercadex/core/format/money.dart';

/// Offline catalog used when `USE_MOCK_DATA` is enabled.
///
/// `assets/demo/catalog.json` is a copy of `backend/prisma/seed/catalog.json`,
/// so the offline demo shows exactly the data the backend seeds.
class DemoCatalog {
  DemoCatalog({required this.markets, required this.products});

  factory DemoCatalog.fromJson(Map<String, dynamic> json) {
    return DemoCatalog(
      markets: [
        for (final market in json['markets'] as List<dynamic>)
          DemoMarket.fromJson(market as Map<String, dynamic>),
      ],
      products: [
        for (final product in json['products'] as List<dynamic>)
          DemoProduct.fromJson(product as Map<String, dynamic>),
      ],
    );
  }

  static const assetPath = 'assets/demo/catalog.json';
  static Future<DemoCatalog>? _loading;

  /// Loads the bundled catalog once per app run.
  static Future<DemoCatalog> load({AssetBundle? bundle}) {
    if (bundle != null) return _read(bundle);
    return _loading ??= _read(rootBundle);
  }

  static Future<DemoCatalog> _read(AssetBundle bundle) async {
    final text = await bundle.loadString(assetPath);
    return DemoCatalog.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  final List<DemoMarket> markets;
  final List<DemoProduct> products;

  DemoProduct? product(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  ({DemoMarket market, DemoBranch branch})? branch(String branchId) {
    for (final market in markets) {
      for (final branch in market.branches) {
        if (branch.id == branchId) return (market: market, branch: branch);
      }
    }
    return null;
  }
}

class DemoMarket {
  const DemoMarket({
    required this.id,
    required this.name,
    required this.branches,
  });

  factory DemoMarket.fromJson(Map<String, dynamic> json) {
    return DemoMarket(
      id: json['id'] as String,
      name: json['name'] as String,
      branches: [
        for (final branch in json['branches'] as List<dynamic>)
          DemoBranch.fromJson(branch as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String name;
  final List<DemoBranch> branches;
}

class DemoBranch {
  const DemoBranch({
    required this.id,
    required this.name,
    required this.address,
  });

  factory DemoBranch.fromJson(Map<String, dynamic> json) {
    return DemoBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }

  final String id;
  final String name;
  final String address;
}

class DemoProduct {
  const DemoProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.packaging,
    required this.category,
    required this.barcode,
    required this.pricesByBranch,
  });

  factory DemoProduct.fromJson(Map<String, dynamic> json) {
    return DemoProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      packaging: json['packaging'] as String,
      category: json['category'] as String,
      barcode: json['barcode'] as String?,
      pricesByBranch: {
        for (final entry in (json['prices'] as Map<String, dynamic>).entries)
          entry.key: parseCents(entry.value as String),
      },
    );
  }

  final String id;
  final String name;
  final String brand;
  final String packaging;
  final String category;
  final String? barcode;
  final Map<String, int> pricesByBranch;
}

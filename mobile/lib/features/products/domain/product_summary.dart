import 'package:mercadex/core/format/money.dart';

/// A product as shown in lists: home, search results and recent products.
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.packaging,
    this.brand = '',
    this.category = '',
    this.barcode,
    this.lowestPriceCents,
    this.highestPriceCents,
    this.lowestPriceMarketName,
    this.marketCount = 0,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    final lowest = json['lowestPrice'] as String?;
    final highest = json['highestPrice'] as String?;
    final market = json['lowestPriceMarket'] as Map<String, dynamic>?;
    return ProductSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      packaging: json['packaging'] as String,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      barcode: json['barcode'] as String?,
      lowestPriceCents: lowest == null ? null : parseCents(lowest),
      highestPriceCents: highest == null ? null : parseCents(highest),
      lowestPriceMarketName: market?['name'] as String?,
      marketCount: json['marketCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String packaging;
  final String brand;
  final String category;
  final String? barcode;
  final int? lowestPriceCents;
  final int? highestPriceCents;
  final String? lowestPriceMarketName;
  final int marketCount;

  /// Difference between the most expensive and the cheapest market.
  int get savingsCents {
    final lowest = lowestPriceCents;
    final highest = highestPriceCents;
    if (lowest == null || highest == null) return 0;
    return highest - lowest;
  }

  int get savingsPercent {
    final highest = highestPriceCents;
    if (highest == null || highest == 0) return 0;
    return (savingsCents * 100 / highest).round();
  }

  /// Fields kept when the product is saved as a recent search.
  Map<String, Object?> toStorageJson() => {
    'id': id,
    'name': name,
    'packaging': packaging,
    'brand': brand,
    'category': category,
  };

  factory ProductSummary.fromStorageJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      packaging: json['packaging'] as String,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

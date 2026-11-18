import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';

/// Active price of a product at one market branch.
class ProductMarketDeal {
  const ProductMarketDeal({
    required this.id,
    required this.marketId,
    required this.marketName,
    required this.branchId,
    required this.branchName,
    required this.priceCents,
    this.branchAddress = '',
    this.observedAt,
    this.submittedBy,
  });

  factory ProductMarketDeal.fromJson(Map<String, dynamic> json) {
    final market = json['market'] as Map<String, dynamic>;
    final branch = json['branch'] as Map<String, dynamic>;
    final observedAt = json['observedAt'] as String?;

    return ProductMarketDeal(
      id: json['id'] as String,
      marketId: market['id'] as String,
      marketName: market['name'] as String,
      branchId: branch['id'] as String,
      branchName: branch['name'] as String,
      branchAddress: branch['address'] as String? ?? '',
      priceCents: parseCents(json['price'] as String),
      observedAt: observedAt == null ? null : DateTime.parse(observedAt),
      submittedBy: json['submittedBy'] as String?,
    );
  }

  final String id;
  final String marketId;
  final String marketName;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final int priceCents;
  final DateTime? observedAt;

  /// Username of the person who reported the price; null for reference data.
  final String? submittedBy;
}

class ProductDeals {
  const ProductDeals({
    required this.id,
    required this.name,
    required this.packaging,
    required this.deals,
    this.brand = '',
    this.category = '',
    this.barcode,
  });

  factory ProductDeals.fromJson(Map<String, dynamic> json) {
    final deals = [
      for (final deal in json['deals'] as List<dynamic>)
        ProductMarketDeal.fromJson(deal as Map<String, dynamic>),
    ]..sort((a, b) => a.priceCents.compareTo(b.priceCents));
    return ProductDeals(
      id: json['id'] as String,
      name: json['name'] as String,
      packaging: json['packaging'] as String,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      barcode: json['barcode'] as String?,
      deals: deals,
    );
  }

  final String id;
  final String name;
  final String packaging;
  final String brand;
  final String category;
  final String? barcode;

  /// Sorted from the cheapest to the most expensive.
  final List<ProductMarketDeal> deals;

  ProductMarketDeal? get bestDeal => deals.isEmpty ? null : deals.first;

  int get savingsCents =>
      deals.length < 2 ? 0 : deals.last.priceCents - deals.first.priceCents;

  ProductSummary toSummary() {
    return ProductSummary(
      id: id,
      name: name,
      packaging: packaging,
      brand: brand,
      category: category,
      barcode: barcode,
      lowestPriceCents: deals.isEmpty ? null : deals.first.priceCents,
      highestPriceCents: deals.isEmpty ? null : deals.last.priceCents,
      lowestPriceMarketName: bestDeal?.marketName,
      marketCount: deals.map((deal) => deal.marketId).toSet().length,
    );
  }
}

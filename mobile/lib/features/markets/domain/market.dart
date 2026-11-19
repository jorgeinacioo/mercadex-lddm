import 'package:mercadex/core/format/money.dart';

class Market {
  const Market({required this.id, required this.name, this.productCount = 0});

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] as String,
      name: json['name'] as String,
      productCount: json['productCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final int productCount;
}

class MarketBranch {
  const MarketBranch({
    required this.id,
    required this.name,
    required this.address,
  });

  factory MarketBranch.fromJson(Map<String, dynamic> json) {
    return MarketBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }

  final String id;
  final String name;
  final String address;
}

/// A product sold by the market, with its lowest price there.
class MarketProduct {
  const MarketProduct({
    required this.id,
    required this.name,
    required this.packaging,
    required this.priceCents,
    this.category = '',
  });

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    return MarketProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      packaging: json['packaging'] as String,
      category: json['category'] as String? ?? '',
      priceCents: parseCents(json['price'] as String),
    );
  }

  final String id;
  final String name;
  final String packaging;
  final String category;
  final int priceCents;
}

class MarketDetail extends Market {
  const MarketDetail({
    required super.id,
    required super.name,
    required this.branches,
    required this.products,
  }) : super(productCount: products.length);

  factory MarketDetail.fromJson(Map<String, dynamic> json) {
    return MarketDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      branches: [
        for (final branch in json['branches'] as List<dynamic>)
          MarketBranch.fromJson(branch as Map<String, dynamic>),
      ],
      products: [
        for (final product in json['products'] as List<dynamic>)
          MarketProduct.fromJson(product as Map<String, dynamic>),
      ],
    );
  }

  final List<MarketBranch> branches;
  final List<MarketProduct> products;
}

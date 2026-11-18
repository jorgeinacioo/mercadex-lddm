/// Result of pricing the whole shopping list in every market.
class BasketComparison {
  const BasketComparison({required this.complete, required this.incomplete});

  static const empty = BasketComparison(complete: [], incomplete: []);

  /// Markets that sell every product, from the cheapest basket up.
  final List<MarketComparison> complete;

  /// Markets left out because some products have no price there.
  final List<IncompleteMarket> incomplete;

  MarketComparison? get best => complete.isEmpty ? null : complete.first;

  /// Savings of the best basket against the most expensive complete one.
  int get savingsCents => complete.length < 2
      ? 0
      : complete.last.totalCents - complete.first.totalCents;
}

class MarketComparison {
  const MarketComparison({
    required this.marketId,
    required this.marketName,
    required this.totalCents,
    required this.items,
  });

  final String marketId;
  final String marketName;
  final int totalCents;
  final List<MarketComparisonItem> items;
}

class MarketComparisonItem {
  const MarketComparisonItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
  });

  final String productId;
  final String name;
  final int quantity;
  final int unitPriceCents;

  int get subtotalCents => quantity * unitPriceCents;
}

class IncompleteMarket {
  const IncompleteMarket({
    required this.marketId,
    required this.marketName,
    required this.missingProducts,
  });

  final String marketId;
  final String marketName;
  final List<String> missingProducts;
}

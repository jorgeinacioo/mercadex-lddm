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
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
  });

  final String name;
  final int quantity;
  final int unitPriceCents;

  int get subtotalCents => quantity * unitPriceCents;
}

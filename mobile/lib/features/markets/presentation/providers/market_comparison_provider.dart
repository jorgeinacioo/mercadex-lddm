import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/markets/domain/market_comparison.dart';
import 'package:mercadex/features/products/data/products_repository.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

final marketComparisonProvider = FutureProvider<List<MarketComparison>>((
  ref,
) async {
  final items = await ref.watch(shoppingListProvider.future);
  if (items.isEmpty) return [];

  final products = await Future.wait(
    items.map(
      (item) => const ProductsRepository().getProductDeals(item.productId),
    ),
  );
  final totals = <String, int>{};
  final coverage = <String, int>{};
  final names = <String, String>{};
  final itemsByMarket = <String, List<MarketComparisonItem>>{};

  for (var i = 0; i < products.length; i++) {
    final cheapest = <String, int>{};
    for (final deal in products[i].deals) {
      final cents = (double.parse(deal.price) * 100).round();
      final previous = cheapest[deal.marketId];
      if (previous != null && previous <= cents) continue;
      cheapest[deal.marketId] = cents;
      names[deal.marketId] = deal.marketName;
    }
    for (final entry in cheapest.entries) {
      final item = MarketComparisonItem(
        name: items[i].name,
        quantity: items[i].quantity,
        unitPriceCents: entry.value,
      );
      totals.update(
        entry.key,
        (total) => total + item.subtotalCents,
        ifAbsent: () => item.subtotalCents,
      );
      coverage.update(entry.key, (count) => count + 1, ifAbsent: () => 1);
      itemsByMarket.putIfAbsent(entry.key, () => []).add(item);
    }
  }

  // Compare complete baskets only; missing products must not imply savings.
  return [
    for (final entry in totals.entries)
      if (coverage[entry.key] == items.length)
        MarketComparison(
          marketId: entry.key,
          marketName: names[entry.key]!,
          totalCents: entry.value,
          items: itemsByMarket[entry.key]!,
        ),
  ]..sort((a, b) {
    final result = a.totalCents.compareTo(b.totalCents);
    return result != 0 ? result : a.marketName.compareTo(b.marketName);
  });
});

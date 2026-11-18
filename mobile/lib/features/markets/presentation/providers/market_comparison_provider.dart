import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/markets/domain/market_comparison.dart';
import 'package:mercadex/features/markets/presentation/providers/markets_providers.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

final marketComparisonProvider = FutureProvider<BasketComparison>((ref) async {
  final items = await ref.watch(shoppingListProvider.future);
  if (items.isEmpty) return BasketComparison.empty;

  final markets = await ref.watch(marketsProvider.future);
  final products = await Future.wait(
    items.map((item) async {
      try {
        return await ref.watch(productDealsProvider(item.productId).future);
      } on ApiException catch (error) {
        // A product without prices anymore is missing in every market.
        if (error.isNotFound) return null;
        rethrow;
      }
    }),
  );
  return compareBaskets(
    items,
    products,
    allMarkets: {for (final market in markets) market.id: market.name},
  );
});

/// Prices the list in each market using the cheapest branch of that market.
///
/// Only markets with every product are ranked: a missing product must never
/// look like a saving.
BasketComparison compareBaskets(
  List<ShoppingListItem> items,
  List<ProductDeals?> products, {
  Map<String, String> allMarkets = const {},
}) {
  final names = <String, String>{...allMarkets};
  final itemsByMarket = <String, List<MarketComparisonItem>>{};

  for (var i = 0; i < items.length; i++) {
    final cheapest = <String, int>{};
    for (final deal in products[i]?.deals ?? const <ProductMarketDeal>[]) {
      names[deal.marketId] = deal.marketName;
      final previous = cheapest[deal.marketId];
      if (previous == null || deal.priceCents < previous) {
        cheapest[deal.marketId] = deal.priceCents;
      }
    }
    for (final entry in cheapest.entries) {
      itemsByMarket
          .putIfAbsent(entry.key, () => [])
          .add(
            MarketComparisonItem(
              productId: items[i].productId,
              name: items[i].name,
              quantity: items[i].quantity,
              unitPriceCents: entry.value,
            ),
          );
    }
  }

  // Markets without any of the products are missing all of them.
  for (final marketId in allMarkets.keys) {
    itemsByMarket.putIfAbsent(marketId, () => []);
  }

  final complete = <MarketComparison>[];
  final incomplete = <IncompleteMarket>[];
  for (final entry in itemsByMarket.entries) {
    final priced = entry.value;
    if (priced.length == items.length) {
      complete.add(
        MarketComparison(
          marketId: entry.key,
          marketName: names[entry.key]!,
          totalCents: priced.fold(0, (sum, item) => sum + item.subtotalCents),
          items: priced,
        ),
      );
    } else {
      final pricedIds = priced.map((item) => item.productId).toSet();
      incomplete.add(
        IncompleteMarket(
          marketId: entry.key,
          marketName: names[entry.key]!,
          missingProducts: [
            for (final item in items)
              if (!pricedIds.contains(item.productId)) item.name,
          ],
        ),
      );
    }
  }

  complete.sort((a, b) {
    final result = a.totalCents.compareTo(b.totalCents);
    return result != 0 ? result : a.marketName.compareTo(b.marketName);
  });
  incomplete.sort((a, b) => a.marketName.compareTo(b.marketName));
  return BasketComparison(complete: complete, incomplete: incomplete);
}

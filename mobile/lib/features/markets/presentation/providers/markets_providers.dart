import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/markets/data/markets_repository.dart';
import 'package:mercadex/features/markets/domain/market.dart';

final marketsRepositoryProvider = Provider<MarketsRepository>(
  (ref) => MarketsRepository(),
);

final marketsProvider = FutureProvider<List<Market>>((ref) {
  return ref.watch(marketsRepositoryProvider).getMarkets();
});

final marketDetailProvider = FutureProvider.family<MarketDetail, String>(
  (ref, marketId) => ref.watch(marketsRepositoryProvider).getMarket(marketId),
);

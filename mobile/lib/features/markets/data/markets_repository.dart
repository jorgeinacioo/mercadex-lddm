import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/demo/demo_catalog.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/markets/data/markets_api.dart';
import 'package:mercadex/features/markets/domain/market.dart';

/// Reads markets from the API, or from the bundled demo catalog when
/// `USE_MOCK_DATA` is enabled.
class MarketsRepository {
  MarketsRepository({
    this.api = const MarketsApi(),
    bool? useMockData,
    Future<DemoCatalog> Function()? loadCatalog,
  }) : useMockData = useMockData ?? AppConfig.useMockData,
       _loadCatalog = loadCatalog ?? DemoCatalog.load;

  final MarketsApi api;
  final bool useMockData;
  final Future<DemoCatalog> Function() _loadCatalog;

  Future<List<Market>> getMarkets() async {
    if (!useMockData) return api.getMarkets();
    final catalog = await _loadCatalog();
    return [
      for (final market in catalog.markets)
        Market(
          id: market.id,
          name: market.name,
          productCount: _products(catalog, market).length,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<MarketDetail> getMarket(String marketId) async {
    if (!useMockData) return api.getMarket(marketId);
    final catalog = await _loadCatalog();
    final market = catalog.markets.where((m) => m.id == marketId).firstOrNull;
    if (market == null) {
      throw const ApiException('Supermercado não encontrado.', statusCode: 404);
    }
    return MarketDetail(
      id: market.id,
      name: market.name,
      branches: [
        for (final branch in market.branches)
          MarketBranch(
            id: branch.id,
            name: branch.name,
            address: branch.address,
          ),
      ],
      products: _products(catalog, market),
    );
  }

  List<MarketProduct> _products(DemoCatalog catalog, DemoMarket market) {
    final branchIds = market.branches.map((branch) => branch.id).toSet();
    final products = <MarketProduct>[];
    for (final product in catalog.products) {
      final prices = [
        for (final entry in product.pricesByBranch.entries)
          if (branchIds.contains(entry.key)) entry.value,
      ];
      if (prices.isEmpty) continue;
      products.add(
        MarketProduct(
          id: product.id,
          name: product.name,
          packaging: product.packaging,
          category: product.category,
          priceCents: prices.reduce((a, b) => a < b ? a : b),
        ),
      );
    }
    return products..sort((a, b) => a.name.compareTo(b.name));
  }
}

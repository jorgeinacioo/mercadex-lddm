import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/markets/domain/market.dart';

class MarketsApi {
  const MarketsApi({this.client = const ApiClient()});

  final ApiClient client;

  Future<List<Market>> getMarkets() async {
    final json = await client.getJson('/markets');
    return [
      for (final item in json! as List<dynamic>)
        Market.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<MarketDetail> getMarket(String marketId) async {
    final json = await client.getJson(
      '/markets/${Uri.encodeComponent(marketId)}',
    );
    return MarketDetail.fromJson(json! as Map<String, dynamic>);
  }
}

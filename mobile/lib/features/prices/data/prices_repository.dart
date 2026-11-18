import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';

/// Sends prices reported by users to the API.
///
/// Reporting needs the backend: the offline demo cannot store a price that
/// other people would see, so it refuses instead of faking a success.
class PricesRepository {
  const PricesRepository({this.client = const ApiClient(), this.useMockData});

  final ApiClient client;
  final bool? useMockData;

  bool get isAvailable => !(useMockData ?? AppConfig.useMockData);

  Future<ProductMarketDeal> submit({
    required String productId,
    required String branchId,
    required int priceCents,
    required String accessToken,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Price reports need the Mercadex API.');
    }
    final json = await client.postJson('/prices', {
      'productId': productId,
      'branchId': branchId,
      'price': double.parse(formatDecimal(priceCents)),
    }, accessToken: accessToken);
    return ProductMarketDeal.fromJson(json! as Map<String, dynamic>);
  }
}

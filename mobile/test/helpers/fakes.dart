import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/auth/data/auth_session_storage.dart';
import 'package:mercadex/features/auth/domain/auth_session.dart';
import 'package:mercadex/features/prices/data/prices_repository.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';

class MemoryAuthStorage implements AuthSessionStorage {
  MemoryAuthStorage([this.session]);

  AuthSession? session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}

class SentPrice {
  SentPrice(this.productId, this.branchId, this.priceCents, this.accessToken);

  final String productId;
  final String branchId;
  final int priceCents;
  final String accessToken;
}

class FakePricesRepository extends PricesRepository {
  FakePricesRepository({this.available = true, this.error});

  final bool available;
  ApiException? error;
  final sent = <SentPrice>[];

  @override
  bool get isAvailable => available;

  @override
  Future<ProductMarketDeal> submit({
    required String productId,
    required String branchId,
    required int priceCents,
    required String accessToken,
  }) async {
    if (error != null) throw error!;
    sent.add(SentPrice(productId, branchId, priceCents, accessToken));
    return ProductMarketDeal(
      id: 'new',
      marketId: 'm',
      marketName: 'M',
      branchId: branchId,
      branchName: 'B',
      priceCents: priceCents,
      submittedBy: 'jorge',
      observedAt: DateTime.now(),
    );
  }
}

import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/core/demo/demo_catalog.dart';
import 'package:mercadex/core/format/text.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/products/data/products_api.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';

/// Reads products from the API, or from the bundled demo catalog when
/// `USE_MOCK_DATA` is enabled.
class ProductsRepository {
  ProductsRepository({
    this.api = const ProductsApi(),
    bool? useMockData,
    Future<DemoCatalog> Function()? loadCatalog,
  }) : useMockData = useMockData ?? AppConfig.useMockData,
       _loadCatalog = loadCatalog ?? DemoCatalog.load;

  final ProductsApi api;
  final bool useMockData;
  final Future<DemoCatalog> Function() _loadCatalog;

  Future<List<ProductSummary>> getProducts() async {
    if (!useMockData) return api.getProducts();
    final catalog = await _loadCatalog();
    return [
      for (final product in catalog.products)
        if (product.pricesByBranch.isNotEmpty) _summary(catalog, product),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<ProductSummary>> search(String query) async {
    if (!useMockData) return api.search(query);
    final terms = normalizeText(query).split(RegExp(r'\s+'))
      ..removeWhere((term) => term.isEmpty);
    if (terms.isEmpty) return [];
    final products = await getProducts();
    return [
      for (final product in products)
        if (terms.every(
          normalizeText(
            '${product.name} ${product.brand} ${product.category} '
            '${product.barcode ?? ''}',
          ).contains,
        ))
          product,
    ];
  }

  Future<ProductSummary?> findByBarcode(String barcode) async {
    final code = barcode.trim();
    if (!useMockData) return api.findByBarcode(code);
    final products = await getProducts();
    for (final product in products) {
      if (product.barcode == code) return product;
    }
    return null;
  }

  Future<ProductDeals> getProductDeals(String productId) async {
    if (!useMockData) return api.getProductDeals(productId);
    final catalog = await _loadCatalog();
    final product = catalog.product(productId);
    if (product == null || product.pricesByBranch.isEmpty) {
      throw const ApiException('Produto não encontrado.', statusCode: 404);
    }
    return ProductDeals(
      id: product.id,
      name: product.name,
      packaging: product.packaging,
      brand: product.brand,
      category: product.category,
      barcode: product.barcode,
      deals: _deals(catalog, product),
    );
  }

  ProductSummary _summary(DemoCatalog catalog, DemoProduct product) {
    return ProductDeals(
      id: product.id,
      name: product.name,
      packaging: product.packaging,
      brand: product.brand,
      category: product.category,
      barcode: product.barcode,
      deals: _deals(catalog, product),
    ).toSummary();
  }

  List<ProductMarketDeal> _deals(DemoCatalog catalog, DemoProduct product) {
    return [
      for (final entry in product.pricesByBranch.entries)
        if (catalog.branch(entry.key) case final location?)
          ProductMarketDeal(
            id: '${product.id}@${entry.key}',
            marketId: location.market.id,
            marketName: location.market.name,
            branchId: location.branch.id,
            branchName: location.branch.name,
            branchAddress: location.branch.address,
            priceCents: entry.value,
          ),
    ]..sort((a, b) => a.priceCents.compareTo(b.priceCents));
  }
}

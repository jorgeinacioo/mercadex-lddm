import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/features/products/data/products_api.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/domain/search_product.dart';

class ProductsRepository {
  const ProductsRepository({this.api = const ProductsApi()});

  final ProductsApi api;

  static const mockSearchProducts = [
    SearchProduct(
      id: 'banana-prata-1kg',
      name: 'Banana Prata',
      packaging: '1kg',
    ),
    SearchProduct(
      id: 'banana-nanica-1kg',
      name: 'Banana Nanica',
      packaging: '1kg',
    ),
    SearchProduct(
      id: 'banana-organica-1kg',
      name: 'Banana Organica',
      packaging: '1kg',
    ),
    SearchProduct(
      id: 'coke-2l',
      name: 'Coca-Cola Original 2L',
      packaging: '2L',
    ),
    SearchProduct(id: 'arroz-5kg', name: 'Arroz Tipo 1', packaging: '5kg'),
    SearchProduct(id: 'feijao-1kg', name: 'Feijao Carioca', packaging: '1kg'),
    SearchProduct(id: 'cafe-500g', name: 'Cafe Tradicional', packaging: '500g'),
    SearchProduct(id: 'leite-1l', name: 'Leite Integral', packaging: '1L'),
    SearchProduct(
      id: 'macarrao-500g',
      name: 'Macarrao Espaguete',
      packaging: '500g',
    ),
    SearchProduct(
      id: 'molho-tomate-300g',
      name: 'Molho de Tomate',
      packaging: '300g',
    ),
    SearchProduct(id: 'tomate-1kg', name: 'Tomate Italiano', packaging: '1kg'),
    SearchProduct(
      id: 'peito-frango-1kg',
      name: 'Peito de Frango',
      packaging: '1kg',
    ),
    SearchProduct(id: 'manteiga-200g', name: 'Manteiga', packaging: '200g'),
    SearchProduct(id: 'agua-1-5l', name: 'Agua Mineral', packaging: '1,5L'),
    SearchProduct(
      id: 'iogurte-natural-170g',
      name: 'Iogurte Natural',
      packaging: '170g',
    ),
    SearchProduct(
      id: 'mussarela-200g',
      name: 'Queijo Mussarela',
      packaging: '200g',
    ),
    SearchProduct(
      id: 'farinha-trigo-1kg',
      name: 'Farinha de Trigo',
      packaging: '1kg',
    ),
    SearchProduct(id: 'aveia-170g', name: 'Aveia', packaging: '170g'),
    SearchProduct(id: 'acucar-1kg', name: 'Acucar', packaging: '1kg'),
    SearchProduct(id: 'sal-1kg', name: 'Sal', packaging: '1kg'),
    SearchProduct(
      id: 'oleo-soja-900ml',
      name: 'Oleo de Soja',
      packaging: '900ml',
    ),
    SearchProduct(
      id: 'milho-lata-170g',
      name: 'Milho em Lata',
      packaging: '170g',
    ),
    SearchProduct(
      id: 'ervilha-lata-170g',
      name: 'Ervilha em Lata',
      packaging: '170g',
    ),
    SearchProduct(id: 'atum-lata-170g', name: 'Atum', packaging: '170g'),
    SearchProduct(
      id: 'sardinha-lata-125g',
      name: 'Sardinha',
      packaging: '125g',
    ),
    SearchProduct(id: 'maca-gala-1kg', name: 'Maca', packaging: '1kg'),
    SearchProduct(id: 'laranja-pera-1kg', name: 'Laranja', packaging: '1kg'),
    SearchProduct(id: 'batata-1kg', name: 'Batata', packaging: '1kg'),
    SearchProduct(id: 'cebola-1kg', name: 'Cebola', packaging: '1kg'),
    SearchProduct(id: 'cenoura-1kg', name: 'Cenoura', packaging: '1kg'),
    SearchProduct(id: 'alface-un', name: 'Alface', packaging: 'unidade'),
    SearchProduct(
      id: 'pao-forma-500g',
      name: 'Pao de Forma',
      packaging: '500g',
    ),
    SearchProduct(id: 'ovos-12un', name: 'Ovos', packaging: '12 unidades'),
    SearchProduct(id: 'carne-moida-1kg', name: 'Carne Moida', packaging: '1kg'),
  ];

  static const _mockProducts = [
    ProductDeals(
      id: 'banana-prata-1kg',
      name: 'Banana Prata',
      packaging: '1kg',
      deals: [
        ProductMarketDeal(
          id: 'banana-prata-freshmart',
          marketId: 'freshmart',
          marketName: 'Carrefour',
          branchName: 'Carrefour Central',
          price: '3.99',
        ),
        ProductMarketDeal(
          id: 'banana-prata-value-foods',
          marketId: 'value-foods',
          marketName: 'Pão de Açúcar',
          branchName: 'Pão de Açúcar Central',
          price: '4.19',
        ),
        ProductMarketDeal(
          id: 'banana-prata-daily-market',
          marketId: 'daily-market',
          marketName: 'Atacadão',
          branchName: 'Atacadão Central',
          price: '4.49',
        ),
      ],
    ),
    ProductDeals(
      id: 'banana-nanica-1kg',
      name: 'Banana Nanica',
      packaging: '1kg',
      deals: [
        ProductMarketDeal(
          id: 'banana-nanica-value-foods',
          marketId: 'value-foods',
          marketName: 'Pão de Açúcar',
          branchName: 'Pão de Açúcar Central',
          price: '4.29',
        ),
      ],
    ),
    ProductDeals(
      id: 'banana-organica-1kg',
      name: 'Banana Organica',
      packaging: '1kg',
      deals: [
        ProductMarketDeal(
          id: 'banana-organica-green-grocer',
          marketId: 'green-grocer',
          marketName: 'Assaí Atacadista',
          branchName: 'Assaí Atacadista Central',
          price: '5.99',
        ),
      ],
    ),
  ];

  Future<List<SearchProduct>> getProducts() {
    if (AppConfig.useMockData) return Future.value(mockSearchProducts);
    return api.getProducts();
  }

  Future<List<SearchProduct>> search(String query) {
    if (!AppConfig.useMockData) {
      return api.search(query);
    }

    final normalizedQuery = query.trim().toLowerCase();
    return Future.value(
      mockSearchProducts
          .where(
            (product) => product.name.toLowerCase().contains(normalizedQuery),
          )
          .toList(),
    );
  }

  static const _mockMarkets = [
    (id: 'freshmart', name: 'Carrefour', markup: 40),
    (id: 'value-foods', name: 'Pão de Açúcar', markup: 130),
    (id: 'green-grocer', name: 'Assaí Atacadista', markup: 0),
    (id: 'daily-market', name: 'Atacadão', markup: 20),
  ];

  // Prices in centavos keep generated mock values exact.
  static const _basePrices = {
    'banana-prata-1kg': 399,
    'banana-nanica-1kg': 429,
    'banana-organica-1kg': 599,
    'coke-2l': 899,
    'arroz-5kg': 2999,
    'feijao-1kg': 849,
    'cafe-500g': 1899,
    'leite-1l': 549,
    'macarrao-500g': 599,
    'molho-tomate-300g': 349,
    'tomate-1kg': 899,
    'peito-frango-1kg': 1899,
    'manteiga-200g': 1299,
    'agua-1-5l': 349,
    'iogurte-natural-170g': 329,
    'mussarela-200g': 1499,
    'farinha-trigo-1kg': 629,
    'aveia-170g': 899,
    'acucar-1kg': 499,
    'sal-1kg': 249,
    'oleo-soja-900ml': 899,
    'milho-lata-170g': 429,
    'ervilha-lata-170g': 429,
    'atum-lata-170g': 999,
    'sardinha-lata-125g': 699,
    'maca-gala-1kg': 1099,
    'laranja-pera-1kg': 599,
    'batata-1kg': 549,
    'cebola-1kg': 499,
    'cenoura-1kg': 599,
    'alface-un': 399,
    'pao-forma-500g': 999,
    'ovos-12un': 1299,
    'carne-moida-1kg': 3499,
  };

  Future<ProductDeals> getProductDeals(String productId) async {
    if (!AppConfig.useMockData) {
      return api.getProductDeals(productId);
    }

    final existingProduct = _mockProducts
        .where((product) => product.id == productId)
        .firstOrNull;
    final product = mockSearchProducts
        .where((product) => product.id == productId)
        .first;
    final deals = [
      for (final market in _mockMarkets)
        existingProduct?.deals
                .where((deal) => deal.marketId == market.id)
                .firstOrNull ??
            ProductMarketDeal(
              id: '${product.id}-${market.id}',
              marketId: market.id,
              marketName: market.name,
              branchName: '${market.name} Central',
              price: ((_basePrices[product.id]! + market.markup) / 100)
                  .toStringAsFixed(2),
            ),
    ]..sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));

    return Future.value(
      ProductDeals(
        id: product.id,
        name: product.name,
        packaging: product.packaging,
        deals: deals,
      ),
    );
  }
}

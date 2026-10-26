import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/markets/data/markets_repository.dart';
import 'package:mercadex/features/markets/domain/market.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/features/products/presentation/widgets/product_search_card.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key, required this.marketId});

  final String marketId;

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  late final Future<MarketDetail> _market;

  @override
  void initState() {
    super.initState();
    _market = const MarketsRepository().getMarket(widget.marketId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Supermercado'),
      body: FutureBuilder<MarketDetail>(
        future: _market,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar o supermercado.'),
            );
          }

          final market = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  MarketLogo(marketName: market.name, width: 88, height: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      market.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Unidades', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...market.branches.map(
                (branch) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(branch.name),
                    subtitle: Text(branch.address),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Produtos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (market.products.isEmpty)
                const Text('Nenhum produto disponível.')
              else
                ...market.products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductSearchCard(
                      name: product.name,
                      packaging: product.packaging,
                      onTap: () => context.push('/product/${product.id}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

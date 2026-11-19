import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/format/text.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/state_views.dart';
import 'package:mercadex/features/markets/domain/market.dart';
import 'package:mercadex/features/markets/presentation/providers/markets_providers.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';
import 'package:mercadex/features/products/presentation/widgets/product_cards.dart';

class MarketPage extends ConsumerStatefulWidget {
  const MarketPage({super.key, required this.marketId});

  final String marketId;

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> {
  var _filter = '';

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketDetailProvider(widget.marketId));
    return Scaffold(
      appBar: const AppTopBar(title: 'Supermercado'),
      body: switch (market) {
        AsyncData(:final value) => _content(value),
        AsyncError(:final error) when !market.isLoading => ErrorView(
          message: friendlyError(error),
          onRetry: () => ref.invalidate(marketDetailProvider(widget.marketId)),
        ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _content(MarketDetail market) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final filter = normalizeText(_filter);
    final products = filter.isEmpty
        ? market.products
        : market.products
              .where((product) => normalizeText(product.name).contains(filter))
              .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            MarketLogo(marketName: market.name, width: 92, height: 68),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(market.name, style: text.headlineSmall),
                  Text(
                    '${market.products.length} produtos com preço',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final branch in market.branches)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.place_outlined, color: scheme.primary),
                title: Text(branch.name, style: text.titleSmall),
                subtitle: Text(branch.address),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Produtos e preços', style: text.titleLarge),
        const SizedBox(height: 10),
        TextField(
          onChanged: (value) => setState(() => _filter = value),
          decoration: InputDecoration(
            hintText: 'Filtrar produtos neste mercado',
            prefixIcon: Icon(Icons.filter_list, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: Text('Nenhum produto encontrado.')),
          ),
        for (final product in products)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProductTile(
              product: ProductSummary(
                id: product.id,
                name: product.name,
                packaging: product.packaging,
                category: product.category,
              ),
              priceCents: product.priceCents,
              priceCaption: 'neste mercado',
              onTap: () => context.push('/product/${product.id}'),
            ),
          ),
      ],
    );
  }
}

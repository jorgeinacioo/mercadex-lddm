import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/theme/app_colors.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/state_views.dart';
import 'package:mercadex/features/markets/domain/market_comparison.dart';
import 'package:mercadex/features/markets/presentation/providers/market_comparison_provider.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

class ComparisonPage extends ConsumerWidget {
  const ComparisonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Comparar supermercados'),
      body: switch (itemsAsync) {
        AsyncData(:final value) when value.isEmpty => MessageView(
          icon: Icons.shopping_basket_outlined,
          title: 'Sua lista está vazia',
          message:
              'Adicione produtos à lista para descobrir em qual supermercado '
              'a compra sai mais barata.',
          actionLabel: 'Buscar produtos',
          onAction: () => context.push('/search'),
        ),
        AsyncData(:final value) => _Comparison(items: value),
        AsyncError() when !itemsAsync.isLoading => ErrorView(
          message: 'Não foi possível carregar a lista.',
          onRetry: () => ref.invalidate(shoppingListProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _Comparison extends ConsumerWidget {
  const _Comparison({required this.items});

  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(marketComparisonProvider);
    return switch (comparison) {
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productDealsProvider);
          await ref.read(marketComparisonProvider.future);
        },
        child: _results(context, value),
      ),
      AsyncError(:final error) when !comparison.isLoading => ErrorView(
        message: friendlyError(error),
        onRetry: () {
          ref.invalidate(productDealsProvider);
          ref.invalidate(marketComparisonProvider);
        },
      ),
      _ => const LoadingView(),
    };
  }

  Widget _results(BuildContext context, BasketComparison result) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final units = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final best = result.best;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          '${items.length} ${items.length == 1 ? 'produto' : 'produtos'} · '
          '$units ${units == 1 ? 'unidade' : 'unidades'}',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        if (best == null)
          const MessageView(
            icon: Icons.inventory_2_outlined,
            title: 'Nenhum supermercado tem todos os itens',
            message:
                'A comparação só considera cestas completas, para que um '
                'produto em falta nunca pareça economia.',
          )
        else ...[
          _WinnerCard(best: best, savingsCents: result.savingsCents),
          if (result.complete.length > 1) ...[
            const SizedBox(height: 24),
            Text('Ranking', style: text.titleLarge),
            const SizedBox(height: 10),
            for (var i = 1; i < result.complete.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RankingTile(
                  position: i + 1,
                  comparison: result.complete[i],
                  differenceCents:
                      result.complete[i].totalCents - best.totalCents,
                ),
              ),
          ],
        ],
        if (result.incomplete.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Fora da comparação', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Estes mercados não têm preço para todos os itens da lista.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 10),
          for (final market in result.incomplete)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IncompleteTile(market: market),
            ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Os totais usam o menor preço ativo de cada produto em cada '
                'rede, multiplicado pela quantidade da sua lista.',
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.best, required this.savingsCents});

  final MarketComparison best;
  final int savingsCents;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.deepGreen],
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
              child: Row(
                children: [
                  MarketLogo(
                    marketName: best.marketName,
                    width: 64,
                    height: 48,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Pill(
                          label: 'Mais barato',
                          icon: Icons.emoji_events,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          best.marketName,
                          style: text.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatBrl(best.totalCents),
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                    ),
                  ),
                  const Spacer(),
                  if (savingsCents > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Você economiza',
                          style: text.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          formatBrl(savingsCents),
                          style: text.titleMedium?.copyWith(
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (savingsCents > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'em relação ao mercado mais caro',
                    style: text.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            ExpansionTile(
              key: const PageStorageKey('winner-items'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 18),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              title: Text(
                'Ver itens da cesta',
                style: text.titleSmall?.copyWith(color: Colors.white),
              ),
              children: [
                for (final item in best.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}× ${item.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatBrl(item.subtotalCents),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.position,
    required this.comparison,
    required this.differenceCents,
  });

  final int position;
  final MarketComparison comparison;
  final int differenceCents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text('$positionº', style: text.titleMedium),
            const SizedBox(width: 12),
            MarketLogo(
              marketName: comparison.marketName,
              width: 56,
              height: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(comparison.marketName, style: text.titleSmall),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatBrl(comparison.totalCents), style: text.titleMedium),
                if (differenceCents > 0)
                  Text(
                    '+${formatBrl(differenceCents)}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncompleteTile extends StatelessWidget {
  const _IncompleteTile({required this.market});

  final IncompleteMarket market;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Opacity(
              opacity: 0.6,
              child: MarketLogo(
                marketName: market.marketName,
                width: 56,
                height: 42,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(market.marketName, style: text.titleSmall),
                  Text(
                    'Sem preço para: ${market.missingProducts.join(', ')}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

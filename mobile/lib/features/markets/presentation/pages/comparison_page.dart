import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/core/theme/app_colors.dart';
import 'package:mercadex/features/markets/presentation/providers/market_comparison_provider.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';

class ComparisonPage extends ConsumerWidget {
  const ComparisonPage({super.key});

  String _brl(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Comparar supermercados'),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(shoppingListProvider),
            child: const Text(
              'Não foi possível carregar a lista. Tentar novamente',
            ),
          ),
        ),
        data: (items) => _comparisons(context, ref, items),
      ),
    );
  }

  Widget _comparisons(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingListItem> items,
  ) {
    final comparisons = ref.watch(marketComparisonProvider);

    return comparisons.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(marketComparisonProvider),
          child: const Text('Não foi possível comparar. Tentar novamente'),
        ),
      ),
      data: (markets) {
        if (items.isEmpty) {
          return const Center(
            child: Text('Adicione produtos à sua lista para comparar.'),
          );
        }
        if (markets.isEmpty) {
          return const Center(
            child: Text('Nenhum supermercado tem todos os produtos da lista.'),
          );
        }
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Melhor opção para sua lista',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${items.fold<int>(0, (sum, item) => sum + item.quantity)} unidades na lista',
              ),
              const SizedBox(height: 16),
              ...markets.asMap().entries.map((entry) {
                final comparison = entry.value;
                final isWinner = entry.key == 0;
                final savings = markets.last.totalCents - comparison.totalCents;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isWinner ? AppColors.seed : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isWinner ? AppColors.seed : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}º ${comparison.marketName}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isWinner
                                    ? Colors.white
                                    : AppColors.deepGreen,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (isWinner) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Recomendado',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _brl(comparison.totalCents),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: isWinner ? Colors.white : AppColors.seed,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (isWinner && savings > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Economia estimada: ${_brl(savings)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Em relação ao supermercado mais caro da comparação.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

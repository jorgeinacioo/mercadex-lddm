import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/theme/app_colors.dart';
import 'package:mercadex/features/markets/presentation/providers/market_comparison_provider.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

/// Home highlight: what the current shopping list costs at the best market.
class BasketSummaryCard extends ConsumerWidget {
  const BasketSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingListProvider).asData?.value ?? const [];
    final units = items.fold<int>(0, (sum, item) => sum + item.quantity);

    if (items.isEmpty) {
      return _Frame(
        onTap: () => context.go('/shopping-list'),
        eyebrow: 'Sua lista de compras',
        title: 'Monte sua lista e descubra onde ela sai mais barata',
        footer: const _FooterAction(label: 'Começar minha lista'),
      );
    }

    final comparison = ref.watch(marketComparisonProvider);
    final best = comparison.asData?.value.best;
    final savings = comparison.asData?.value.savingsCents ?? 0;
    final eyebrow =
        '${items.length} ${items.length == 1 ? 'produto' : 'produtos'} · '
        '$units ${units == 1 ? 'unidade' : 'unidades'}';

    return _Frame(
      onTap: () => context.push('/compare'),
      eyebrow: eyebrow,
      title: switch (comparison) {
        AsyncData() when best != null => 'Melhor opção: ${best.marketName}',
        AsyncData() => 'Nenhum mercado tem todos os itens',
        AsyncError() => 'Não foi possível calcular agora',
        _ => 'Calculando o melhor mercado...',
      },
      amount: best == null ? null : formatBrl(best.totalCents),
      savings: savings > 0 ? 'Economize ${formatBrl(savings)}' : null,
      footer: const _FooterAction(label: 'Ver comparação completa'),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.onTap,
    required this.eyebrow,
    required this.title,
    required this.footer,
    this.amount,
    this.savings,
  });

  final VoidCallback onTap;
  final String eyebrow;
  final String title;
  final String? amount;
  final String? savings;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.deepGreen],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_basket_outlined,
                      color: AppColors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        eyebrow,
                        style: text.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                if (amount != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        amount!,
                        style: text.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                      if (savings != null) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              savings!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.deepGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
      ],
    );
  }
}

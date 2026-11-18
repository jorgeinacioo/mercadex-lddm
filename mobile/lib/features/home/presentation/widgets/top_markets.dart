import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/features/markets/presentation/providers/markets_providers.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';

class TopMarkets extends ConsumerWidget {
  const TopMarkets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final markets = ref.watch(marketsProvider);

    return markets.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _InlineError(
        message: friendlyError(error),
        onRetry: () => ref.invalidate(marketsProvider),
      ),
      data: (markets) {
        if (markets.isEmpty) {
          return const Text('Nenhum supermercado disponível.');
        }
        return SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: markets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final market = markets[index];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push('/market/${market.id}'),
                child: SizedBox(
                  width: 104,
                  child: Column(
                    children: [
                      MarketLogo(
                        marketName: market.name,
                        width: 104,
                        height: 68,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        market.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: text.labelLarge?.copyWith(fontSize: 13),
                      ),
                      Text(
                        '${market.productCount} produtos',
                        style: text.bodySmall?.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
      ],
    );
  }
}

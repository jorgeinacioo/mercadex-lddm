import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/markets/data/markets_repository.dart';
import 'package:mercadex/features/markets/domain/market.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';

class TopMarkets extends StatefulWidget {
  const TopMarkets({super.key});

  @override
  State<TopMarkets> createState() => _TopMarketsState();
}

class _TopMarketsState extends State<TopMarkets> {
  late final Future<List<Market>> _markets;

  @override
  void initState() {
    super.initState();
    _markets = const MarketsRepository().getMarkets();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supermercados em destaque',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Market>>(
          future: _markets,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 84,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const Text('Não foi possível carregar os supermercados.');
            }

            final markets = snapshot.data ?? [];
            if (markets.isEmpty) {
              return const Text('Nenhum supermercado disponível.');
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: markets.map((market) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 104,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => context.push('/market/${market.id}'),
                        child: Column(
                          children: [
                            MarketLogo(marketName: market.name),
                            const SizedBox(height: 8),
                            Text(
                              market.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

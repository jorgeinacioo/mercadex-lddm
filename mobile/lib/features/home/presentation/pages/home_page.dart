import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/widgets/app_search_field.dart';
import 'package:mercadex/core/widgets/demo_badge.dart';
import 'package:mercadex/core/widgets/mercadex_logo.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:mercadex/features/home/presentation/providers/home_products_provider.dart';
import 'package:mercadex/features/home/presentation/widgets/basket_summary_card.dart';
import 'package:mercadex/features/home/presentation/widgets/top_markets.dart';
import 'package:mercadex/features/markets/presentation/providers/markets_providers.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';
import 'package:mercadex/features/products/presentation/widgets/product_cards.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(productsProvider);
    ref.invalidate(marketsProvider);
    ref.invalidate(productDealsProvider);
    try {
      await ref.read(featuredProductsProvider.future);
    } catch (_) {
      // The page shows the error state with a retry button.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(authSessionProvider);
    final featured = ref.watch(featuredProductsProvider);
    final recent = ref.watch(recentProductsProvider).asData?.value ?? const [];
    final name = _displayName(session?.username);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Row(
                children: [MercadexLogo(markSize: 34), Spacer(), DemoBadge()],
              ),
              const SizedBox(height: 22),
              Text(
                name == null ? 'Olá!' : 'Olá, $name!',
                style: text.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'O que vamos comprar hoje?',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              AppSearchField(
                hintText: 'Buscar arroz, café, leite...',
                onScan: () => context.push('/scan'),
                onSubmitted: (query) {
                  final searchQuery = query.trim();
                  if (searchQuery.isEmpty) return;
                  context.push(
                    '/search?query=${Uri.encodeQueryComponent(searchQuery)}',
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Shortcut(
                    icon: Icons.qr_code_scanner,
                    label: 'Escanear',
                    onTap: () => context.push('/scan'),
                  ),
                  const SizedBox(width: 10),
                  _Shortcut(
                    icon: Icons.grid_view_rounded,
                    label: 'Categorias',
                    onTap: () => context.push('/search'),
                  ),
                  const SizedBox(width: 10),
                  _Shortcut(
                    icon: Icons.balance_outlined,
                    label: 'Comparar',
                    onTap: () => context.push('/compare'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const BasketSummaryCard(),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Maiores economias',
                subtitle: 'Onde comparar faz mais diferença',
                actionLabel: 'Ver todos',
                onAction: () => context.push('/search'),
              ),
              const SizedBox(height: 12),
              featured.when(
                loading: () => const SizedBox(
                  height: 214,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Row(
                  children: [
                    Expanded(child: Text(friendlyError(error))),
                    TextButton(
                      onPressed: () => ref.invalidate(productsProvider),
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
                data: (products) => products.isEmpty
                    ? const Text('Nenhuma oferta disponível no momento.')
                    : SizedBox(
                        height: 214,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: products.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) => ProductDealCard(
                            product: products[index],
                            onTap: () =>
                                context.push('/product/${products[index].id}'),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 28),
              const _SectionHeader(
                title: 'Supermercados',
                subtitle: 'Toque para ver os preços de cada um',
              ),
              const SizedBox(height: 12),
              const TopMarkets(),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionHeader(title: 'Vistos recentemente'),
                const SizedBox(height: 12),
                for (final product in recent.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProductTile(
                      product: product,
                      onTap: () => context.push('/product/${product.id}'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _displayName(String? username) {
  if (username == null || username.trim().isEmpty) return null;
  final first = username.split(RegExp(r'[.\-_ ]')).first.trim();
  if (first.isEmpty) return null;
  return first[0].toUpperCase() + first.substring(1);
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: text.bodySmall),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                Icon(icon, color: scheme.primary, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

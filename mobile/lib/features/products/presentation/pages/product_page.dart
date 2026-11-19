import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/category_avatar.dart';
import 'package:mercadex/core/widgets/state_views.dart';
import 'package:mercadex/features/auth/presentation/require_login.dart';
import 'package:mercadex/features/home/presentation/providers/home_products_provider.dart';
import 'package:mercadex/features/markets/presentation/providers/markets_providers.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';
import 'package:mercadex/features/products/presentation/widgets/deal_card.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  var _savingList = false;
  var _recorded = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(productDealsProvider(widget.productId), (_, next) {
      final product = next.asData?.value;
      if (product == null || _recorded) return;
      _recorded = true;
      ref.read(recentProductsProvider.notifier).add(product.toSummary());
    }, fireImmediately: true);
  }

  Future<void> _changeQuantity(
    ProductDeals product, {
    required bool add,
  }) async {
    if (_savingList) return;
    setState(() => _savingList = true);
    final list = ref.read(shoppingListProvider.notifier);
    try {
      if (add) {
        await list.add(
          productId: product.id,
          name: product.name,
          packaging: product.packaging,
        );
      } else {
        await list.decrement(product.id);
      }
    } catch (_) {
      if (mounted) {
        showAppNotification(context, 'Não foi possível atualizar sua lista.');
      }
    } finally {
      if (mounted) setState(() => _savingList = false);
    }
  }

  Future<void> _reportPrice(ProductDeals product) async {
    if (!await requireLogin(context, ref) || !mounted) return;
    final sent = await context.push<bool>(
      '/product/${product.id}/informar-preco',
    );
    if (sent != true || !mounted) return;
    ref.invalidate(productDealsProvider(product.id));
    ref.invalidate(productsProvider);
    ref.invalidate(productSearchProvider);
    ref.invalidate(marketsProvider);
    ref.invalidate(marketDetailProvider);
    showAppNotification(context, 'Preço publicado. Obrigado por contribuir!');
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDealsProvider(widget.productId));

    return Scaffold(
      appBar: const AppTopBar(title: 'Produto'),
      body: switch (productAsync) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(productDealsProvider(widget.productId).future),
          child: _content(value),
        ),
        AsyncError(:final error) when !productAsync.isLoading => ErrorView(
          message: error is ApiException && error.isNotFound
              ? 'Este produto não tem preços ativos no momento.'
              : friendlyError(error),
          onRetry: () => ref.invalidate(productDealsProvider(widget.productId)),
        ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _content(ProductDeals product) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final best = product.bestDeal;
    final details = [
      if (product.brand.isNotEmpty) product.brand,
      product.packaging,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryAvatar(category: product.category, size: 68),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.category.isNotEmpty)
                    Text(
                      product.category.toUpperCase(),
                      style: text.bodySmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  Text(product.name, style: text.headlineSmall),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (product.barcode != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(product.barcode!, style: text.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (best != null) _BestPriceCard(product: product, best: best),
        const SizedBox(height: 14),
        _ListControl(
          productId: product.id,
          busy: _savingList,
          onAdd: () => _changeQuantity(product, add: true),
          onRemove: () => _changeQuantity(product, add: false),
        ),
        const SizedBox(height: 26),
        Text(
          'Preços em ${product.deals.length} '
          '${product.deals.length == 1 ? 'supermercado' : 'supermercados'}',
          style: text.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final deal in product.deals)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DealCard(
              deal: deal,
              isBest: identical(deal, best),
              differenceCents: best == null
                  ? 0
                  : deal.priceCents - best.priceCents,
              onTap: () => context.push('/market/${deal.marketId}'),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('Viu outro preço?', style: text.titleMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Informe o valor que você encontrou na prateleira. '
                  'Ele passa a valer para todos que usam o Mercadex.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _reportPrice(product),
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Informar preço'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BestPriceCard extends StatelessWidget {
  const _BestPriceCard({required this.product, required this.best});

  final ProductDeals product;
  final ProductMarketDeal best;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menor preço encontrado',
            style: text.bodySmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatBrl(best.priceCents),
            style: text.headlineSmall?.copyWith(
              fontSize: 32,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(
            best.branchName,
            style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          if (product.savingsCents > 0) ...[
            const SizedBox(height: 10),
            Pill(
              icon: Icons.savings_outlined,
              label:
                  'Até ${formatBrl(product.savingsCents)} a menos que no mais caro',
            ),
          ],
        ],
      ),
    );
  }
}

/// Add button, or a quantity stepper once the product is in the list.
class _ListControl extends ConsumerWidget {
  const _ListControl({
    required this.productId,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final String productId;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingListProvider).asData?.value ?? const [];
    final quantity =
        items
            .where((item) => item.productId == productId)
            .firstOrNull
            ?.quantity ??
        0;

    if (quantity == 0) {
      return FilledButton.icon(
        onPressed: busy ? null : onAdd,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Adicionar à lista de compras'),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary, width: 1.4),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.check_circle, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('Na sua lista', style: text.titleSmall)),
          IconButton(
            tooltip: 'Diminuir',
            onPressed: busy ? null : onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$quantity',
            style: text.titleMedium?.copyWith(color: scheme.primary),
          ),
          IconButton(
            tooltip: 'Aumentar',
            onPressed: busy ? null : onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

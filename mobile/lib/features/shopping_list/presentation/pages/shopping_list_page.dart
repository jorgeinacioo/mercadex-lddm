import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/product_avatar.dart';
import 'package:mercadex/core/theme/app_colors.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final _pending = <String>{};

  Future<void> _mutate(String productId, Future<void> Function() action) async {
    if (_pending.contains(productId)) return;
    setState(() => _pending.add(productId));
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      showAppNotification(
        context,
        'Não foi possível atualizar a lista de compras.',
      );
    } finally {
      if (mounted) setState(() => _pending.remove(productId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingListProvider);
    final items = itemsAsync.asData?.value;

    return Scaffold(
      appBar: const AppTopBar(title: 'Lista de compras'),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: items == null || items.isEmpty
              ? null
              : () => context.push('/compare'),
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Comparar supermercados'),
        ),
      ),
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
        data: (loaded) => loaded.isEmpty
            ? const Center(child: Text('Sua lista de compras está vazia.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: loaded.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = loaded[index];
                  final pending = _pending.contains(item.productId);
                  return _ShoppingListCard(
                    item: item,
                    pending: pending,
                    onDecrease: () => _mutate(
                      item.productId,
                      () => ref
                          .read(shoppingListProvider.notifier)
                          .decrement(item.productId),
                    ),
                    onIncrease: () => _mutate(
                      item.productId,
                      () => ref
                          .read(shoppingListProvider.notifier)
                          .add(
                            productId: item.productId,
                            name: item.name,
                            packaging: item.packaging,
                          ),
                    ),
                    onRemove: () => _mutate(
                      item.productId,
                      () => ref
                          .read(shoppingListProvider.notifier)
                          .remove(item.productId),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ShoppingListCard extends StatelessWidget {
  const _ShoppingListCard({
    required this.item,
    required this.pending,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final ShoppingListItem item;
  final bool pending;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/product/${item.productId}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const ProductAvatar(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.deepGreen,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.packaging,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Diminuir',
                onPressed: pending ? null : onDecrease,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '${item.quantity}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                tooltip: 'Aumentar',
                onPressed: pending ? null : onIncrease,
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              TextButton(
                onPressed: pending ? null : onRemove,
                child: const Text('Remover'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

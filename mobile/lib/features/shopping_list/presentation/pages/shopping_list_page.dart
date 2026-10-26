import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_sort_order.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_sort_order_provider.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/app_notification.dart';
import 'package:mercadex/core/widgets/product_avatar.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final _pending = <String>{};
  var _savingSort = false;

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

  Future<void> _changeSort(ShoppingListSortOrder order) async {
    final current = ref.read(shoppingListSortOrderProvider).asData?.value;
    if (_savingSort || current == order) return;
    setState(() => _savingSort = true);
    try {
      await ref.read(shoppingListSortOrderProvider.notifier).select(order);
    } catch (_) {
      if (!mounted) return;
      showAppNotification(
        context,
        'Não foi possível salvar a ordenação da lista.',
      );
    } finally {
      if (mounted) setState(() => _savingSort = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(shoppingListSortOrderProvider, (previous, next) {
      if (!next.hasError || previous?.hasError == true || !mounted) return;
      showAppNotification(
        context,
        'Não foi possível carregar a ordenação. A lista segue a ordem de adição.',
      );
    });

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
        data: (loaded) {
          final sortAsync = ref.watch(shoppingListSortOrderProvider);
          if (sortAsync.isLoading && !sortAsync.hasValue) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = sortAsync.value ?? ShoppingListSortOrder.createdAt;
          final visible = sortedShoppingList(loaded, order);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SortOrderControl(
                  order: order,
                  enabled: !_savingSort,
                  onChanged: _changeSort,
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text('Sua lista de compras está vazia.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = visible[index];
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
            ],
          );
        },
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.primary,
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

class _SortOrderControl extends StatelessWidget {
  const _SortOrderControl({
    required this.order,
    required this.enabled,
    required this.onChanged,
  });

  final ShoppingListSortOrder order;
  final bool enabled;
  final ValueChanged<ShoppingListSortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ordenar por', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ShoppingListSortOrder>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              selectedBackgroundColor: Theme.of(context).colorScheme.primary,
              selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            segments: const [
              ButtonSegment(
                value: ShoppingListSortOrder.createdAt,
                label: Text('Adição'),
                tooltip: 'Ordem de adição',
              ),
              ButtonSegment(
                value: ShoppingListSortOrder.nameAsc,
                label: Text('Nome A–Z'),
                tooltip: 'Nome do produto',
              ),
            ],
            selected: {order},
            onSelectionChanged: enabled
                ? (selection) => onChanged(selection.first)
                : null,
          ),
        ),
      ],
    );
  }
}

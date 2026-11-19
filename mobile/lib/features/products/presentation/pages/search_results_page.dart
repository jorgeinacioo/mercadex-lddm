import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/widgets/app_search_field.dart';
import 'package:mercadex/core/widgets/app_top_bar.dart';
import 'package:mercadex/core/widgets/category_avatar.dart';
import 'package:mercadex/core/widgets/state_views.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';
import 'package:mercadex/features/products/presentation/providers/products_providers.dart';
import 'package:mercadex/features/products/presentation/widgets/product_cards.dart';

/// Search results, or the whole catalog by category when there is no query.
class SearchResultsPage extends ConsumerStatefulWidget {
  const SearchResultsPage({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  String? _category;

  String get _query => widget.query.trim();

  void _submit(String value) {
    final query = value.trim();
    if (query == _query) return;
    setState(() => _category = null);
    context.replace(
      query.isEmpty
          ? '/search'
          : '/search?query=${Uri.encodeQueryComponent(query)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? ref.watch(productsProvider)
        : ref.watch(productSearchProvider(_query));

    return Scaffold(
      appBar: AppTopBar(title: _query.isEmpty ? 'Produtos' : 'Buscar produtos'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppSearchField(
              key: ValueKey(_query),
              initialValue: _query,
              autofocus: false,
              onScan: () => context.push('/scan'),
              onSubmitted: _submit,
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: friendlyError(error),
                onRetry: () => _query.isEmpty
                    ? ref.invalidate(productsProvider)
                    : ref.invalidate(productSearchProvider(_query)),
              ),
              data: (products) => _results(products),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(List<ProductSummary> products) {
    if (products.isEmpty) {
      return MessageView(
        icon: Icons.search_off_rounded,
        title: 'Nenhum produto encontrado',
        message: 'Tente outro nome, uma marca ou uma categoria, como "café".',
        actionLabel: 'Ver todos os produtos',
        onAction: () => _submit(''),
      );
    }

    final categories = {
      for (final product in products) product.category,
    }.where((category) => category.isNotEmpty).toList()..sort();
    final visible = _category == null
        ? products
        : products.where((product) => product.category == _category).toList();
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (categories.length > 1) ...[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'Todos',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final category in categories)
                  _CategoryChip(
                    label: category,
                    icon: categoryStyle(category).icon,
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _query.isEmpty
              ? '${visible.length} ${visible.length == 1 ? 'produto' : 'produtos'}'
              : '${visible.length} ${visible.length == 1 ? 'resultado' : 'resultados'} para "$_query"',
          style: text.bodySmall,
        ),
        const SizedBox(height: 10),
        for (final product in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProductTile(
              product: product,
              onTap: () => context.push('/product/${product.id}'),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon == null
            ? null
            : Icon(
                icon,
                size: 16,
                color: selected ? scheme.onPrimary : scheme.primary,
              ),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/widgets/category_avatar.dart';
import 'package:mercadex/core/widgets/state_views.dart';
import 'package:mercadex/features/products/domain/product_summary.dart';

/// Full-width row used in search results, recent products and market pages.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
    this.priceCents,
    this.priceCaption,
  });

  final ProductSummary product;
  final VoidCallback onTap;

  /// Price shown on the right; defaults to the product's lowest price.
  final int? priceCents;
  final String? priceCaption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final price = priceCents ?? product.lowestPriceCents;
    final caption =
        priceCaption ??
        (product.lowestPriceMarketName == null
            ? null
            : 'no ${product.lowestPriceMarketName}');
    final details = [
      if (product.brand.isNotEmpty) product.brand,
      product.packaging,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CategoryAvatar(category: product.category),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(details, style: text.bodySmall),
                  ],
                ),
              ),
              if (price != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (priceCents == null)
                      Text('a partir de', style: text.bodySmall),
                    Text(
                      formatBrl(price),
                      style: text.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption,
                        style: text.bodySmall?.copyWith(fontSize: 11.5),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact card for horizontal carousels on the home page.
class ProductDealCard extends StatelessWidget {
  const ProductDealCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final ProductSummary product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final price = product.lowestPriceCents;

    return SizedBox(
      width: 164,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryAvatar(category: product.category, size: 46),
                    const Spacer(),
                    if (product.savingsPercent > 0)
                      Pill(
                        label: '-${product.savingsPercent}%',
                        icon: Icons.trending_down,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  product.brand.isEmpty ? product.packaging : product.brand,
                  style: text.bodySmall,
                ),
                const Spacer(),
                if (price != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    formatBrl(price),
                    style: text.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (product.lowestPriceMarketName != null)
                    Text(
                      'no ${product.lowestPriceMarketName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

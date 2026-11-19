import 'package:flutter/material.dart';
import 'package:mercadex/core/format/money.dart';
import 'package:mercadex/core/format/relative_time.dart';
import 'package:mercadex/core/widgets/state_views.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';
import 'package:mercadex/features/products/domain/product_deals.dart';

/// One market's price for the product being viewed.
class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.deal,
    this.isBest = false,
    this.differenceCents = 0,
    this.onTap,
  });

  final ProductMarketDeal deal;
  final bool isBest;

  /// How much more expensive than the best price.
  final int differenceCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final observedAt = deal.observedAt;
    final source = deal.submittedBy == null
        ? 'Preço de referência'
        : 'Por ${deal.submittedBy}'
              '${observedAt == null ? '' : ' · ${relativeTime(observedAt)}'}';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isBest ? scheme.primary : scheme.outline,
          width: isBest ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MarketLogo(marketName: deal.marketName, width: 64, height: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal.marketName, style: text.titleSmall),
                    Text(deal.branchName, style: text.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          deal.submittedBy == null
                              ? Icons.verified_outlined
                              : Icons.people_alt_outlined,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            source,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isBest)
                    const Pill(label: 'Melhor preço')
                  else if (differenceCents > 0)
                    Text(
                      '+${formatBrl(differenceCents)}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    formatBrl(deal.priceCents),
                    style: text.titleLarge?.copyWith(
                      color: isBest ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

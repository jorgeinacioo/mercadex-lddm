import 'package:flutter/material.dart';
import 'package:mercadex/core/theme/app_colors.dart';
import 'package:mercadex/core/widgets/product_avatar.dart';

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.product,
    required this.market,
    required this.branch,
    required this.price,
    required this.packaging,
    this.onTap,
    this.onMarketTap,
  });

  final String product;
  final String market;
  final String branch;
  final String price;
  final String packaging;
  final VoidCallback? onTap;
  final VoidCallback? onMarketTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProductAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      children: [
                        InkWell(
                          onTap: onMarketTap,
                          child: Text(
                            market,
                            style: onMarketTap == null
                                ? null
                                : TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                          ),
                        ),
                        Text(' · $branch'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'R\$ ${price.replaceAll('.', ',')}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Oferta ativa · $packaging',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

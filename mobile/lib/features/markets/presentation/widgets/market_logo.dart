import 'package:flutter/material.dart';
import 'package:mercadex/core/theme/app_colors.dart';

class MarketLogo extends StatelessWidget {
  const MarketLogo({
    super.key,
    required this.marketName,
    this.width = 96,
    this.height = 64,
  });

  final String marketName;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final asset = switch (marketName.toLowerCase()) {
      'carrefour' => 'assets/markets/carrefour.png',
      'pão de açúcar' => 'assets/markets/pao-de-acucar.png',
      'assaí atacadista' => 'assets/markets/assai.png',
      'atacadão' => 'assets/markets/atacadao.png',
      _ => null,
    };

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: asset == null
          ? _fallback()
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              semanticLabel: 'Logo do supermercado $marketName',
              errorBuilder: (_, _, _) => _fallback(),
            ),
    );
  }

  Widget _fallback() =>
      const Icon(Icons.storefront_outlined, color: AppColors.primary);
}

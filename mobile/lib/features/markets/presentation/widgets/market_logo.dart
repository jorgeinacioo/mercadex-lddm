import 'package:flutter/material.dart';
import 'package:mercadex/core/format/text.dart';

/// Brand logo of a supermarket chain, on a white tile so it reads in both
/// themes. Unknown chains show a store icon.
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
    final asset = marketLogoAsset(marketName);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(height * 0.14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(height * 0.26),
      ),
      child: asset == null
          ? _fallback(scheme)
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              semanticLabel: 'Logo do supermercado $marketName',
              errorBuilder: (_, _, _) => _fallback(scheme),
            ),
    );
  }

  Widget _fallback(ColorScheme scheme) => Icon(
    Icons.storefront_outlined,
    color: const Color(0xFF16A34A),
    size: height * 0.5,
  );
}

String? marketLogoAsset(String marketName) {
  return switch (normalizeText(marketName)) {
    'carrefour' => 'assets/markets/carrefour.png',
    'pao de acucar' => 'assets/markets/pao-de-acucar.png',
    'assai atacadista' || 'assai' => 'assets/markets/assai.png',
    'atacadao' => 'assets/markets/atacadao.png',
    _ => null,
  };
}

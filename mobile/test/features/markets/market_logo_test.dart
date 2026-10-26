import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/features/markets/presentation/widgets/market_logo.dart';

void main() {
  const logos = {
    'Carrefour': 'carrefour.png',
    'Pão de Açúcar': 'pao-de-acucar.png',
    'Assaí Atacadista': 'assai.png',
    'Atacadão': 'atacadao.png',
  };

  for (final entry in logos.entries) {
    testWidgets('${entry.key} uses its bundled logo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MarketLogo(marketName: entry.key)),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/markets/${entry.value}',
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
    });
  }

  testWidgets('unknown market displays fallback icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MarketLogo(marketName: 'Novo mercado')),
    );

    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
  });
}

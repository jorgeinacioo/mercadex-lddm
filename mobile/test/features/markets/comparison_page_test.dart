import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/theme/app_theme.dart';
import 'package:mercadex/features/markets/presentation/pages/comparison_page.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

import '../../helpers/test_catalog.dart';
import '../shopping_list/fake_shopping_list_repository.dart';

void main() {
  Future<ProviderContainer> pumpComparison(
    WidgetTester tester, {
    required List<(String, String)> items,
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...catalogOverrides(),
        shoppingListRepositoryProvider.overrideWithValue(
          FakeShoppingListRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    for (final (id, name) in items) {
      await container
          .read(shoppingListProvider.notifier)
          .add(productId: id, name: name, packaging: 'un');
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const ComparisonPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows the cheapest complete basket, its savings and items', (
    tester,
  ) async {
    await pumpComparison(
      tester,
      items: [
        ('arroz-5kg', 'Arroz'),
        ('arroz-5kg', 'Arroz'),
        ('manteiga-200g', 'Manteiga'),
      ],
    );

    expect(find.text('2 produtos · 3 unidades'), findsOneWidget);
    expect(find.text('Mais barato'), findsOneWidget);
    expect(find.text('Barato'), findsOneWidget);
    expect(find.text('R\$ 72,97'), findsOneWidget);
    // Médio costs 2 × 31,49 + 13,49 = 76,47.
    expect(find.text('R\$ 3,50'), findsWidgets);
    expect(find.text('R\$ 76,47'), findsOneWidget);

    expect(find.text('2× Arroz'), findsNothing);
    await tester.tap(find.text('Ver itens da cesta'));
    await tester.pumpAndSettle();
    expect(find.text('2× Arroz'), findsOneWidget);
    expect(find.text('R\$ 59,98'), findsOneWidget);
    expect(find.text('1× Manteiga'), findsOneWidget);
  });

  testWidgets('lists markets left out for missing products', (tester) async {
    await pumpComparison(
      tester,
      items: [('arroz-5kg', 'Arroz'), ('manteiga-200g', 'Manteiga')],
    );
    await tester.scrollUntilVisible(find.text('Fora da comparação'), 200);

    expect(find.text('Parcial'), findsOneWidget);
    expect(find.text('Sem preço para: Manteiga'), findsOneWidget);
  });

  testWidgets('an empty list explains how to start', (tester) async {
    await pumpComparison(tester, items: const []);
    expect(find.text('Sua lista está vazia'), findsOneWidget);
    expect(find.text('Buscar produtos'), findsOneWidget);
  });
}

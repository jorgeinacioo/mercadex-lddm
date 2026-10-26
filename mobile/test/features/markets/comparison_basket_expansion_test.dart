import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/features/markets/presentation/pages/comparison_page.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

import '../shopping_list/fake_shopping_list_repository.dart';

void main() {
  testWidgets('basket summary expands to show item quantities and prices', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(
          FakeShoppingListRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final list = container.read(shoppingListProvider.notifier);
    await list.add(productId: 'arroz-5kg', name: 'Arroz', packaging: '5kg');
    await list.add(productId: 'arroz-5kg', name: 'Arroz', packaging: '5kg');
    await list.add(
      productId: 'manteiga-200g',
      name: 'Manteiga',
      packaging: '200g',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ComparisonPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 unidades na lista'), findsOneWidget);
    expect(find.text('2x Arroz'), findsNothing);

    await tester.tap(find.text('3 unidades na lista'));
    await tester.pumpAndSettle();

    expect(find.text('2x Arroz'), findsOneWidget);
    expect(find.text('R\$ 59,98'), findsOneWidget);
    expect(find.text('1x Manteiga'), findsOneWidget);
    expect(find.text('R\$ 12,99'), findsOneWidget);
  });
}

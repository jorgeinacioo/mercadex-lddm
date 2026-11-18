import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/features/markets/presentation/providers/market_comparison_provider.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';

import '../../helpers/test_catalog.dart';
import '../shopping_list/fake_shopping_list_repository.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        ...catalogOverrides(),
        shoppingListRepositoryProvider.overrideWithValue(
          FakeShoppingListRepository(),
        ),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> add(String id, String name) => container
      .read(shoppingListProvider.notifier)
      .add(productId: id, name: name, packaging: 'un');

  test('an empty list has nothing to compare', () async {
    final result = await container.read(marketComparisonProvider.future);
    expect(result.complete, isEmpty);
    expect(result.incomplete, isEmpty);
    expect(result.best, isNull);
  });

  test('ranks complete baskets by total using the quantities', () async {
    await add('arroz-5kg', 'Arroz');
    await add('cafe-500g', 'Café');

    final result = await container.read(marketComparisonProvider.future);
    expect(result.complete.map((m) => m.marketId), [
      'parcial',
      'barato',
      'medio',
    ]);
    // Barato and Médio tie at R\$ 47,99; ties are ordered by name.
    expect(result.complete.map((m) => m.totalCents), [4490, 4799, 4799]);

    await add('arroz-5kg', 'Arroz');
    final updated = await container.read(marketComparisonProvider.future);
    expect(updated.best!.marketId, 'parcial');
    expect(updated.best!.totalCents, 2 * 2500 + 1990);
    expect(updated.best!.items.first.quantity, 2);
    expect(updated.best!.items.first.subtotalCents, 5000);
    expect(updated.savingsCents, (2 * 3149 + 1650) - (2 * 2500 + 1990));
  });

  test('a market without every product is never ranked', () async {
    await add('arroz-5kg', 'Arroz');
    await add('manteiga-200g', 'Manteiga');

    final result = await container.read(marketComparisonProvider.future);
    // Parcial has the cheapest rice, but no butter: it must not look cheaper.
    expect(result.complete.map((m) => m.marketId), ['barato', 'medio']);
    expect(result.best!.totalCents, 2999 + 1299);
    expect(result.incomplete.single.marketId, 'parcial');
    expect(result.incomplete.single.missingProducts, ['Manteiga']);
  });

  test('subtotals add up to the total', () async {
    await add('arroz-5kg', 'Arroz');
    await add('manteiga-200g', 'Manteiga');
    await add('manteiga-200g', 'Manteiga');

    final best = (await container.read(marketComparisonProvider.future)).best!;
    expect(
      best.items.fold<int>(0, (sum, item) => sum + item.subtotalCents),
      best.totalCents,
    );
  });

  test('removing the missing product brings the market back', () async {
    await add('arroz-5kg', 'Arroz');
    await add('manteiga-200g', 'Manteiga');
    await container.read(shoppingListProvider.notifier).remove('manteiga-200g');

    final result = await container.read(marketComparisonProvider.future);
    expect(result.best!.marketId, 'parcial');
    expect(result.incomplete, isEmpty);
  });

  test(
    'a market with none of the products is listed as missing them',
    () async {
      await add('manteiga-200g', 'Manteiga');

      final result = await container.read(marketComparisonProvider.future);
      expect(result.complete.map((m) => m.marketId), ['barato', 'medio']);
      expect(result.incomplete.single.marketName, 'Parcial');
      expect(result.incomplete.single.missingProducts, ['Manteiga']);
    },
  );
}

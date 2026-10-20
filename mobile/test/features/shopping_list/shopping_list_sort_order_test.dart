import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/theme/app_theme.dart';
import 'package:mercadex/features/shopping_list/data/shopping_list_preferences.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_sort_order.dart';
import 'package:mercadex/features/shopping_list/presentation/pages/shopping_list_page.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_sort_order_provider.dart';

import 'fake_shopping_list_repository.dart';

void main() {
  group('SharedPreferences sort order', () {
    test('uses created_at when nothing is stored', () async {
      final store = _MemoryStore();
      final preferences = SharedPreferencesShoppingListPreferences(store);

      expect(
        await preferences.readSortOrder(),
        ShoppingListSortOrder.createdAt,
      );
      expect(store.values, isEmpty);
    });

    test('writes and reads name_asc', () async {
      final store = _MemoryStore();
      final preferences = SharedPreferencesShoppingListPreferences(store);

      await preferences.writeSortOrder(ShoppingListSortOrder.nameAsc);

      expect(store.values[shoppingListSortOrderKey], 'name_asc');
      expect(await preferences.readSortOrder(), ShoppingListSortOrder.nameAsc);
    });

    test('treats an unknown stored value as created_at', () async {
      final store = _MemoryStore()..values[shoppingListSortOrderKey] = 'outro';
      final preferences = SharedPreferencesShoppingListPreferences(store);

      expect(
        await preferences.readSortOrder(),
        ShoppingListSortOrder.createdAt,
      );
    });

    test('restores the saved order in a new provider', () async {
      final store = _MemoryStore();
      final preferences = SharedPreferencesShoppingListPreferences(store);
      final first = _container(preferences);

      expect(
        await first.read(shoppingListSortOrderProvider.future),
        ShoppingListSortOrder.createdAt,
      );
      await first
          .read(shoppingListSortOrderProvider.notifier)
          .select(ShoppingListSortOrder.nameAsc);
      first.dispose();

      final second = _container(preferences);
      addTearDown(second.dispose);
      expect(
        await second.read(shoppingListSortOrderProvider.future),
        ShoppingListSortOrder.nameAsc,
      );
    });

    test('switches between the two orders', () async {
      final preferences = SharedPreferencesShoppingListPreferences(
        _MemoryStore(),
      );
      final container = _container(preferences);
      addTearDown(container.dispose);
      final notifier = container.read(shoppingListSortOrderProvider.notifier);

      await notifier.select(ShoppingListSortOrder.nameAsc);
      expect(
        container.read(shoppingListSortOrderProvider).value,
        ShoppingListSortOrder.nameAsc,
      );

      await notifier.select(ShoppingListSortOrder.createdAt);
      expect(
        container.read(shoppingListSortOrderProvider).value,
        ShoppingListSortOrder.createdAt,
      );
      expect(
        await preferences.readSortOrder(),
        ShoppingListSortOrder.createdAt,
      );
    });

    test(
      'reports read and write failures without dropping a saved order',
      () async {
        final store = _MemoryStore()..failReads = true;
        final preferences = SharedPreferencesShoppingListPreferences(store);

        expect(
          () => preferences.readSortOrder(),
          throwsA(isA<ShoppingListPreferencesException>()),
        );

        store.failReads = false;
        await preferences.writeSortOrder(ShoppingListSortOrder.nameAsc);
        store.failWrites = true;
        expect(
          () => preferences.writeSortOrder(ShoppingListSortOrder.createdAt),
          throwsA(isA<ShoppingListPreferencesException>()),
        );
        expect(
          await preferences.readSortOrder(),
          ShoppingListSortOrder.nameAsc,
        );

        final container = _container(preferences);
        addTearDown(container.dispose);
        expect(
          await container.read(shoppingListSortOrderProvider.future),
          ShoppingListSortOrder.nameAsc,
        );
        expect(
          container
              .read(shoppingListSortOrderProvider.notifier)
              .select(ShoppingListSortOrder.createdAt),
          throwsA(isA<ShoppingListPreferencesException>()),
        );
        expect(
          container.read(shoppingListSortOrderProvider).value,
          ShoppingListSortOrder.nameAsc,
        );
      },
    );
  });

  testWidgets('shows both sort options on the shopping list', (tester) async {
    final repository = FakeShoppingListRepository();
    await repository.add(
      productId: 'banana',
      name: 'Banana',
      packaging: '1 kg',
    );
    await repository.add(productId: 'arroz', name: 'Arroz', packaging: '1 kg');
    final preferences = SharedPreferencesShoppingListPreferences(
      _MemoryStore(),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          shoppingListPreferencesProvider.overrideWithValue(preferences),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ShoppingListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ordenar por'), findsOneWidget);
    expect(find.text('Adição'), findsOneWidget);
    expect(find.text('Nome A–Z'), findsOneWidget);

    final box = tester.getRect(find.text('Nome A–Z'));
    expect(box.top, lessThan(844));
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(390));
  });

  test('sorting changes only the presented order', () {
    final created = DateTime.utc(2026, 10, 19, 12);
    final items = [
      _item('banana', 'Banana', 2, created),
      _item('arroz', 'Arroz', 3, created.add(const Duration(minutes: 1))),
    ];

    final byName = sortedShoppingList(items, ShoppingListSortOrder.nameAsc);
    expect(byName.map((item) => item.productId), ['arroz', 'banana']);
    expect(byName.map((item) => item.quantity), [3, 2]);
    expect(items.map((item) => item.productId), ['banana', 'arroz']);

    final byCreation = sortedShoppingList(
      byName,
      ShoppingListSortOrder.createdAt,
    );
    expect(byCreation.map((item) => item.productId), ['banana', 'arroz']);
    expect(byCreation.map((item) => item.quantity), [2, 3]);
  });
}

ProviderContainer _container(ShoppingListPreferences preferences) {
  return ProviderContainer(
    overrides: [shoppingListPreferencesProvider.overrideWithValue(preferences)],
  );
}

ShoppingListItem _item(
  String id,
  String name,
  int quantity,
  DateTime createdAt,
) {
  return ShoppingListItem(
    productId: id,
    name: name,
    packaging: '1',
    quantity: quantity,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class _MemoryStore implements StringPreferenceStore {
  final values = <String, String>{};
  var failReads = false;
  var failWrites = false;

  @override
  Future<String?> getString(String key) async {
    if (failReads) throw StateError('falha de leitura');
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('falha de gravação');
    values[key] = value;
  }
}

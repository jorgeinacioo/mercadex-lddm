import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/features/markets/presentation/providers/market_comparison_provider.dart';
import 'package:mercadex/features/shopping_list/data/shopping_list_database.dart';
import 'package:mercadex/features/shopping_list/data/shopping_list_repository.dart';
import 'package:mercadex/features/shopping_list/presentation/providers/shopping_list_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_shopping_list_repository.dart';

final _databases = <ShoppingListDatabase>[];

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('SQLite shopping list', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('mercadex-list-');
    });

    tearDown(() async {
      for (final database in _databases) {
        await database.close();
      }
      _databases.clear();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('creates, reads, updates and deletes a product', () async {
      final repository = _repository(directory);

      final created = await repository.add(
        productId: 'arroz-5kg',
        name: 'Arroz Tipo 1',
        packaging: '5kg',
      );
      expect(created, hasLength(1));
      expect(created.single.quantity, 1);
      expect(created.single.createdAt.isUtc, isTrue);

      final read = await repository.readAll();
      expect(read.single.name, 'Arroz Tipo 1');
      expect(read.single.packaging, '5kg');
      expect(read.single.quantity, 1);

      final updated = await repository.add(
        productId: 'arroz-5kg',
        name: 'Arroz Tipo 1',
        packaging: '5kg',
      );
      expect(updated.single.quantity, 2);
      expect(updated.single.createdAt, created.single.createdAt);
      expect(
        updated.single.updatedAt.isAfter(created.single.updatedAt) ||
            updated.single.updatedAt.isAtSameMomentAs(created.single.updatedAt),
        isTrue,
      );

      final removed = await repository.remove('arroz-5kg');
      expect(removed, isEmpty);
      expect(await repository.readAll(), isEmpty);
    });

    test('adding the same product twice does not duplicate the row', () async {
      final repository = _repository(directory);

      await Future.wait([
        repository.add(productId: 'leite-1l', name: 'Leite', packaging: '1L'),
        repository.add(productId: 'leite-1l', name: 'Leite', packaging: '1L'),
      ]);

      final items = await repository.readAll();
      expect(items, hasLength(1));
      expect(items.single.quantity, 2);
    });

    test('decrementing quantity 1 deletes the item', () async {
      final repository = _repository(directory);
      await repository.add(
        productId: 'cafe-500g',
        name: 'Café',
        packaging: '500g',
      );
      await repository.add(
        productId: 'cafe-500g',
        name: 'Café',
        packaging: '500g',
      );

      final decreased = await repository.decrement('cafe-500g');
      expect(decreased.single.quantity, 1);

      final deleted = await repository.decrement('cafe-500g');
      expect(deleted, isEmpty);
    });

    test('data survives a new database and repository', () async {
      final firstDatabase = _database(directory);
      final first = SqliteShoppingListRepository(firstDatabase);
      await first.add(
        productId: 'feijao-1kg',
        name: 'Feijão',
        packaging: '1kg',
      );
      await first.add(
        productId: 'feijao-1kg',
        name: 'Feijão',
        packaging: '1kg',
      );
      await firstDatabase.close();

      final secondDatabase = _database(directory);
      final second = SqliteShoppingListRepository(secondDatabase);
      final restored = await second.readAll();
      expect(restored.single.productId, 'feijao-1kg');
      expect(restored.single.quantity, 2);
      await secondDatabase.close();
    });

    test('a recreated provider reads the persisted list', () async {
      final database = _database(directory);
      final container = _container(database);
      addTearDown(container.dispose);
      await container
          .read(shoppingListProvider.notifier)
          .add(productId: 'ovos-12un', name: 'Ovos', packaging: '12un');
      await database.close();

      final reopened = _database(directory);
      final restored = _container(reopened);
      addTearDown(() async {
        restored.dispose();
        await reopened.close();
      });

      final items = await restored.read(shoppingListProvider.future);
      expect(items.single.name, 'Ovos');
      expect(items.single.quantity, 1);
    });

    test('keeps a stable order by creation time', () async {
      final repository = _repository(directory);
      await repository.add(productId: 'b', name: 'Segundo', packaging: '1');
      await repository.add(productId: 'a', name: 'Primeiro', packaging: '1');

      final items = await repository.readAll();
      expect(items.map((item) => item.productId), ['b', 'a']);
    });
  });

  group('Shopping list provider', () {
    test('stays loading until the first read finishes', () async {
      final gate = Completer<void>();
      final fake = FakeShoppingListRepository(readGate: gate);
      final container = ProviderContainer(
        overrides: [shoppingListRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final loading = container.read(shoppingListProvider);
      expect(loading.isLoading, isTrue);
      expect(loading.hasValue, isFalse);

      gate.complete();
      expect(await container.read(shoppingListProvider.future), isEmpty);
    });

    test(
      'a failed write keeps the previous list and reports the error',
      () async {
        final fake = FakeShoppingListRepository();
        final container = ProviderContainer(
          overrides: [shoppingListRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await container
            .read(shoppingListProvider.notifier)
            .add(productId: 'sal-1kg', name: 'Sal', packaging: '1kg');
        fake.failWrites = true;

        expect(
          container
              .read(shoppingListProvider.notifier)
              .add(productId: 'acucar-1kg', name: 'Açúcar', packaging: '1kg'),
          throwsA(isA<ShoppingListWriteException>()),
        );

        final items = await container.read(shoppingListProvider.future);
        expect(items.map((item) => item.productId), ['sal-1kg']);
        expect(items.single.quantity, 1);
      },
    );

    test('comparison follows persisted quantity changes and removal', () async {
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
      await list.add(
        productId: 'manteiga-200g',
        name: 'Manteiga',
        packaging: '200g',
      );

      final compared = await container.read(marketComparisonProvider.future);
      expect(compared.first.totalCents, 4298);

      await list.add(productId: 'arroz-5kg', name: 'Arroz', packaging: '5kg');
      expect(
        (await container.read(
          marketComparisonProvider.future,
        )).first.totalCents,
        7297,
      );

      await list.remove('manteiga-200g');
      final afterDelete = await container.read(marketComparisonProvider.future);
      expect(afterDelete.first.marketId, 'green-grocer');
      expect(afterDelete.first.totalCents, 5998);
    });
  });
}

ShoppingListDatabase _database(Directory directory) {
  final database = ShoppingListDatabase(
    factory: databaseFactoryFfi,
    filePath: path.join(directory.path, 'mercadex.db'),
  );
  _databases.add(database);
  return database;
}

SqliteShoppingListRepository _repository(Directory directory) {
  return SqliteShoppingListRepository(_database(directory));
}

ProviderContainer _container(ShoppingListDatabase database) {
  return ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(
        SqliteShoppingListRepository(database),
      ),
    ],
  );
}

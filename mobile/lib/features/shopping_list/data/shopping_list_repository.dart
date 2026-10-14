import 'package:mercadex/features/shopping_list/data/shopping_list_database.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';
import 'package:sqflite/sqflite.dart';

class ShoppingListWriteException implements Exception {
  ShoppingListWriteException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class ShoppingListRepository {
  Future<List<ShoppingListItem>> readAll();

  Future<List<ShoppingListItem>> add({
    required String productId,
    required String name,
    required String packaging,
  });

  Future<List<ShoppingListItem>> decrement(String productId);

  Future<List<ShoppingListItem>> remove(String productId);
}

class SqliteShoppingListRepository implements ShoppingListRepository {
  SqliteShoppingListRepository(this._database);

  final ShoppingListDatabase _database;
  Future<void> _writes = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then((_) {}, onError: (_, _) {});
    return result;
  }

  @override
  Future<List<ShoppingListItem>> readAll() {
    return _enqueue(() async {
      final database = await _database.open();
      return _query(database);
    });
  }

  @override
  Future<List<ShoppingListItem>> add({
    required String productId,
    required String name,
    required String packaging,
  }) {
    return _enqueue(() async {
      final database = await _database.open();
      final now = _timestamp();
      await database.transaction((txn) async {
        final rows = await txn.query(
          'shopping_list_items',
          where: 'product_id = ?',
          whereArgs: [productId],
        );
        if (rows.isEmpty) {
          await txn.insert('shopping_list_items', {
            'product_id': productId,
            'name': name,
            'packaging': packaging,
            'quantity': 1,
            'created_at': now,
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.abort);
          return;
        }

        final quantity = _quantity(rows.first) + 1;
        await txn.update(
          'shopping_list_items',
          {'quantity': quantity, 'updated_at': now},
          where: 'product_id = ?',
          whereArgs: [productId],
        );
      });
      return _query(database);
    });
  }

  @override
  Future<List<ShoppingListItem>> decrement(String productId) {
    return _enqueue(() async {
      final database = await _database.open();
      final now = _timestamp();
      await database.transaction((txn) async {
        final rows = await txn.query(
          'shopping_list_items',
          where: 'product_id = ?',
          whereArgs: [productId],
        );
        if (rows.isEmpty) {
          throw ShoppingListWriteException('O produto não está na lista.');
        }

        final quantity = _quantity(rows.first);
        if (quantity <= 1) {
          await txn.delete(
            'shopping_list_items',
            where: 'product_id = ?',
            whereArgs: [productId],
          );
          return;
        }

        await txn.update(
          'shopping_list_items',
          {'quantity': quantity - 1, 'updated_at': now},
          where: 'product_id = ?',
          whereArgs: [productId],
        );
      });
      return _query(database);
    });
  }

  @override
  Future<List<ShoppingListItem>> remove(String productId) {
    return _enqueue(() async {
      final database = await _database.open();
      await database.transaction((txn) async {
        final deleted = await txn.delete(
          'shopping_list_items',
          where: 'product_id = ?',
          whereArgs: [productId],
        );
        if (deleted == 0) {
          throw ShoppingListWriteException('O produto não está na lista.');
        }
      });
      return _query(database);
    });
  }

  Future<List<ShoppingListItem>> _query(DatabaseExecutor database) async {
    final rows = await database.query(
      'shopping_list_items',
      orderBy: 'created_at ASC, product_id ASC',
    );
    return rows.map(_itemFromRow).toList();
  }
}

String _timestamp() {
  final utc = DateTime.now().toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  final fractional = (utc.millisecond * 1000 + utc.microsecond)
      .toString()
      .padLeft(6, '0');
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${two(utc.month)}-${two(utc.day)}T'
      '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}.'
      '${fractional}Z';
}

int _quantity(Map<String, Object?> row) {
  final value = row['quantity'];
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw ShoppingListWriteException('Quantidade inválida no banco local.');
}

ShoppingListItem _itemFromRow(Map<String, Object?> row) {
  return ShoppingListItem(
    productId: row['product_id']! as String,
    name: row['name']! as String,
    packaging: row['packaging']! as String,
    quantity: _quantity(row),
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );
}

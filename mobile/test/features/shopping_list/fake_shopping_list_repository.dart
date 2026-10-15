import 'dart:async';

import 'package:mercadex/features/shopping_list/data/shopping_list_repository.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  FakeShoppingListRepository({this.readGate});

  final Completer<void>? readGate;
  final List<ShoppingListItem> _items = [];
  var failWrites = false;
  Future<void> _writes = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then((_) {}, onError: (_, _) {});
    return result;
  }

  @override
  Future<List<ShoppingListItem>> readAll() async {
    final gate = readGate;
    if (gate != null) await gate.future;
    return List<ShoppingListItem>.unmodifiable(_items);
  }

  @override
  Future<List<ShoppingListItem>> add({
    required String productId,
    required String name,
    required String packaging,
  }) {
    return _enqueue(() async {
      _guard();
      final now = DateTime.now().toUtc();
      final index = _items.indexWhere((item) => item.productId == productId);
      if (index == -1) {
        _items.add(
          ShoppingListItem(
            productId: productId,
            name: name,
            packaging: packaging,
            quantity: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        final current = _items[index];
        _items[index] = current.copyWith(
          quantity: current.quantity + 1,
          updatedAt: now,
        );
      }
      return List<ShoppingListItem>.unmodifiable(_items);
    });
  }

  @override
  Future<List<ShoppingListItem>> decrement(String productId) {
    return _enqueue(() async {
      _guard();
      final index = _items.indexWhere((item) => item.productId == productId);
      if (index == -1) {
        throw ShoppingListWriteException('O produto não está na lista.');
      }
      final current = _items[index];
      if (current.quantity <= 1) {
        _items.removeAt(index);
      } else {
        _items[index] = current.copyWith(
          quantity: current.quantity - 1,
          updatedAt: DateTime.now().toUtc(),
        );
      }
      return List<ShoppingListItem>.unmodifiable(_items);
    });
  }

  @override
  Future<List<ShoppingListItem>> remove(String productId) {
    return _enqueue(() async {
      _guard();
      final index = _items.indexWhere((item) => item.productId == productId);
      if (index == -1) {
        throw ShoppingListWriteException('O produto não está na lista.');
      }
      _items.removeAt(index);
      return List<ShoppingListItem>.unmodifiable(_items);
    });
  }

  void _guard() {
    if (failWrites) {
      throw ShoppingListWriteException('Falha simulada ao gravar a lista.');
    }
  }
}

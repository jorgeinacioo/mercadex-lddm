import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/shopping_list/data/shopping_list_database.dart';
import 'package:mercadex/features/shopping_list/data/shopping_list_repository.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';

final shoppingListDatabaseProvider = Provider<ShoppingListDatabase>((ref) {
  final database = ShoppingListDatabase();
  ref.onDispose(database.close);
  return database;
});

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return SqliteShoppingListRepository(ref.watch(shoppingListDatabaseProvider));
});

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>(
      ShoppingListNotifier.new,
    );

class ShoppingListNotifier extends AsyncNotifier<List<ShoppingListItem>> {
  Future<void> _writes = Future<void>.value();

  @override
  Future<List<ShoppingListItem>> build() {
    return ref.watch(shoppingListRepositoryProvider).readAll();
  }

  Future<void> add({
    required String productId,
    required String name,
    required String packaging,
  }) {
    return _mutate(
      (repository) => repository.add(
        productId: productId,
        name: name,
        packaging: packaging,
      ),
    );
  }

  Future<void> decrement(String productId) {
    return _mutate((repository) => repository.decrement(productId));
  }

  Future<void> remove(String productId) {
    return _mutate((repository) => repository.remove(productId));
  }

  Future<void> _mutate(
    Future<List<ShoppingListItem>> Function(ShoppingListRepository repository)
    action,
  ) {
    final operation = _writes.then((_) async {
      await future;
      final items = await action(ref.read(shoppingListRepositoryProvider));
      if (!ref.mounted) return;
      state = AsyncData(items);
    });
    _writes = operation.then((_) {}, onError: (_, _) {});
    return operation;
  }
}

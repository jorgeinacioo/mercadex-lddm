import 'package:mercadex/features/shopping_list/domain/shopping_list_sort_order.dart';
import 'package:mercadex/core/storage/string_preference_store.dart';

export 'package:mercadex/core/storage/string_preference_store.dart';

const shoppingListSortOrderKey = 'shopping_list_sort_order';

class ShoppingListPreferencesException implements Exception {
  ShoppingListPreferencesException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class ShoppingListPreferences {
  Future<ShoppingListSortOrder> readSortOrder();

  Future<void> writeSortOrder(ShoppingListSortOrder order);
}

class SharedPreferencesShoppingListPreferences
    implements ShoppingListPreferences {
  SharedPreferencesShoppingListPreferences(this._store);

  final StringPreferenceStore _store;

  @override
  Future<ShoppingListSortOrder> readSortOrder() async {
    try {
      final value = await _store.getString(shoppingListSortOrderKey);
      return ShoppingListSortOrder.fromStorage(value);
    } on ShoppingListPreferencesException {
      rethrow;
    } catch (_) {
      throw ShoppingListPreferencesException(
        'Não foi possível ler a ordenação da lista.',
      );
    }
  }

  @override
  Future<void> writeSortOrder(ShoppingListSortOrder order) async {
    try {
      await _store.setString(shoppingListSortOrderKey, order.storageValue);
    } on ShoppingListPreferencesException {
      rethrow;
    } catch (_) {
      throw ShoppingListPreferencesException(
        'Não foi possível salvar a ordenação da lista.',
      );
    }
  }
}

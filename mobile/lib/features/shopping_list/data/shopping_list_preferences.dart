import 'package:mercadex/features/shopping_list/domain/shopping_list_sort_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

const shoppingListSortOrderKey = 'shopping_list_sort_order';

class ShoppingListPreferencesException implements Exception {
  ShoppingListPreferencesException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class StringPreferenceStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

class SharedPreferencesStringStore implements StringPreferenceStore {
  SharedPreferencesStringStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
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

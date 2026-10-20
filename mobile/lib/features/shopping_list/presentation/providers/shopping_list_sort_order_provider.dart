import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/shopping_list/data/shopping_list_preferences.dart';
import 'package:mercadex/features/shopping_list/domain/shopping_list_sort_order.dart';

final shoppingListPreferencesProvider = Provider<ShoppingListPreferences>((
  ref,
) {
  return SharedPreferencesShoppingListPreferences(
    SharedPreferencesStringStore(),
  );
});

final shoppingListSortOrderProvider =
    AsyncNotifierProvider<ShoppingListSortOrderNotifier, ShoppingListSortOrder>(
      ShoppingListSortOrderNotifier.new,
    );

class ShoppingListSortOrderNotifier
    extends AsyncNotifier<ShoppingListSortOrder> {
  @override
  Future<ShoppingListSortOrder> build() {
    return ref.watch(shoppingListPreferencesProvider).readSortOrder();
  }

  Future<void> select(ShoppingListSortOrder order) async {
    await ref.read(shoppingListPreferencesProvider).writeSortOrder(order);
    if (!ref.mounted) return;
    state = AsyncData(order);
  }
}

import 'package:mercadex/features/shopping_list/domain/shopping_list_item.dart';

enum ShoppingListSortOrder {
  createdAt('created_at'),
  nameAsc('name_asc');

  const ShoppingListSortOrder(this.storageValue);

  final String storageValue;

  static const fallback = ShoppingListSortOrder.createdAt;

  static ShoppingListSortOrder fromStorage(String? value) {
    for (final order in values) {
      if (order.storageValue == value) return order;
    }
    return fallback;
  }
}

List<ShoppingListItem> sortedShoppingList(
  List<ShoppingListItem> items,
  ShoppingListSortOrder order,
) {
  final sorted = List<ShoppingListItem>.of(items);
  switch (order) {
    case ShoppingListSortOrder.createdAt:
      sorted.sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        if (byTime != 0) return byTime;
        return a.productId.compareTo(b.productId);
      });
    case ShoppingListSortOrder.nameAsc:
      sorted.sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (byName != 0) return byName;
        return a.productId.compareTo(b.productId);
      });
  }
  return sorted;
}

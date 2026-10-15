class ShoppingListItem {
  const ShoppingListItem({
    required this.productId,
    required this.name,
    required this.packaging,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  final String productId;
  final String name;
  final String packaging;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingListItem copyWith({int? quantity, DateTime? updatedAt}) {
    return ShoppingListItem(
      productId: productId,
      name: name,
      packaging: packaging,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

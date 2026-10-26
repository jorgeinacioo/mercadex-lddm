import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mercadex/features/products/data/products_repository.dart';
import 'package:mercadex/features/products/domain/search_product.dart';

final hotTodayProductsProvider = FutureProvider<List<SearchProduct>>((
  ref,
) async {
  final products = [...await const ProductsRepository().getProducts()]
    ..shuffle(Random());
  return products.take(6).toList();
});

final recentProductsProvider =
    NotifierProvider<RecentProductsNotifier, List<SearchProduct>>(
      RecentProductsNotifier.new,
    );

class RecentProductsNotifier extends Notifier<List<SearchProduct>> {
  @override
  List<SearchProduct> build() => [];

  void add(SearchProduct product) {
    state = [
      product,
      ...state.where((recentProduct) => recentProduct.id != product.id),
    ].take(6).toList();
  }
}

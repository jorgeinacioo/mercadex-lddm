import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/features/home/presentation/widgets/home_product_section.dart';
import 'package:mercadex/features/products/domain/search_product.dart';

void main() {
  testWidgets('one-line and two-line product cards have the same height', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeProductSection(
            title: 'Ofertas em destaque',
            emptyMessage: 'Empty',
            products: [
              SearchProduct(id: '1', name: 'Arroz', packaging: '1 kg'),
              SearchProduct(
                id: '2',
                name: 'Leite integral longa vida',
                packaging: '1 L',
              ),
            ],
          ),
        ),
      ),
    );

    final shortCard = find.ancestor(
      of: find.text('Arroz'),
      matching: find.byType(Card),
    );
    final longCard = find.ancestor(
      of: find.text('Leite integral longa vida'),
      matching: find.byType(Card),
    );
    expect(tester.getSize(shortCard).height, tester.getSize(longCard).height);
  });
}

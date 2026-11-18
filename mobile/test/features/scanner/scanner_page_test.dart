import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/theme/app_theme.dart';
import 'package:mercadex/features/scanner/presentation/pages/scanner_page.dart';

import '../../helpers/test_catalog.dart';

void main() {
  Future<void> pumpScanner(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/scan',
      routes: [
        GoRoute(
          path: '/scan',
          builder: (_, _) => const ScannerPage(enableCamera: false),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (_, state) =>
              Scaffold(body: Text('produto ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/search',
          builder: (_, _) => const Scaffold(body: Text('busca')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: catalogOverrides(),
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeCode(WidgetTester tester, String code) async {
    await tester.tap(find.text('Digitar o código'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
  }

  testWidgets('a known barcode opens its product', (tester) async {
    await pumpScanner(tester);
    expect(find.textContaining('câmera não está disponível'), findsOneWidget);

    await typeCode(tester, '7890000000024');

    expect(find.text('produto manteiga-200g'), findsOneWidget);
  });

  testWidgets('an unknown barcode offers a search by name', (tester) async {
    await pumpScanner(tester);
    await typeCode(tester, '123456');

    expect(find.text('Produto não encontrado'), findsOneWidget);
    await tester.tap(find.text('Buscar pelo nome'));
    await tester.pumpAndSettle();
    expect(find.text('busca'), findsOneWidget);
  });
}

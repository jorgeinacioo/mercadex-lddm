// End-to-end check of the main flow against a running backend.
//
// Run with the API up (docker compose up) and a simulator open:
//   flutter test integration_test -d <device> \
//     --dart-define=USE_MOCK_DATA=false \
//     --dart-define=API_URL=http://127.0.0.1:3001
//
// It signs in as `jorge`, so it publishes a real price in the database.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mercadex/core/config/app_config.dart';
import 'package:mercadex/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search, sign in, report a price and see it applied', (
    tester,
  ) async {
    expect(
      AppConfig.useMockData,
      isFalse,
      reason: 'This flow needs the API: pass USE_MOCK_DATA=false and API_URL.',
    );
    await app.main();
    await _settle(tester);

    // Search ignoring accents.
    await tester.enterText(find.byType(TextFormField).first, 'cafe');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(find.text('Café Tradicional 500g'), findsWidgets);

    await tester.tap(find.text('Café Tradicional 500g').first);
    await _settle(tester);
    expect(find.text('Menor preço encontrado'), findsOneWidget);

    // A price lower than any other, unique to this run.
    final cents = 900 + DateTime.now().second;
    final typed = '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';

    await tester.scrollUntilVisible(
      find.text('Informar preço'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Informar preço'));
    await _settle(tester);

    if (find.text('Entre para contribuir').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextFormField).at(0), 'jorge');
      await tester.enterText(find.byType(TextFormField).at(1), 'mercadex');
      await tester.tap(find.text('Entrar'));
      await _settle(tester);
    }

    expect(find.text('Onde você viu?'), findsOneWidget);
    await tester.tap(find.text('Atacadão'));
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField), typed);
    await tester.scrollUntilVisible(
      find.text('Publicar preço'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Publicar preço'));
    await _settle(tester);

    // Back on the product: the reported price is now the best one.
    expect(find.text('Preços em 4 supermercados'), findsOneWidget);
    expect(find.text('Por jorge · agora'), findsOneWidget);
    final bestCard = find.ancestor(
      of: find.text('Melhor preço'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: bestCard, matching: find.text('Atacadão')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bestCard, matching: find.text('R\$ $typed')),
      findsOneWidget,
    );
  });
}

/// Waits for animations and network requests to finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 20),
  );
}

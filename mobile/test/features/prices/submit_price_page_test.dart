import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mercadex/core/network/api_client.dart';
import 'package:mercadex/core/theme/app_theme.dart';
import 'package:mercadex/features/auth/domain/auth_session.dart';
import 'package:mercadex/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:mercadex/features/prices/presentation/pages/submit_price_page.dart';
import 'package:mercadex/features/prices/presentation/providers/prices_providers.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_catalog.dart';

void main() {
  late FakePricesRepository prices;
  late MemoryAuthStorage storage;
  late ProviderContainer container;
  bool? result;

  Future<void> pumpForm(WidgetTester tester, {bool available = true}) async {
    // A phone-sized screen (390 × 844 points), like an iPhone.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    prices = FakePricesRepository(available: available);
    storage = MemoryAuthStorage(
      const AuthSession(username: 'jorge', accessToken: 'jwt'),
    );
    result = null;
    container = ProviderContainer(
      overrides: [
        ...catalogOverrides(),
        pricesRepositoryProvider.overrideWithValue(prices),
        authSessionProvider.overrideWith(
          () => AuthSessionNotifier(
            initialSession: storage.session,
            storage: storage,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await context.push<bool>('/report'),
              child: const Text('abrir'),
            ),
          ),
        ),
        GoRoute(
          path: '/report',
          builder: (_, _) => const SubmitPricePage(productId: 'arroz-5kg'),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSend(WidgetTester tester, String price) async {
    await tester.tap(find.text('Médio'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField), price);
    await tester.ensureVisible(find.text('Publicar preço'));
    await tester.tap(find.text('Publicar preço'));
    await tester.pumpAndSettle();
  }

  testWidgets('publishes the price for the chosen branch and returns', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.text('Arroz Tipo 1 5kg'), findsOneWidget);

    await tester.tap(find.text('Médio'));
    await tester.pumpAndSettle();
    // The current price of that branch is shown for reference.
    expect(find.text('Médio Centro'), findsOneWidget);
    expect(find.text('R\$ 31,49'), findsOneWidget);

    await fillAndSend(tester, '29,90');

    final sent = prices.sent.single;
    expect(sent.productId, 'arroz-5kg');
    expect(sent.branchId, 'medio-centro');
    expect(sent.priceCents, 2990);
    expect(sent.accessToken, 'jwt');
    expect(result, isTrue);
  });

  testWidgets('rejects an invalid price without sending', (tester) async {
    await pumpForm(tester);
    await fillAndSend(tester, '0');

    expect(
      find.text('Informe um valor válido, por exemplo 4,29.'),
      findsOneWidget,
    );
    expect(prices.sent, isEmpty);
    expect(result, isNull);
  });

  testWidgets('an expired session signs the user out and stays on the form', (
    tester,
  ) async {
    await pumpForm(tester);
    prices.error = const ApiException('expirou', statusCode: 401);
    await fillAndSend(tester, '29,90');

    expect(container.read(authSessionProvider), isNull);
    expect(storage.session, isNull);
    expect(result, isNull);
    expect(find.text('Publicar preço'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('the offline demo explains that publishing needs the server', (
    tester,
  ) async {
    await pumpForm(tester, available: false);

    expect(find.textContaining('precisa do servidor'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Publicar preço'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Publicar preço'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });
}

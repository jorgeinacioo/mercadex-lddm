import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercadex/core/widgets/app_notification.dart';

void main() {
  testWidgets('notification overlays content without shifting it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Content'))),
      ),
    );

    final originalPosition = tester.getTopLeft(find.text('Content'));
    showAppNotification(tester.element(find.text('Content')), 'Saved');
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Content')), originalPosition);

    showAppNotification(tester.element(find.text('Content')), 'Updated');
    await tester.pump();
    expect(find.text('Saved'), findsNothing);
    expect(find.text('Updated'), findsOneWidget);

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pump();
    expect(find.text('Updated'), findsNothing);
    expect(tester.getTopLeft(find.text('Content')), originalPosition);
  });

  testWidgets('notification disappears after three seconds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Content'))),
    );

    showAppNotification(tester.element(find.text('Content')), 'Temporary');
    await tester.pump();
    expect(find.text('Temporary'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Temporary'), findsNothing);
  });
}

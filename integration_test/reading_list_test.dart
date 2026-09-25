import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_testability_lab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('GUI-01 add a book through the running app', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title-input')), 'GUI smoke book');
    await tester.tap(find.byKey(const Key('add-book')));
    await tester.pumpAndSettle();
    expect(find.text('GUI smoke book'), findsOneWidget);
  });
}

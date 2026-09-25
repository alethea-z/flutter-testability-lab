import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testability_lab/src/app.dart';
import 'package:flutter_testability_lab/src/data.dart';
import 'package:flutter_testability_lab/src/domain.dart';
import 'package:flutter_testability_lab/src/services.dart';
class _Store implements BookStore { List<Book> items=[]; @override Future<List<Book>> read() async=>items; @override Future<void> write(List<Book> b) async { items=List.of(b); } }
class _FailingImporter implements BookImporter { @override Future<List<Book>> importBooks(ImportMode mode) async => throw const ImportFailure('controlled failure'); }
void main() {
 testWidgets('WID-ADD-01 adds a book through the visible form', (tester) async { final r=BookRepository(_Store()); await tester.pumpWidget(MaterialApp(home:ReadingListPage(repository:r, importer:DemoImporter()))); await tester.enterText(find.byKey(const Key('title-input')), 'Dune'); await tester.tap(find.byKey(const Key('add-book'))); await tester.pumpAndSettle(); expect(find.text('Dune'), findsOneWidget); });
 testWidgets('WID-ERR-01 shows service error to the user', (tester) async { final r=BookRepository(_Store()); await tester.pumpWidget(MaterialApp(home:ReadingListPage(repository:r, importer:_FailingImporter()))); await tester.tap(find.byKey(const Key('import-books'))); await tester.pumpAndSettle(); expect(find.text('controlled failure'), findsOneWidget); });
}

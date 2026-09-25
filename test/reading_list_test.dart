import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testability_lab/src/data.dart';
import 'package:flutter_testability_lab/src/domain.dart';
import 'package:flutter_testability_lab/src/services.dart';

class MemoryStore implements BookStore {
  List<Book> items = [];
  @override Future<List<Book>> read() async => List.of(items);
  @override Future<void> write(List<Book> books) async { items = List.of(books); }
}

void main() {
  group('Unit: validation and business logic', () {
    test('VAL-01 rejects blank titles', () => expect(validateTitle('  '), 'Title is required'));
    test('VAL-02 accepts and trims valid titles through repository', () async {
      final store = MemoryStore(); final repo = BookRepository(store);
      await repo.add('  Dune  ');
      expect(repo.books.single.title, 'Dune');
    });
    test('BOOK-01 search is case-insensitive across title and author', () async {
      final repo = BookRepository(MemoryStore()); await repo.add('Dune', author: 'Frank Herbert');
      expect(repo.search('HERBERT').length, 1); expect(repo.search('missing'), isEmpty);
    });
  });
  group('Service: controlled importer outcomes', () {
    final service = DemoImporter();
    test('SVC-01 success returns deterministic sample', () async => expect((await service.importBooks(ImportMode.success)).single.id, 'import-1'));
    for (final mode in [ImportMode.error, ImportMode.timeout, ImportMode.offline]) {
      test('SVC-${mode.name} reports an explicit failure', () async => expect(() => service.importBooks(mode), throwsA(isA<ImportFailure>())));
    }
  });
}

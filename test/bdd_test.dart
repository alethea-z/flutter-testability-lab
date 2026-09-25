import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testability_lab/src/data.dart';
import 'package:flutter_testability_lab/src/domain.dart';
import 'package:flutter_testability_lab/src/services.dart';

class _Store implements BookStore { List<Book> books=[]; @override Future<List<Book>> read() async => books; @override Future<void> write(List<Book> b) async { books=List.of(b); } }
void main() {
  final feature = File('test/features/reading_list.feature').readAsLinesSync();
  final scenarios = <String, List<String>>{};
  String? current;
  for (final line in feature) {
    final s = RegExp(r'Scenario: \[(.+?)\]').firstMatch(line);
    if (s != null) { current=s.group(1); scenarios[current!]=[]; }
    else if (current != null && RegExp(r'^\s+(Given|When|Then|And) ').hasMatch(line)) { scenarios[current]!.add(line.trim()); }
  }
  for (final id in ['BOOK-ADD-01','BOOK-VALID-01','BOOK-SEARCH-01','IMPORT-01']) {
    test('BDD $id executes Gherkin scenario', () async {
      final steps=scenarios[id]!; expect(steps, isNotEmpty);
      final repo=BookRepository(_Store()); String? error; List<Book> matches=[];
      for (final step in steps) {
        if (step == 'Given an empty reading list') { expect(repo.books, isEmpty); }
        else if (step == 'Given the reading list contains "Dune"') { await repo.add('Dune'); }
        else if (step == 'When I add the book "Dune"') { await repo.add('Dune'); }
        else if (step == 'When I add a blank title') { try { await repo.add(' '); } on ArgumentError catch(e) { error=e.message as String; } }
        else if (step == 'Then the reading list contains "Dune"') { expect(repo.books.map((b)=>b.title), contains('Dune')); }
        else if (step == 'Then the validation error is "Title is required"') { expect(error,'Title is required'); }
        else if (step == 'When I search for "dUnE"') { matches=repo.search('dUnE'); }
        else if (step == 'Then one matching book is found') { expect(matches,hasLength(1)); }
        else if (step == 'When I request an import error') { try { await DemoImporter().importBooks(ImportMode.error); } on ImportFailure catch(e) { error=e.message; } }
        else if (step == 'Then the import fails with "Import service returned an error"') { expect(error,'Import service returned an error'); }
        else { fail('Unimplemented Gherkin step: $step'); }
      }
    });
  }
}

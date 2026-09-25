import 'domain.dart';

class DemoImporter implements BookImporter {
  @override Future<List<Book>> importBooks(ImportMode mode) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    switch (mode) {
      case ImportMode.success: return [const Book(id: 'import-1', title: 'The Pragmatic Programmer', author: 'David Thomas')];
      case ImportMode.error: throw const ImportFailure('Import service returned an error');
      case ImportMode.timeout: throw const ImportFailure('Import timed out');
      case ImportMode.offline: throw const ImportFailure('Device is offline');
    }
  }
}
class ImportFailure implements Exception { const ImportFailure(this.message); final String message; @override String toString() => message; }

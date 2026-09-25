import 'package:flutter/material.dart';
import 'data.dart';
import 'domain.dart';

class ReadingListApp extends StatelessWidget {
  const ReadingListApp({super.key, required this.repository, required this.importer});
  final BookRepository repository;
  final BookImporter importer;
  @override Widget build(BuildContext context) => MaterialApp(title: 'Reading list lab', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)), home: ReadingListPage(repository: repository, importer: importer));
}

class ReadingListPage extends StatefulWidget {
  const ReadingListPage({super.key, required this.repository, required this.importer});
  final BookRepository repository;
  final BookImporter importer;
  @override State<ReadingListPage> createState() => _ReadingListPageState();
}
class _ReadingListPageState extends State<ReadingListPage> {
  final _title = TextEditingController(); final _author = TextEditingController(); final _search = TextEditingController();
  String? _error; String _notice = ''; ImportMode _mode = ImportMode.success;
  @override void dispose() { _title.dispose(); _author.dispose(); _search.dispose(); super.dispose(); }
  Future<void> _add() async { try { await widget.repository.add(_title.text, author: _author.text); _title.clear(); _author.clear(); setState(() { _error = null; _notice = 'Book added'; }); } on ArgumentError catch (e) { setState(() { _error = e.message.toString(); _notice = ''; }); } }
  Future<void> _edit(Book b) async { _title.text = b.title; _author.text = b.author; await _addEditDialog(b); }
  Future<void> _addEditDialog(Book b) async { final title = TextEditingController(text: b.title); final author = TextEditingController(text: b.author); await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Edit book'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(key: const Key('edit-title'), controller: title), TextField(controller: author)]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(key: const Key('save-edit'), onPressed: () async { try { await widget.repository.update(b, title.text, author: author.text); if (context.mounted) Navigator.pop(context); setState(() => _notice = 'Book updated'); } on ArgumentError catch (e) { setState(() => _error = e.message.toString()); } }, child: const Text('Save'))])); title.dispose(); author.dispose(); }
  Future<void> _import() async { try { final books = await widget.importer.importBooks(_mode); for (final b in books) { await widget.repository.add(b.title, author: b.author); } setState(() { _notice = 'Imported ${books.length} book'; _error = null; }); } catch (e) { setState(() { _error = e.toString(); _notice = ''; }); } }
  @override Widget build(BuildContext context) {
    final books = widget.repository.search(_search.text);
    return Scaffold(appBar: AppBar(title: const Text('Reading list lab')), body: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(key: const Key('title-input'), controller: _title, decoration: const InputDecoration(labelText: 'Book title')),
      TextField(key: const Key('author-input'), controller: _author, decoration: const InputDecoration(labelText: 'Author (optional)')),
      Row(children: [Expanded(child: ElevatedButton(key: const Key('add-book'), onPressed: _add, child: const Text('Add book'))), const SizedBox(width: 8), Expanded(child: DropdownButton<ImportMode>(key: const Key('import-mode'), value: _mode, isExpanded: true, items: ImportMode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(), onChanged: (m) => setState(() => _mode = m!)))]),
      ElevatedButton(key: const Key('import-books'), onPressed: _import, child: const Text('Import sample book')),
      if (_error != null) Text(_error!, key: const Key('error-message'), style: const TextStyle(color: Colors.red)),
      if (_notice.isNotEmpty) Text(_notice, key: const Key('notice-message')),
      TextField(key: const Key('search-input'), controller: _search, decoration: const InputDecoration(labelText: 'Search books'), onChanged: (_) => setState(() {})),
      Expanded(child: books.isEmpty ? const Center(child: Text('No books found')) : ListView.builder(itemCount: books.length, itemBuilder: (context, i) { final b = books[i]; return ListTile(key: Key('book-${b.id}'), title: Text(b.title), subtitle: Text(b.author), leading: Checkbox(key: Key('read-${b.id}'), value: b.isRead, onChanged: (_) async { await widget.repository.toggleRead(b); setState(() {}); }), trailing: Wrap(children: [IconButton(key: Key('edit-${b.id}'), onPressed: () => _edit(b), icon: const Icon(Icons.edit)), IconButton(key: Key('delete-${b.id}'), onPressed: () async { await widget.repository.delete(b); setState(() => _notice = 'Book deleted'); }, icon: const Icon(Icons.delete))])); })),
    ])));
  }
}

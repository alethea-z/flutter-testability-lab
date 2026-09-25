import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain.dart';

class PreferencesBookStore implements BookStore {
  static const _key = 'reading_list_v1';
  @override Future<List<Book>> read() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }
  @override Future<void> write(List<Book> books) async => (await SharedPreferences.getInstance()).setString(_key, jsonEncode(books.map((b) => b.toJson()).toList()));
}

class BookRepository {
  BookRepository(this.store);
  final BookStore store;
  List<Book> books = [];
  Future<void> load() async => books = await store.read();
  Future<void> add(String title, {String author = ''}) async {
    final error = validateTitle(title); if (error != null) throw ArgumentError(error);
    books = [...books, Book(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title.trim(), author: author.trim())];
    await store.write(books);
  }
  Future<void> update(Book old, String title, {String author = ''}) async {
    final error = validateTitle(title); if (error != null) throw ArgumentError(error);
    books = books.map((b) => b.id == old.id ? b.copyWith(title: title.trim(), author: author.trim()) : b).toList(); await store.write(books);
  }
  Future<void> delete(Book book) async { books = books.where((b) => b.id != book.id).toList(); await store.write(books); }
  Future<void> toggleRead(Book book) async { books = books.map((b) => b.id == book.id ? b.copyWith(isRead: !b.isRead) : b).toList(); await store.write(books); }
  List<Book> search(String query) => books.where((b) => ('${b.title} ${b.author}').toLowerCase().contains(query.trim().toLowerCase())).toList();
}

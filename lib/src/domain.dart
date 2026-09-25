class Book {
  const Book({required this.id, required this.title, this.author = '', this.isRead = false});
  final String id;
  final String title;
  final String author;
  final bool isRead;
  Book copyWith({String? title, String? author, bool? isRead}) => Book(id: id, title: title ?? this.title, author: author ?? this.author, isRead: isRead ?? this.isRead);
  Map<String, Object?> toJson() => {'id': id, 'title': title, 'author': author, 'isRead': isRead};
  factory Book.fromJson(Map<String, dynamic> json) => Book(id: json['id'] as String, title: json['title'] as String, author: json['author'] as String? ?? '', isRead: json['isRead'] as bool? ?? false);
}

String? validateTitle(String title) {
  if (title.trim().isEmpty) return 'Title is required';
  if (title.trim().length > 80) return 'Title must be 80 characters or fewer';
  return null;
}

abstract interface class BookStore { Future<List<Book>> read(); Future<void> write(List<Book> books); }
abstract interface class BookImporter { Future<List<Book>> importBooks(ImportMode mode); }
enum ImportMode { success, error, timeout, offline }

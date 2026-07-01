import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';

/// Owns the user's library: the Hive records plus the book and cover files on
/// disk. A [ChangeNotifier] so the library screen rebuilds when books are
/// added, removed, or their progress changes.
class LibraryStore extends ChangeNotifier {
  LibraryStore._(this._box, this.booksDir, this.coversDir, this.reflowDir);

  static const _boxName = 'papyr_library';

  final Box<Book> _box;

  /// `<docs>/books` — where imported book files are copied.
  final Directory booksDir;

  /// `<docs>/covers` — where extracted cover images are written.
  final Directory coversDir;

  /// `<docs>/reflow` — cached extracted text for the PDF Reading view.
  final Directory reflowDir;

  static Future<LibraryStore> open() async {
    final box = await Hive.openBox<Book>(_boxName);
    final docs = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(docs.path, 'books'));
    final coversDir = Directory(p.join(docs.path, 'covers'));
    final reflowDir = Directory(p.join(docs.path, 'reflow'));
    await booksDir.create(recursive: true);
    await coversDir.create(recursive: true);
    await reflowDir.create(recursive: true);
    return LibraryStore._(box, booksDir, coversDir, reflowDir);
  }

  /// Cached reflow-text file for a book (may not exist yet).
  File reflowCacheFile(Book book) =>
      File(p.join(reflowDir.path, '${book.id}.txt'));

  /// Returns an existing book with the same content hash, or null.
  Book? findByHash(String? hash) {
    if (hash == null) return null;
    return _box.values.firstWhereOrNull((b) => b.contentHash == hash);
  }

  /// Books, most-recently-opened first (falling back to date added).
  List<Book> get books {
    final list = _box.values.toList();
    list.sort((a, b) {
      final at = a.lastOpenedAt ?? a.addedAt;
      final bt = b.lastOpenedAt ?? b.addedAt;
      return bt.compareTo(at);
    });
    return list;
  }

  bool get isEmpty => _box.isEmpty;

  /// Absolute path to a book's file.
  File bookFile(Book book) => File(p.join(booksDir.path, book.fileName));

  /// Absolute path to a book's cover, or null if it has none.
  File? coverFile(Book book) => book.coverFileName == null
      ? null
      : File(p.join(coversDir.path, book.coverFileName!));

  Future<void> add(Book book) async {
    await _box.put(book.id, book);
    notifyListeners();
  }

  /// Removes a book and deletes its file and cover from disk.
  Future<void> delete(Book book) async {
    try {
      final f = bookFile(book);
      if (await f.exists()) await f.delete();
      final c = coverFile(book);
      if (c != null && await c.exists()) await c.delete();
      final r = reflowCacheFile(book);
      if (await r.exists()) await r.delete();
    } catch (_) {
      // File already gone — the record removal below is what matters.
    }
    await book.delete();
    notifyListeners();
  }

  /// Updates a book's editable metadata (title and author).
  Future<void> updateDetails(Book book,
      {required String title, String? author}) async {
    final t = title.trim();
    if (t.isNotEmpty) book.title = t;
    final a = author?.trim();
    book.author = (a == null || a.isEmpty) ? null : a;
    await book.save();
    notifyListeners();
  }

  /// Marks a book finished (progress 1.0) or back to unread (0.0) by hand,
  /// without touching its last-opened time or saved position.
  Future<void> setReadStatus(Book book, {required bool finished}) async {
    book.progress = finished ? 1.0 : 0.0;
    await book.save();
    notifyListeners();
  }

  /// Marks a book as opened now (moves it to the front of the library).
  Future<void> markOpened(Book book) async {
    book.lastOpenedAt = DateTime.now();
    await book.save();
    notifyListeners();
  }

  /// Persists reading position + progress after a session.
  Future<void> saveProgress(Book book,
      {required double progress, String? locator}) async {
    book.progress = progress.clamp(0.0, 1.0);
    if (locator != null) book.locator = locator;
    book.lastOpenedAt = DateTime.now();
    await book.save();
    notifyListeners();
  }

  Future<void> addBookmark(Book book, Bookmark bookmark) async {
    // Avoid duplicate bookmarks at the same spot.
    if (book.bookmarks.any((b) => b.locator == bookmark.locator)) return;
    book.bookmarks = [...book.bookmarks, bookmark]
      ..sort((a, b) => a.progress.compareTo(b.progress));
    await book.save();
    notifyListeners();
  }

  Future<void> removeBookmark(Book book, Bookmark bookmark) async {
    book.bookmarks =
        book.bookmarks.where((b) => b.locator != bookmark.locator).toList();
    await book.save();
    notifyListeners();
  }
}

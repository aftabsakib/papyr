import 'package:flutter_test/flutter_test.dart';
import 'package:papyr/models/book.dart';
import 'package:papyr/theme/library_options.dart';

Book _book({
  required String title,
  String? author,
  BookFormat format = BookFormat.pdf,
  double progress = 0.0,
  int? pageCount,
  DateTime? added,
  DateTime? opened,
  List<String>? collectionIds,
}) {
  return Book(
    id: title,
    title: title,
    author: author,
    format: format,
    fileName: '$title.pdf',
    pageCount: pageCount,
    progress: progress,
    addedAt: added ?? DateTime(2026, 1, 1),
    lastOpenedAt: opened,
    collectionIds: collectionIds,
  );
}

void main() {
  group('LibraryFilter.matches', () {
    final unread = _book(title: 'Unread');
    final reading = _book(title: 'Reading', progress: 0.4);
    final finished = _book(title: 'Finished', progress: 1.0);
    final epub = _book(title: 'Epub', format: BookFormat.epub, progress: 0.2);

    test('status filters', () {
      expect(LibraryFilter.unread.matches(unread), isTrue);
      expect(LibraryFilter.unread.matches(reading), isFalse);
      expect(LibraryFilter.reading.matches(reading), isTrue);
      expect(LibraryFilter.reading.matches(finished), isFalse);
      expect(LibraryFilter.finished.matches(finished), isTrue);
      expect(LibraryFilter.all.matches(finished), isTrue);
    });

    test('format filters', () {
      expect(LibraryFilter.pdf.matches(reading), isTrue);
      expect(LibraryFilter.pdf.matches(epub), isFalse);
      expect(LibraryFilter.epub.matches(epub), isTrue);
    });
  });

  group('LibraryQuery.apply', () {
    final books = [
      _book(title: 'Moby Dick', author: 'Herman Melville', progress: 0.5),
      _book(title: 'Dune', author: 'Frank Herbert', progress: 1.0),
      _book(title: 'Sapiens', author: 'Yuval Noah Harari'),
      _book(title: 'The Hobbit', author: 'Tolkien', format: BookFormat.epub),
    ];

    test('search matches title or author, case-insensitively', () {
      final byTitle = LibraryQuery.apply(books, search: 'dune');
      expect(byTitle.map((b) => b.title), ['Dune']);

      final byAuthor = LibraryQuery.apply(books, search: 'tolkien');
      expect(byAuthor.map((b) => b.title), ['The Hobbit']);

      expect(LibraryQuery.apply(books, search: 'zzz'), isEmpty);
    });

    test('filter narrows the set', () {
      final epubs = LibraryQuery.apply(books, filter: LibraryFilter.epub);
      expect(epubs.map((b) => b.title), ['The Hobbit']);

      final finished = LibraryQuery.apply(books, filter: LibraryFilter.finished);
      expect(finished.map((b) => b.title), ['Dune']);
    });

    test('collection scope keeps only member books, composes with filter', () {
      final shelf = [
        _book(title: 'A', progress: 1.0, collectionIds: ['sci-fi']),
        _book(title: 'B', progress: 0.3, collectionIds: ['sci-fi']),
        _book(title: 'C', collectionIds: ['history']),
        _book(title: 'D'), // in no collection
      ];
      final sciFi = LibraryQuery.apply(shelf, collectionId: 'sci-fi');
      expect(sciFi.map((b) => b.title).toSet(), {'A', 'B'});

      // Collection + status filter compose.
      final sciFiFinished = LibraryQuery.apply(shelf,
          collectionId: 'sci-fi', filter: LibraryFilter.finished);
      expect(sciFiFinished.map((b) => b.title), ['A']);

      // A book can be in more than one collection.
      final multi = _book(title: 'X', collectionIds: ['sci-fi', 'history']);
      expect(LibraryQuery.apply([multi], collectionId: 'sci-fi'), hasLength(1));
      expect(LibraryQuery.apply([multi], collectionId: 'history'), hasLength(1));
    });

    test('sort by title is alphabetical', () {
      final sorted = LibraryQuery.apply(books, sort: LibrarySort.title);
      expect(sorted.map((b) => b.title),
          ['Dune', 'Moby Dick', 'Sapiens', 'The Hobbit']);
    });

    test('sort by progress is descending', () {
      final sorted = LibraryQuery.apply(books, sort: LibrarySort.progress);
      expect(sorted.first.title, 'Dune'); // 1.0
      expect(sorted.last.progress, 0.0);
    });

    test('sort by recent uses last-opened then added', () {
      final list = [
        _book(title: 'A', added: DateTime(2026, 1, 1)),
        _book(title: 'B', added: DateTime(2026, 1, 2), opened: DateTime(2026, 6, 1)),
        _book(title: 'C', added: DateTime(2026, 5, 1)),
      ];
      final sorted = LibraryQuery.apply(list, sort: LibrarySort.recent);
      expect(sorted.first.title, 'B'); // most recently opened
    });
  });

  group('LibraryStats.from', () {
    test('counts statuses, formats, and pages read', () {
      final stats = LibraryStats.from([
        _book(title: 'A', progress: 0.0),
        _book(title: 'B', progress: 0.5, pageCount: 200),
        _book(title: 'C', progress: 1.0, pageCount: 100),
        _book(title: 'D', format: BookFormat.epub, progress: 0.3),
      ]);
      expect(stats.total, 4);
      expect(stats.unread, 1);
      expect(stats.reading, 2);
      expect(stats.finished, 1);
      expect(stats.pdfs, 3);
      expect(stats.epubs, 1);
      // B: 200*0.5=100, C: 100*1.0=100 -> 200. EPUB D contributes nothing.
      expect(stats.pagesRead, 200);
    });
  });
}

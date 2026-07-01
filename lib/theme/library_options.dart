import '../models/book.dart';

/// How the library shelf is ordered.
enum LibrarySort {
  recent,
  title,
  author,
  added,
  progress;

  String get label => switch (this) {
        LibrarySort.recent => 'Recently read',
        LibrarySort.title => 'Title',
        LibrarySort.author => 'Author',
        LibrarySort.added => 'Date added',
        LibrarySort.progress => 'Progress',
      };
}

/// A single-choice library filter: by reading status or by format.
enum LibraryFilter {
  all,
  reading,
  finished,
  unread,
  pdf,
  epub;

  String get label => switch (this) {
        LibraryFilter.all => 'All',
        LibraryFilter.reading => 'Reading',
        LibraryFilter.finished => 'Finished',
        LibraryFilter.unread => 'Unread',
        LibraryFilter.pdf => 'PDF',
        LibraryFilter.epub => 'EPUB',
      };

  bool matches(Book b) => switch (this) {
        LibraryFilter.all => true,
        LibraryFilter.reading => b.hasStarted && !b.isFinished,
        LibraryFilter.finished => b.isFinished,
        LibraryFilter.unread => !b.hasStarted,
        LibraryFilter.pdf => b.format == BookFormat.pdf,
        LibraryFilter.epub => b.format == BookFormat.epub,
      };
}

/// Applies the user's search text, filter, and sort to the library in one place
/// so the screen stays declarative and the logic stays unit-testable.
class LibraryQuery {
  const LibraryQuery._();

  static List<Book> apply(
    List<Book> books, {
    String search = '',
    LibraryFilter filter = LibraryFilter.all,
    LibrarySort sort = LibrarySort.recent,
  }) {
    final q = search.trim().toLowerCase();
    final list = books.where((b) {
      if (!filter.matches(b)) return false;
      if (q.isEmpty) return true;
      final title = b.title.toLowerCase();
      final author = (b.author ?? '').toLowerCase();
      return title.contains(q) || author.contains(q);
    }).toList();
    list.sort(comparator(sort));
    return list;
  }

  /// The comparator for a given sort. Exposed for testing.
  static int Function(Book, Book) comparator(LibrarySort sort) =>
      switch (sort) {
        LibrarySort.recent => (a, b) => _recency(b).compareTo(_recency(a)),
        LibrarySort.title => (a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        LibrarySort.author => (a, b) =>
            (a.author ?? '').toLowerCase().compareTo((b.author ?? '').toLowerCase()),
        LibrarySort.added => (a, b) => b.addedAt.compareTo(a.addedAt),
        LibrarySort.progress => (a, b) => b.progress.compareTo(a.progress),
      };

  static DateTime _recency(Book b) => b.lastOpenedAt ?? b.addedAt;
}

/// A compact summary of the whole library, shown in the stats sheet.
class LibraryStats {
  const LibraryStats({
    required this.total,
    required this.reading,
    required this.finished,
    required this.unread,
    required this.pdfs,
    required this.epubs,
    required this.pagesRead,
  });

  final int total;
  final int reading;
  final int finished;
  final int unread;
  final int pdfs;
  final int epubs;

  /// Estimated pages read across PDFs (pageCount × progress). EPUBs are
  /// reflowable with no fixed page count, so they don't contribute here.
  final int pagesRead;

  factory LibraryStats.from(List<Book> books) {
    var reading = 0, finished = 0, unread = 0, pdfs = 0, epubs = 0;
    var pagesRead = 0;
    for (final b in books) {
      if (b.isFinished) {
        finished++;
      } else if (b.hasStarted) {
        reading++;
      } else {
        unread++;
      }
      if (b.format == BookFormat.pdf) {
        pdfs++;
        final pages = b.pageCount;
        if (pages != null) {
          pagesRead += (pages * b.progress.clamp(0.0, 1.0)).round();
        }
      } else {
        epubs++;
      }
    }
    return LibraryStats(
      total: books.length,
      reading: reading,
      finished: finished,
      unread: unread,
      pdfs: pdfs,
      epubs: epubs,
      pagesRead: pagesRead,
    );
  }
}

import 'package:hive/hive.dart';

part 'book.g.dart';

/// The two formats Papyr can read.
@HiveType(typeId: 1)
enum BookFormat {
  @HiveField(0)
  pdf,
  @HiveField(1)
  epub;

  String get label => this == BookFormat.pdf ? 'PDF' : 'EPUB';
}

/// A saved reading position the user can jump back to.
@HiveType(typeId: 2)
class Bookmark {
  Bookmark({
    required this.locator,
    required this.label,
    required this.progress,
    required this.createdAt,
  });

  /// Where the bookmark points: a page number (PDF) or an EPUB CFI.
  @HiveField(0)
  final String locator;

  /// Human-readable label, e.g. "Page 42" or a progress percent.
  @HiveField(1)
  final String label;

  /// Progress fraction at the bookmark, for ordering and display.
  @HiveField(2)
  final double progress;

  @HiveField(3)
  final DateTime createdAt;
}

/// One book in the user's library.
///
/// The actual book file and cover image live in the app's documents directory;
/// only their *file names* are stored here so the records stay portable if the
/// sandbox path changes between app launches (notably on iOS).
@HiveType(typeId: 0)
class Book extends HiveObject {
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.fileName,
    this.coverFileName,
    this.pageCount,
    this.progress = 0.0,
    this.locator,
    required this.addedAt,
    this.lastOpenedAt,
    List<Bookmark>? bookmarks,
    this.contentHash,
    List<String>? collectionIds,
  })  : bookmarks = bookmarks ?? <Bookmark>[],
        collectionIds = collectionIds ?? <String>[];

  /// Stable unique id (uuid v4). Also used to name the cover file.
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? author;

  @HiveField(3)
  final BookFormat format;

  /// File name of the book inside `<docs>/books/`.
  @HiveField(4)
  final String fileName;

  /// File name of the cover inside `<docs>/covers/`, if one was extracted.
  @HiveField(5)
  String? coverFileName;

  /// Total pages — known for PDFs, null for EPUB (reflowable).
  @HiveField(6)
  int? pageCount;

  /// Reading progress 0.0–1.0 for the library progress bar.
  @HiveField(7)
  double progress;

  /// Last reading position: a page index (PDF) or an EPUB CFI/locator string.
  @HiveField(8)
  String? locator;

  @HiveField(9)
  final DateTime addedAt;

  @HiveField(10)
  DateTime? lastOpenedAt;

  @HiveField(11, defaultValue: <Bookmark>[])
  List<Bookmark> bookmarks;

  /// SHA-1 of the source file, used to detect duplicate imports.
  @HiveField(12)
  String? contentHash;

  /// Ids of the collections this book belongs to. A book can be in many
  /// collections at once (tag-style membership).
  @HiveField(13, defaultValue: <String>[])
  List<String> collectionIds;

  bool get hasStarted => progress > 0.0;
  bool get isFinished => progress >= 0.999;

  /// Whole-number percent for display (e.g. "37%").
  int get progressPercent => (progress.clamp(0.0, 1.0) * 100).round();
}

/// A user-defined collection (a named shelf). Books reference collections by
/// [id]; a book can belong to any number of them.
@HiveType(typeId: 3)
class Collection extends HiveObject {
  Collection({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime createdAt;
}

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
  });

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

  bool get hasStarted => progress > 0.0;
  bool get isFinished => progress >= 0.999;

  /// Whole-number percent for display (e.g. "37%").
  int get progressPercent => (progress.clamp(0.0, 1.0) * 100).round();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:papyr/models/book.dart';

Book makeBook({double progress = 0.0}) => Book(
      id: 'id',
      title: 'Title',
      author: 'Author',
      format: BookFormat.pdf,
      fileName: 'id.pdf',
      addedAt: DateTime(2026, 1, 1),
      progress: progress,
    );

void main() {
  group('Book progress', () {
    test('not started', () {
      final b = makeBook(progress: 0);
      expect(b.hasStarted, isFalse);
      expect(b.isFinished, isFalse);
      expect(b.progressPercent, 0);
    });

    test('partway through', () {
      final b = makeBook(progress: 0.37);
      expect(b.hasStarted, isTrue);
      expect(b.isFinished, isFalse);
      expect(b.progressPercent, 37);
    });

    test('finished', () {
      final b = makeBook(progress: 1.0);
      expect(b.isFinished, isTrue);
      expect(b.progressPercent, 100);
    });

    test('bookmarks default to empty and are mutable', () {
      final b = makeBook();
      expect(b.bookmarks, isEmpty);
      b.bookmarks = [
        Bookmark(locator: '1', label: 'Page 1', progress: 0.1, createdAt: DateTime(2026)),
      ];
      expect(b.bookmarks, hasLength(1));
    });

    test('BookFormat labels', () {
      expect(BookFormat.pdf.label, 'PDF');
      expect(BookFormat.epub.label, 'EPUB');
    });
  });
}

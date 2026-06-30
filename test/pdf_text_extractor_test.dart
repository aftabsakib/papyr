import 'package:flutter_test/flutter_test.dart';
import 'package:papyr/services/pdf_text_extractor.dart';

void main() {
  group('PdfTextExtractor.isPageNumber', () {
    test('bare numbers are page numbers', () {
      expect(PdfTextExtractor.isPageNumber('12'), isTrue);
      expect(PdfTextExtractor.isPageNumber('  3  '), isTrue);
      expect(PdfTextExtractor.isPageNumber('- 7 -'), isTrue);
      expect(PdfTextExtractor.isPageNumber('Page 42'), isTrue);
    });

    test('real text is not a page number', () {
      expect(PdfTextExtractor.isPageNumber('Chapter 1'), isFalse);
      expect(PdfTextExtractor.isPageNumber('The year 1984'), isFalse);
      expect(PdfTextExtractor.isPageNumber('Reading'), isFalse);
    });
  });

  group('PdfTextExtractor.normalizeHeader', () {
    test('strips digits and case so running headers match across pages', () {
      expect(PdfTextExtractor.normalizeHeader('A History of Reading  12'),
          PdfTextExtractor.normalizeHeader('A History of Reading  13'));
      expect(PdfTextExtractor.normalizeHeader('CHAPTER 3'), 'chapter');
    });
  });

  group('ReflowBlock encode/decode', () {
    test('round-trips a heading', () {
      final b = ReflowBlock(ReflowBlockType.heading, 'Chapter One');
      final back = ReflowBlock.decode(b.encode());
      expect(back, isNotNull);
      expect(back!.type, ReflowBlockType.heading);
      expect(back.text, 'Chapter One');
    });

    test('round-trips a paragraph', () {
      final b = ReflowBlock(ReflowBlockType.paragraph, 'Some body text.');
      final back = ReflowBlock.decode(b.encode());
      expect(back!.type, ReflowBlockType.paragraph);
      expect(back.text, 'Some body text.');
    });

    test('cache header gates stale caches', () {
      final encoded = PdfTextExtractor.encodeCache([
        ReflowBlock(ReflowBlockType.heading, 'Title'),
        ReflowBlock(ReflowBlockType.paragraph, 'Body'),
      ]);
      final decoded = PdfTextExtractor.decodeCache(encoded);
      expect(decoded, hasLength(2));
      expect(decoded!.first.isHeading, isTrue);
      // Old plain-text cache (no version header) is rejected.
      expect(PdfTextExtractor.decodeCache('just some\nold lines'), isNull);
    });
  });
}

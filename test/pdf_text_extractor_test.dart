import 'package:flutter_test/flutter_test.dart';
import 'package:papyr/services/pdf_text_extractor.dart';

void main() {
  group('PdfTextExtractor.toParagraphs', () {
    test('folds single line breaks within a paragraph into spaces', () {
      final result = PdfTextExtractor.toParagraphs([
        'Reading should feel\ncalm and unhurried.',
      ]);
      expect(result, ['Reading should feel calm and unhurried.']);
    });

    test('splits paragraphs on blank lines', () {
      final result = PdfTextExtractor.toParagraphs([
        'First paragraph.\n\nSecond paragraph.',
      ]);
      expect(result, ['First paragraph.', 'Second paragraph.']);
    });

    test('joins hyphenated words across line breaks', () {
      final result = PdfTextExtractor.toParagraphs(['exam-\nple text']);
      expect(result.single, 'example text');
    });

    test('treats each page as its own paragraph break', () {
      final result = PdfTextExtractor.toParagraphs(['Page one.', 'Page two.']);
      expect(result, ['Page one.', 'Page two.']);
    });

    test('collapses runs of whitespace and drops empty blocks', () {
      final result = PdfTextExtractor.toParagraphs(['a    b\n\n   \n\nc']);
      expect(result, ['a b', 'c']);
    });

    test('returns empty list for empty input', () {
      expect(PdfTextExtractor.toParagraphs([]), isEmpty);
    });
  });
}

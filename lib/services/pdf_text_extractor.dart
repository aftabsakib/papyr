import 'package:pdfrx/pdfrx.dart';

/// Extracts a PDF's text layer and cleans it into reflowable paragraphs for the
/// Reading view. Returns an empty list for scanned PDFs that have no text layer.
class PdfTextExtractor {
  PdfTextExtractor._();

  /// Pulls text from every page and groups it into paragraphs.
  static Future<List<String>> extractParagraphs(String path) async {
    await pdfrxFlutterInitialize();
    final doc = await PdfDocument.openFile(path);
    try {
      final pages = <String>[];
      for (final page in doc.pages) {
        final raw = await page.loadText();
        final text = raw?.fullText.trim() ?? '';
        if (text.isNotEmpty) pages.add(text);
      }
      return _toParagraphs(pages);
    } finally {
      await doc.dispose();
    }
  }

  /// Cleans raw page text into paragraphs:
  /// - joins hyphenated line breaks (`exam-\nple` -> `example`)
  /// - treats blank lines as paragraph breaks
  /// - joins remaining single line breaks into spaces
  /// - keeps page boundaries as paragraph breaks
  static List<String> _toParagraphs(List<String> pages) {
    final paragraphs = <String>[];
    for (final page in pages) {
      final normalized = page.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      // Split on blank lines into candidate paragraphs.
      for (final block in normalized.split(RegExp(r'\n[ \t]*\n'))) {
        // De-hyphenate across line breaks, then fold single breaks to spaces.
        final joined = block
            .replaceAll(RegExp(r'-\n'), '')
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'[ \t]+'), ' ')
            .trim();
        if (joined.isNotEmpty) paragraphs.add(joined);
      }
    }
    return paragraphs;
  }
}

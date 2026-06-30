import 'package:pdfrx/pdfrx.dart';

import 'pdf_ocr.dart';

/// A reflowable block of a PDF: either a heading or a body paragraph.
enum ReflowBlockType { heading, paragraph }

class ReflowBlock {
  const ReflowBlock(this.type, this.text);
  final ReflowBlockType type;
  final String text;

  bool get isHeading => type == ReflowBlockType.heading;

  /// Serialised cache form: a one-char type tag, a tab, then the text.
  String encode() => '${isHeading ? 'H' : 'P'}\t$text';

  static ReflowBlock? decode(String line) {
    final tab = line.indexOf('\t');
    if (tab < 1) return null;
    final type = line[0] == 'H' ? ReflowBlockType.heading : ReflowBlockType.paragraph;
    final text = line.substring(tab + 1).trim();
    return text.isEmpty ? null : ReflowBlock(type, text);
  }
}

/// One visual line of text on a page, assembled from positioned fragments.
class _Line {
  _Line(this.text, this.left, this.right, this.top, this.bottom);
  final String text;
  final double left;
  final double right;
  final double top; // higher y = higher on page (PDF origin is bottom-left)
  final double bottom;

  double get height => top - bottom;
  double get centerX => (left + right) / 2;
}

/// Extracts a PDF's text layer into structured reflow blocks: detects headings
/// by font size, reorders two-column layouts, strips running headers/footers and
/// page numbers, and rebuilds paragraphs from line geometry.
class PdfTextExtractor {
  PdfTextExtractor._();

  static const _cacheHeader = 'PAPYR_REFLOW_V2';

  /// Encodes blocks for the on-disk reflow cache.
  static String encodeCache(List<ReflowBlock> blocks) =>
      '$_cacheHeader\n${blocks.map((b) => b.encode()).join('\n')}';

  /// Decodes the cache; returns null if it's missing/stale (wrong version).
  static List<ReflowBlock>? decodeCache(String raw) {
    final lines = raw.split('\n');
    if (lines.isEmpty || lines.first != _cacheHeader) return null;
    final blocks = <ReflowBlock>[];
    for (final line in lines.skip(1)) {
      final b = ReflowBlock.decode(line);
      if (b != null) blocks.add(b);
    }
    return blocks;
  }

  /// Reads every page's structured text and produces reflow blocks.
  ///
  /// [onProgress] reports 0.0–1.0; the loop yields between pages so the UI stays
  /// responsive on large PDFs.
  ///
  /// When [useOcr] is true, any page with no embedded text layer is rendered
  /// and read with on-device OCR (for scanned PDFs). OCR is slow, so it's
  /// opt-in — callers run a fast text-only pass first and only enable OCR once
  /// they know the PDF is scanned.
  static Future<List<ReflowBlock>> extractBlocks(
    String path, {
    bool useOcr = false,
    void Function(double progress)? onProgress,
  }) async {
    await pdfrxFlutterInitialize();
    final doc = await PdfDocument.openFile(path);
    final ocr = useOcr ? PdfOcr() : null;
    try {
      final total = doc.pages.length;
      final pageLines = <List<_Line>>[];
      final pageHeights = <double>[];
      final pageWidths = <double>[];
      final bodyHeights = <double>[];
      final marginCounts = <String, int>{};

      // Pass 1: assemble lines, learn the body font size and running margins.
      for (var i = 0; i < total; i++) {
        final page = doc.pages[i];
        final st = await page.loadStructuredText();
        var lines = _buildLines(st.fragments);
        if (lines.isEmpty && ocr != null) {
          // Scanned page — recover its text with OCR.
          lines = (await ocr.recognizePage(page))
              .map((o) => _Line(o.text, o.left, o.right, o.top, o.bottom))
              .toList();
        }
        pageLines.add(lines);
        pageHeights.add(page.height);
        pageWidths.add(page.width);
        for (final l in lines) {
          if (_inMargin(l, page.height)) {
            final key = _normHeader(l.text);
            if (key.isNotEmpty) marginCounts[key] = (marginCounts[key] ?? 0) + 1;
          } else {
            bodyHeights.add(l.height);
          }
        }
        onProgress?.call((i + 1) / total * 0.7);
        await Future<void>.delayed(Duration.zero);
      }

      final body = _median(bodyHeights);
      // A running header must repeat across pages, so it needs >=2 occurrences.
      // For a 1-page doc nothing can "run", so set the bar out of reach.
      final runningThreshold =
          total < 2 ? total + 1 : (total * 0.4).ceil().clamp(2, total);
      final running = marginCounts.entries
          .where((e) => e.value >= runningThreshold)
          .map((e) => e.key)
          .toSet();

      // Pass 2: order columns, strip chrome, group into blocks.
      final blocks = <ReflowBlock>[];
      final para = StringBuffer();

      void flush() {
        final t = _clean(para.toString());
        if (t.isNotEmpty) blocks.add(ReflowBlock(ReflowBlockType.paragraph, t));
        para.clear();
      }

      for (var i = 0; i < total; i++) {
        final h = pageHeights[i];
        final w = pageWidths[i];
        final content = pageLines[i].where((l) {
          if (!_inMargin(l, h)) return true;
          if (running.contains(_normHeader(l.text))) return false;
          if (_isPageNumber(l.text)) return false;
          return true;
        }).toList();

        final ordered = _orderColumns(content, w);

        _Line? prev;
        for (final l in ordered) {
          if (l.height >= body * 1.35 && l.text.trim().length < 120) {
            flush();
            blocks.add(ReflowBlock(ReflowBlockType.heading, l.text.trim()));
            prev = l;
            continue;
          }
          if (prev != null) {
            final gap = prev.bottom - l.top; // space between lines
            final indent = l.left - prev.left;
            if (gap > body * 0.9 || indent > body * 1.2) flush();
          }
          _appendLine(para, l.text);
          prev = l;
        }
        // Let paragraphs continue across page breaks (don't flush here).
        onProgress?.call(0.7 + (i + 1) / total * 0.3);
        await Future<void>.delayed(Duration.zero);
      }
      flush();
      return blocks;
    } finally {
      await ocr?.dispose();
      await doc.dispose();
    }
  }

  // ---- Line assembly -----------------------------------------------------
  static List<_Line> _buildLines(List<PdfPageTextFragment> frags) {
    if (frags.isEmpty) return const [];
    final sorted = [...frags]..sort((a, b) {
        final dt = b.bounds.top.compareTo(a.bounds.top);
        return dt != 0 ? dt : a.bounds.left.compareTo(b.bounds.left);
      });

    final lines = <_Line>[];
    var group = <PdfPageTextFragment>[sorted.first];
    var refTop = sorted.first.bounds.top;
    var refHeight = sorted.first.bounds.height;

    for (var k = 1; k < sorted.length; k++) {
      final f = sorted[k];
      final tol = (refHeight * 0.6).clamp(2.0, 60.0);
      if ((refTop - f.bounds.top).abs() < tol) {
        group.add(f);
      } else {
        lines.add(_assembleLine(group));
        group = [f];
        refTop = f.bounds.top;
        refHeight = f.bounds.height;
      }
    }
    lines.add(_assembleLine(group));
    return lines;
  }

  static _Line _assembleLine(List<PdfPageTextFragment> group) {
    group.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
    final sb = StringBuffer();
    double left = group.first.bounds.left;
    double right = group.first.bounds.right;
    double top = group.first.bounds.top;
    double bottom = group.first.bounds.bottom;
    double? prevRight;
    double height = group.first.bounds.height;

    for (final f in group) {
      final b = f.bounds;
      if (prevRight != null && (b.left - prevRight) > height * 0.25) {
        sb.write(' ');
      }
      sb.write(f.text);
      prevRight = b.right;
      left = left < b.left ? left : b.left;
      right = right > b.right ? right : b.right;
      top = top > b.top ? top : b.top;
      bottom = bottom < b.bottom ? bottom : b.bottom;
      height = height > b.height ? height : b.height;
    }
    return _Line(sb.toString(), left, right, top, bottom);
  }

  // ---- Column ordering ---------------------------------------------------
  static List<_Line> _orderColumns(List<_Line> lines, double pageWidth) {
    if (lines.length < 6) return lines;
    final mid = pageWidth / 2;
    final slack = pageWidth * 0.05;
    final left = <_Line>[];
    final right = <_Line>[];
    var full = 0;
    for (final l in lines) {
      if (l.right < mid + slack) {
        left.add(l);
      } else if (l.left > mid - slack) {
        right.add(l);
      } else {
        full++;
      }
    }
    final twoColumn = left.length >= 3 &&
        right.length >= 3 &&
        full <= (lines.length * 0.2).ceil();
    return twoColumn ? [...left, ...right] : lines;
  }

  // ---- Helpers -----------------------------------------------------------
  static bool _inMargin(_Line l, double pageHeight) {
    final cy = (l.top + l.bottom) / 2;
    return cy > pageHeight * 0.93 || cy < pageHeight * 0.07;
  }

  static bool _isPageNumber(String text) {
    final t = text.trim();
    return RegExp(r'^[^\w]*\d{1,4}[^\w]*$').hasMatch(t) ||
        RegExp(r'^(page|p\.?)\s*\d{1,4}$', caseSensitive: false).hasMatch(t);
  }

  /// Normalises a margin line for running-header detection: page numbers change
  /// per page, so strip digits and collapse whitespace.
  static String _normHeader(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'\d+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static void _appendLine(StringBuffer para, String lineText) {
    final text = lineText.trim();
    if (text.isEmpty) return;
    final current = para.toString();
    if (current.isEmpty) {
      para.write(text);
    } else if (current.endsWith('-')) {
      // De-hyphenate across the line break.
      para.clear();
      para.write(current.substring(0, current.length - 1));
      para.write(text);
    } else {
      para.write(' ');
      para.write(text);
    }
  }

  static String _clean(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static double _median(List<double> values) {
    if (values.isEmpty) return 10;
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Public for unit testing: true when a margin line is just a page number.
  static bool isPageNumber(String text) => _isPageNumber(text);

  /// Public for unit testing: header normalisation used for running detection.
  static String normalizeHeader(String text) => _normHeader(text);
}

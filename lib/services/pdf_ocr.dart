import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// One OCR-recognised line, expressed in PDF-point space (origin bottom-left,
/// higher y = higher on the page) so it slots straight into the reflow
/// pipeline alongside lines read from a real text layer.
class OcrLine {
  OcrLine(this.text, this.left, this.right, this.top, this.bottom);
  final String text;
  final double left;
  final double right;
  final double top;
  final double bottom;
}

/// On-device OCR for scanned PDFs (pages with no embedded text layer).
///
/// Renders each page to a bitmap and runs Google ML Kit text recognition.
/// Everything happens locally — no page ever leaves the device. Reuse one
/// instance across a document and [dispose] it when finished.
class PdfOcr {
  PdfOcr() : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  /// Render resolution. ~200 DPI gives ML Kit enough detail to read body text
  /// without ballooning memory or time on large pages.
  static const _dpi = 200.0;

  /// OCRs a single page and returns its lines in PDF-point coordinates.
  Future<List<OcrLine>> recognizePage(PdfPage page) async {
    final scale = _dpi / 72.0;
    final pxToPt = 1.0 / scale;
    final img = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: 0xFFFFFFFF, // white paper behind the scan
    );
    if (img == null) return const [];

    String? pngPath;
    try {
      final pngBytes = await _toPng(img);
      if (pngBytes == null) return const [];
      pngPath = await _writeTemp(pngBytes, img.width, img.height);

      final result =
          await _recognizer.processImage(InputImage.fromFilePath(pngPath));

      final lines = <OcrLine>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isEmpty) continue;
          final r = line.boundingBox; // image pixels, origin top-left
          lines.add(OcrLine(
            text,
            r.left * pxToPt,
            r.right * pxToPt,
            page.height - r.top * pxToPt, // flip Y into PDF space
            page.height - r.bottom * pxToPt,
          ));
        }
      }
      // Top-to-bottom; the reflow pipeline reorders columns from here.
      lines.sort((a, b) => b.top.compareTo(a.top));
      return lines;
    } finally {
      img.dispose();
      if (pngPath != null) {
        try {
          await File(pngPath).delete();
        } catch (_) {
          // Best-effort cleanup of the scratch bitmap.
        }
      }
    }
  }

  /// Encodes a rendered [PdfImage] (BGRA) to PNG bytes for ML Kit, which reads
  /// most reliably from a file on disk.
  Future<Uint8List?> _toPng(PdfImage img) async {
    final ui.Image image = await img.createImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<String> _writeTemp(Uint8List png, int w, int h) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'papyr_ocr_${w}x$h.png'));
    await file.writeAsBytes(png, flush: true);
    return file.path;
  }

  Future<void> dispose() => _recognizer.close();
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import 'library_store.dart';

/// Imports PDF and EPUB files into the library: copies the file into the app's
/// books directory, extracts a title/author and cover, and creates the [Book]
/// record. Cover/metadata failures never block an import — the book still lands
/// in the library, just without a cover.
class BookImporter {
  BookImporter(this._store);

  final LibraryStore _store;
  static const _uuid = Uuid();
  static const _coverTargetWidth = 360;

  /// Opens the system file picker and imports everything the user selects.
  /// Returns the books that were added (empty if the user cancelled).
  Future<List<Book>> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
      allowMultiple: true,
    );
    if (result == null) return const [];

    final added = <Book>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      try {
        final book = await _importFile(path, file.name);
        await _store.add(book);
        added.add(book);
      } catch (_) {
        // Skip a file that fails to import rather than aborting the batch.
      }
    }
    return added;
  }

  Future<Book> _importFile(String srcPath, String displayName) async {
    final ext = p.extension(srcPath).toLowerCase();
    final format = ext == '.pdf' ? BookFormat.pdf : BookFormat.epub;
    final id = _uuid.v4();
    final storedName = '$id$ext';

    // Copy the file into the app's library so it's always available.
    final dest = File(p.join(_store.booksDir.path, storedName));
    await File(srcPath).copy(dest.path);

    final fallbackTitle = _titleFromFileName(displayName);
    return format == BookFormat.pdf
        ? await _buildPdf(id, storedName, dest, fallbackTitle)
        : await _buildEpub(id, storedName, dest, fallbackTitle);
  }

  // ---- PDF ---------------------------------------------------------------
  Future<Book> _buildPdf(
      String id, String storedName, File file, String fallbackTitle) async {
    await pdfrxFlutterInitialize();
    int? pageCount;
    String? coverName;

    final doc = await PdfDocument.openFile(file.path);
    try {
      pageCount = doc.pages.length;
      coverName = await _renderPdfCover(doc.pages.first, id);
    } catch (_) {
      // No cover — fine.
    } finally {
      await doc.dispose();
    }

    return Book(
      id: id,
      title: fallbackTitle,
      author: null,
      format: BookFormat.pdf,
      fileName: storedName,
      coverFileName: coverName,
      pageCount: pageCount,
      addedAt: DateTime.now(),
    );
  }

  Future<String?> _renderPdfCover(PdfPage page, String id) async {
    final scale = _coverTargetWidth / page.width;
    final image = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
    );
    if (image == null) return null;
    try {
      // pdfrx returns BGRA8888 — decode with the matching pixel format.
      final pngBytes = await _bgraToPng(image.pixels, image.width, image.height);
      final coverName = '$id.png';
      await File(p.join(_store.coversDir.path, coverName)).writeAsBytes(pngBytes);
      return coverName;
    } finally {
      image.dispose();
    }
  }

  Future<Uint8List> _bgraToPng(Uint8List bgra, int width, int height) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bgra,
      width,
      height,
      ui.PixelFormat.bgra8888,
      completer.complete,
    );
    final uiImage = await completer.future;
    try {
      final data = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      uiImage.dispose();
    }
  }

  // ---- EPUB --------------------------------------------------------------
  Future<Book> _buildEpub(
      String id, String storedName, File file, String fallbackTitle) async {
    String title = fallbackTitle;
    String? author;
    String? coverName;

    try {
      final bytes = await file.readAsBytes();
      final epub = await EpubReader.readBook(bytes);
      final t = epub.Title?.trim();
      if (t != null && t.isNotEmpty) title = t;
      final a = epub.Author?.trim();
      if (a != null && a.isNotEmpty) author = a;

      final cover = epub.CoverImage;
      if (cover != null) {
        final png = Uint8List.fromList(img.encodePng(cover));
        coverName = '$id.png';
        await File(p.join(_store.coversDir.path, coverName)).writeAsBytes(png);
      }
    } catch (_) {
      // Metadata/cover extraction failed — keep the fallback title.
    }

    return Book(
      id: id,
      title: title,
      author: author,
      format: BookFormat.epub,
      fileName: storedName,
      coverFileName: coverName,
      addedAt: DateTime.now(),
    );
  }

  String _titleFromFileName(String name) {
    var base = p.basenameWithoutExtension(name).trim();
    base = base.replaceAll(RegExp(r'[._]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    return base.isEmpty ? 'Untitled' : base;
  }
}

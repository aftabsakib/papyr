import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

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
  // An EPUB is a ZIP. We read the OPF package document for the title/author and
  // locate the cover image, copying its bytes straight out — no image re-encode,
  // so there's no dependency on a specific `image` package version.
  Future<Book> _buildEpub(
      String id, String storedName, File file, String fallbackTitle) async {
    String title = fallbackTitle;
    String? author;
    String? coverName;

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final opfPath = _findOpfPath(archive);
      if (opfPath != null) {
        final opfFile = archive.findFile(opfPath);
        if (opfFile != null) {
          final opf = XmlDocument.parse(utf8.decode(opfFile.content));

          title = _firstText(opf, 'title') ?? fallbackTitle;
          author = _firstText(opf, 'creator');

          final coverHref = _findCoverHref(opf);
          if (coverHref != null) {
            // Cover href is relative to the OPF's directory (posix paths).
            final opfDir = p.posix.dirname(opfPath);
            final coverPath =
                p.posix.normalize(p.posix.join(opfDir, coverHref));
            final coverFile = archive.findFile(coverPath);
            if (coverFile != null) {
              final ext = p.extension(coverHref).toLowerCase();
              coverName = '$id${ext.isEmpty ? '.img' : ext}';
              await File(p.join(_store.coversDir.path, coverName))
                  .writeAsBytes(coverFile.content);
            }
          }
        }
      }
    } catch (_) {
      // Malformed EPUB — keep the filename-derived title.
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

  /// Reads META-INF/container.xml to find the OPF package document path.
  String? _findOpfPath(Archive archive) {
    final container = archive.findFile('META-INF/container.xml');
    if (container == null) return null;
    final doc = XmlDocument.parse(utf8.decode(container.content));
    final rootfile = doc.findAllElements('rootfile', namespace: '*').firstOrNull;
    return rootfile?.getAttribute('full-path');
  }

  /// First text value of a Dublin Core element (e.g. dc:title, dc:creator).
  String? _firstText(XmlDocument opf, String localName) {
    final el = opf.findAllElements(localName, namespace: '*').firstOrNull;
    final text = el?.innerText.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Locates the cover image href, supporting EPUB3 (properties="cover-image")
  /// and EPUB2 (<meta name="cover" content="itemId">).
  String? _findCoverHref(XmlDocument opf) {
    final items = opf.findAllElements('item', namespace: '*').toList();

    // EPUB3: manifest item flagged as the cover image.
    for (final item in items) {
      final props = item.getAttribute('properties') ?? '';
      if (props.split(RegExp(r'\s+')).contains('cover-image')) {
        return item.getAttribute('href');
      }
    }

    // EPUB2: a <meta name="cover" content="..."> points at a manifest item id.
    final coverMeta = opf
        .findAllElements('meta', namespace: '*')
        .where((m) => m.getAttribute('name') == 'cover')
        .firstOrNull;
    final coverId = coverMeta?.getAttribute('content');
    if (coverId != null) {
      for (final item in items) {
        if (item.getAttribute('id') == coverId) {
          return item.getAttribute('href');
        }
      }
    }
    return null;
  }

  String _titleFromFileName(String name) {
    var base = p.basenameWithoutExtension(name).trim();
    base = base.replaceAll(RegExp(r'[._]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    return base.isEmpty ? 'Untitled' : base;
  }
}

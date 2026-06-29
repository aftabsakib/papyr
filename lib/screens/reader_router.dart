import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import 'epub_reader_screen.dart';
import 'pdf_reader_screen.dart';

/// Opens the correct reader for a book and records that it was opened.
class ReaderRouter {
  static Future<void> open(
    BuildContext context, {
    required Book book,
    required LibraryStore library,
    required SettingsStore settings,
    required ThemeController themeController,
  }) async {
    await library.markOpened(book);
    if (!context.mounted) return;

    final Widget screen = switch (book.format) {
      BookFormat.pdf => PdfReaderScreen(
          book: book,
          library: library,
          settings: settings,
          themeController: themeController,
        ),
      BookFormat.epub => EpubReaderScreen(
          book: book,
          library: library,
          settings: settings,
          themeController: themeController,
        ),
    };

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
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
    // The book file can go missing if storage was cleared or the file was
    // removed outside the app. Handle it instead of opening a broken reader.
    if (!await library.bookFile(book).exists()) {
      if (!context.mounted) return;
      await _handleMissingFile(context, book, library, themeController);
      return;
    }

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

  static Future<void> _handleMissingFile(
    BuildContext context,
    Book book,
    LibraryStore library,
    ThemeController themeController,
  ) async {
    final p = themeController.palette;
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('File missing',
            style: PapyrTheme.title(p.inkPrimary, size: 18)),
        content: Text(
          '"${book.title}" can no longer be found on this device. '
          'Remove it from your library?',
          style: PapyrTheme.reading(p.inkSecondary, size: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: PapyrTheme.ui(p.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: PapyrTheme.ui(const Color(0xFFB3261E), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (remove == true) await library.delete(book);
  }
}

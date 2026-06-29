import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/book_importer.dart';
import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import '../widgets/book_grid_tile.dart';
import '../widgets/paper_picker_sheet.dart';
import 'reader_router.dart';
import 'settings_screen.dart';

/// The library — Papyr's home. Shows the shelf of imported books, handles
/// importing, and lets the reader switch papers.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.themeController,
    required this.settings,
    required this.library,
  });

  final ThemeController themeController;
  final SettingsStore settings;
  final LibraryStore library;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final BookImporter _importer = BookImporter(widget.library);
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.themeController.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papyr'),
        actions: [
          IconButton(
            tooltip: 'Paper',
            icon: const Icon(Icons.contrast_outlined),
            onPressed: () =>
                PaperPickerSheet.show(context, widget.themeController),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  themeController: widget.themeController,
                  settings: widget.settings,
                ),
              ),
            ),
          ),
          const SizedBox(width: PapyrTheme.space1),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.library,
        builder: (context, _) {
          final books = widget.library.books;
          if (books.isEmpty) return _EmptyState(palette: p);
          return _Shelf(
            books: books,
            palette: p,
            library: widget.library,
            onOpen: _open,
            onDelete: _confirmDelete,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing ? null : _import,
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        icon: _importing
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
              )
            : const Icon(Icons.add),
        label: Text(
          _importing ? 'Importing…' : 'Add book',
          style: PapyrTheme.ui(p.onAccent, size: 14, weight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final added = await _importer.pickAndImport();
      if (!mounted) return;
      if (added.isEmpty) return;
      final p = widget.themeController.palette;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added.length == 1
                ? 'Added "${added.first.title}"'
                : 'Added ${added.length} books',
            style: PapyrTheme.ui(p.onAccent, size: 14),
          ),
          backgroundColor: p.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _open(Book book) {
    return ReaderRouter.open(
      context,
      book: book,
      library: widget.library,
      settings: widget.settings,
      themeController: widget.themeController,
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final p = widget.themeController.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Remove book?', style: PapyrTheme.title(p.inkPrimary, size: 18)),
        content: Text(
          'Remove "${book.title}" from your library? The file will be deleted from this device.',
          style: PapyrTheme.reading(p.inkSecondary, size: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: PapyrTheme.ui(p.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: PapyrTheme.ui(const Color(0xFFB3261E), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.library.delete(book);
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.books,
    required this.palette,
    required this.library,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Book> books;
  final PaperPalette palette;
  final LibraryStore library;
  final ValueChanged<Book> onOpen;
  final ValueChanged<Book> onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        PapyrTheme.space4,
        PapyrTheme.space3,
        PapyrTheme.space4,
        PapyrTheme.space7 + PapyrTheme.space6, // clear the FAB
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.52,
        crossAxisSpacing: PapyrTheme.space4,
        mainAxisSpacing: PapyrTheme.space5,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        return BookGridTile(
          book: book,
          coverFile: library.coverFile(book),
          palette: palette,
          onTap: () => onOpen(book),
          onLongPress: () => onDelete(book),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final PaperPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PapyrTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 56, color: palette.inkFaint),
            const SizedBox(height: PapyrTheme.space4),
            Text(
              'Your library is empty',
              textAlign: TextAlign.center,
              style: PapyrTheme.title(palette.inkPrimary, size: 22),
            ),
            const SizedBox(height: PapyrTheme.space2),
            Text(
              'Tap Add book to import a PDF or EPUB.\nEverything stays on your device.',
              textAlign: TextAlign.center,
              style: PapyrTheme.reading(palette.inkSecondary, size: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

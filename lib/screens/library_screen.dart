import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/book_importer.dart';
import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/library_options.dart';
import '../theme/paper_palette.dart';
import '../widgets/book_grid_tile.dart';
import '../widgets/book_options_sheet.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/edit_book_sheet.dart';
import '../widgets/library_stats_sheet.dart';
import '../widgets/paper_picker_sheet.dart';
import 'reader_router.dart';
import 'settings_screen.dart';

/// The library — Papyr's home. Shows the shelf of imported books, handles
/// importing, search, filtering, sorting, and per-book actions.
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
  final _searchController = TextEditingController();
  bool _importing = false;
  bool _searching = false;
  String _search = '';
  late LibraryFilter _filter = widget.settings.libraryFilter;
  late LibrarySort _sort = widget.settings.librarySort;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.themeController.palette;
    return Scaffold(
      appBar: _buildAppBar(p),
      body: ListenableBuilder(
        listenable: widget.library,
        builder: (context, _) {
          final all = widget.library.books;
          if (all.isEmpty) return _EmptyState(palette: p);

          final visible = LibraryQuery.apply(
            all,
            search: _search,
            filter: _filter,
            sort: _sort,
          );
          final continueBook = _continueBook(all);

          return _Shelf(
            books: visible,
            continueBook: continueBook,
            palette: p,
            library: widget.library,
            onOpen: _open,
            onOptions: _openOptions,
            searching: _search.trim().isNotEmpty,
            filter: _filter,
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
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
              )
            : const Icon(Icons.add),
        label: Text(
          _importing ? 'Importing…' : 'Add book',
          style: PapyrTheme.ui(p.onAccent, size: 14, weight: FontWeight.w600),
        ),
      ),
    );
  }

  // ---- App bar -----------------------------------------------------------
  PreferredSizeWidget _buildAppBar(PaperPalette p) {
    return AppBar(
      leading: _searching
          ? IconButton(
              tooltip: 'Close search',
              icon: const Icon(Icons.arrow_back),
              onPressed: _stopSearch,
            )
          : null,
      title: _searching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: PapyrTheme.ui(p.inkPrimary, size: 16),
              cursorColor: p.accent,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search title or author',
                hintStyle: PapyrTheme.ui(p.inkFaint, size: 16),
              ),
              onChanged: (v) => setState(() => _search = v),
            )
          : const Text('Papyr'),
      actions: _searching
          ? [
              if (_search.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
            ]
          : [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _searching = true),
              ),
              IconButton(
                tooltip: 'Your reading',
                icon: const Icon(Icons.insights_outlined),
                onPressed: () => LibraryStatsSheet.show(
                  context,
                  books: widget.library.books,
                  palette: p,
                ),
              ),
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
      bottom: _FilterBar(
        palette: p,
        filter: _filter,
        sort: _sort,
        onFilter: (f) {
          setState(() => _filter = f);
          widget.settings.setLibraryFilter(f);
        },
        onSort: (s) {
          setState(() => _sort = s);
          widget.settings.setLibrarySort(s);
        },
      ),
    );
  }

  void _stopSearch() {
    _searchController.clear();
    setState(() {
      _searching = false;
      _search = '';
    });
  }

  Book? _continueBook(List<Book> all) {
    Book? best;
    DateTime bestWhen = DateTime.fromMillisecondsSinceEpoch(0);
    for (final b in all) {
      if (!b.hasStarted || b.isFinished) continue;
      final when = b.lastOpenedAt ?? b.addedAt;
      if (when.isAfter(bestWhen)) {
        best = b;
        bestWhen = when;
      }
    }
    return best;
  }

  // ---- Actions -----------------------------------------------------------
  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await _importer.pickAndImport();
      if (!mounted) return;
      final added = result.added;
      if (added.isEmpty && result.duplicates == 0) return;

      final String message;
      if (added.isEmpty) {
        message = result.duplicates == 1
            ? 'Already in your library'
            : 'All ${result.duplicates} already in your library';
      } else {
        final base = added.length == 1
            ? 'Added "${added.first.title}"'
            : 'Added ${added.length} books';
        message = result.duplicates == 0
            ? base
            : '$base · ${result.duplicates} already in library';
      }
      _snack(message);
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

  void _openOptions(Book book) {
    final p = widget.themeController.palette;
    BookOptionsSheet.show(
      context,
      book: book,
      coverFile: widget.library.coverFile(book),
      palette: p,
      onEdit: () => _editDetails(book),
      onToggleFinished: () async {
        final finishing = !book.isFinished;
        await widget.library.setReadStatus(book, finished: finishing);
        _snack(finishing ? 'Marked as finished' : 'Marked as unread');
      },
      onRemove: () => _confirmDelete(book),
    );
  }

  void _editDetails(Book book) {
    final p = widget.themeController.palette;
    EditBookSheet.show(
      context,
      book: book,
      palette: p,
      onSave: (title, author) async {
        await widget.library.updateDetails(book, title: title, author: author);
        _snack('Saved');
      },
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final p = widget.themeController.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title:
            Text('Remove book?', style: PapyrTheme.title(p.inkPrimary, size: 18)),
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
            child: Text('Remove',
                style: PapyrTheme.ui(const Color(0xFFB3261E),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.library.delete(book);
  }

  void _snack(String message) {
    if (!mounted) return;
    final p = widget.themeController.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: PapyrTheme.ui(p.onAccent, size: 14)),
        backgroundColor: p.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// The pinned filter-chip + sort row beneath the app bar.
class _FilterBar extends StatelessWidget implements PreferredSizeWidget {
  const _FilterBar({
    required this.palette,
    required this.filter,
    required this.sort,
    required this.onFilter,
    required this.onSort,
  });

  final PaperPalette palette;
  final LibraryFilter filter;
  final LibrarySort sort;
  final ValueChanged<LibraryFilter> onFilter;
  final ValueChanged<LibrarySort> onSort;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: PapyrTheme.space4),
              children: [
                for (final f in LibraryFilter.values) ...[
                  _Chip(
                    label: f.label,
                    selected: f == filter,
                    palette: p,
                    onTap: () => onFilter(f),
                  ),
                  const SizedBox(width: PapyrTheme.space2),
                ],
              ],
            ),
          ),
          PopupMenuButton<LibrarySort>(
            tooltip: 'Sort',
            icon: Icon(Icons.sort, color: p.inkSecondary),
            color: p.surface,
            onSelected: onSort,
            itemBuilder: (context) => [
              for (final s in LibrarySort.values)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                        s == sort ? Icons.check : Icons.check,
                        size: 18,
                        color: s == sort ? p.accent : Colors.transparent,
                      ),
                      const SizedBox(width: PapyrTheme.space2),
                      Text(s.label, style: PapyrTheme.ui(p.inkPrimary, size: 14)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: PapyrTheme.space1),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final PaperPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Center(
      child: Material(
        color: selected ? p.accent : p.surface,
        borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PapyrTheme.space4, vertical: PapyrTheme.space2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
              border: Border.all(color: selected ? p.accent : p.divider),
            ),
            child: Text(
              label,
              style: PapyrTheme.ui(
                selected ? p.onAccent : p.inkSecondary,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.books,
    required this.continueBook,
    required this.palette,
    required this.library,
    required this.onOpen,
    required this.onOptions,
    required this.searching,
    required this.filter,
  });

  final List<Book> books;
  final Book? continueBook;
  final PaperPalette palette;
  final LibraryStore library;
  final ValueChanged<Book> onOpen;
  final ValueChanged<Book> onOptions;
  final bool searching;
  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    // The continue-reading banner only makes sense on the unfiltered, unsearched
    // shelf — otherwise it duplicates or contradicts what's shown below.
    final showBanner =
        continueBook != null && !searching && filter == LibraryFilter.all;

    if (books.isEmpty) {
      return _NoResults(palette: palette, searching: searching);
    }

    return CustomScrollView(
      slivers: [
        if (showBanner)
          SliverToBoxAdapter(
            child: ContinueReadingCard(
              book: continueBook!,
              coverFile: library.coverFile(continueBook!),
              palette: palette,
              onOpen: () => onOpen(continueBook!),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            PapyrTheme.space4,
            PapyrTheme.space3,
            PapyrTheme.space4,
            PapyrTheme.space7 + PapyrTheme.space6, // clear the FAB
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.52,
              crossAxisSpacing: PapyrTheme.space4,
              mainAxisSpacing: PapyrTheme.space5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final book = books[i];
                return BookGridTile(
                  book: book,
                  coverFile: library.coverFile(book),
                  palette: palette,
                  onTap: () => onOpen(book),
                  onLongPress: () => onOptions(book),
                );
              },
              childCount: books.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.palette, required this.searching});

  final PaperPalette palette;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PapyrTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.filter_list_off,
              size: 48,
              color: palette.inkFaint,
            ),
            const SizedBox(height: PapyrTheme.space3),
            Text(
              searching ? 'No books match your search' : 'Nothing here yet',
              textAlign: TextAlign.center,
              style: PapyrTheme.ui(palette.inkSecondary, size: 15),
            ),
          ],
        ),
      ),
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

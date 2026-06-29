import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import '../widgets/bookmarks_sheet.dart';
import '../widgets/paper_picker_sheet.dart';
import '../widgets/reader_paper_filter.dart';

/// Reads a PDF with pdfrx, tinted to match the selected paper. Chrome (top bar)
/// toggles on tap; reading position is saved as a page number.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.book,
    required this.library,
    required this.themeController,
  });

  final Book book;
  final LibraryStore library;
  final ThemeController themeController;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _controller = PdfViewerController();
  late int _currentPage = int.tryParse(widget.book.locator ?? '') ?? 1;
  int? _totalPages;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _totalPages = widget.book.pageCount;
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  void _saveProgress() {
    final total = _totalPages ?? widget.book.pageCount;
    if (total == null || total <= 0) return;
    widget.library.saveProgress(
      widget.book,
      progress: _currentPage / total,
      locator: _currentPage.toString(),
    );
  }

  void _addBookmark() {
    final total = _totalPages ?? widget.book.pageCount;
    final progress = (total != null && total > 0) ? _currentPage / total : 0.0;
    widget.library.addBookmark(
      widget.book,
      Bookmark(
        locator: _currentPage.toString(),
        label: 'Page $_currentPage',
        progress: progress,
        createdAt: DateTime.now(),
      ),
    );
    final p = widget.themeController.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmarked page $_currentPage',
            style: PapyrTheme.ui(p.onAccent, size: 14)),
        backgroundColor: p.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openBookmarks() {
    BookmarksSheet.show(
      context,
      book: widget.book,
      palette: widget.themeController.palette,
      onJump: (bm) {
        final page = int.tryParse(bm.locator);
        if (page != null) _controller.goToPage(pageNumber: page);
      },
      onRemove: (bm) => widget.library.removeBookmark(widget.book, bm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.themeController.palette;
    return Scaffold(
      backgroundColor: p.page,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              child: ColorFiltered(
                colorFilter: ReaderPaperFilter.forPalette(p),
                child: PdfViewer.file(
                  widget.library.bookFile(widget.book).path,
                  controller: _controller,
                  initialPageNumber: _currentPage,
                  params: PdfViewerParams(
                    backgroundColor: Colors.white,
                    onViewerReady: (document, _) {
                      setState(() => _totalPages = document.pages.length);
                      widget.book.pageCount ??= document.pages.length;
                    },
                    onPageChanged: (pageNumber) {
                      if (pageNumber == null) return;
                      setState(() => _currentPage = pageNumber);
                    },
                  ),
                ),
              ),
            ),
          ),
          _TopBar(
            visible: _chromeVisible,
            palette: p,
            title: widget.book.title,
            onBack: () => Navigator.of(context).pop(),
            onPaper: () => PaperPickerSheet.show(context, widget.themeController),
            onAddBookmark: _addBookmark,
            onBookmarks: _openBookmarks,
          ),
          _PageIndicator(
            visible: _chromeVisible,
            palette: p,
            current: _currentPage,
            total: _totalPages,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.visible,
    required this.palette,
    required this.title,
    required this.onBack,
    required this.onPaper,
    required this.onAddBookmark,
    required this.onBookmarks,
  });

  final bool visible;
  final PaperPalette palette;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onPaper;
  final VoidCallback onAddBookmark;
  final VoidCallback onBookmarks;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: visible ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Container(
          color: palette.page.withValues(alpha: 0.96),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: palette.inkPrimary),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PapyrTheme.ui(palette.inkPrimary, size: 15, weight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add bookmark',
                    icon: Icon(Icons.bookmark_add_outlined, color: palette.inkSecondary),
                    onPressed: onAddBookmark,
                  ),
                  IconButton(
                    tooltip: 'Bookmarks',
                    icon: Icon(Icons.bookmarks_outlined, color: palette.inkSecondary),
                    onPressed: onBookmarks,
                  ),
                  IconButton(
                    tooltip: 'Paper',
                    icon: Icon(Icons.contrast_outlined, color: palette.inkSecondary),
                    onPressed: onPaper,
                  ),
                  const SizedBox(width: PapyrTheme.space1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.visible,
    required this.palette,
    required this.current,
    required this.total,
  });

  final bool visible;
  final PaperPalette palette;
  final int current;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: PapyrTheme.space3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PapyrTheme.space3,
                  vertical: PapyrTheme.space1,
                ),
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
                  border: Border.all(color: palette.divider),
                ),
                child: Text(
                  total == null ? '$current' : '$current / $total',
                  style: PapyrTheme.ui(palette.inkSecondary, size: 12, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

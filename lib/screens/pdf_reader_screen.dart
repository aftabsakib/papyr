import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../services/pdf_text_extractor.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import '../widgets/bookmarks_sheet.dart';
import '../widgets/paper_picker_sheet.dart';
import '../widgets/pdf_reflow_view.dart';
import '../widgets/reading_settings_sheet.dart';

/// Reads a PDF two ways:
/// - Page view: the original fixed page (pdfrx), tinted to the paper.
/// - Reading view: the extracted text reflowed like an ebook (Kindle-style).
/// The mode toggles in the top bar; scanned PDFs (no text) stay in Page view.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.book,
    required this.library,
    required this.settings,
    required this.themeController,
  });

  final Book book;
  final LibraryStore library;
  final SettingsStore settings;
  final ThemeController themeController;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _controller = PdfViewerController();
  late int _currentPage = int.tryParse(widget.book.locator ?? '') ?? 1;
  int? _totalPages;
  bool _chromeVisible = true;

  // Reading (reflow) mode.
  late bool _reflow = widget.settings.pdfReflowMode;
  List<String>? _paragraphs;
  bool _extracting = false;
  bool _noText = false;
  late double _fontScale = widget.settings.fontScale;
  late double _lineHeight = widget.settings.lineHeight;
  late double _reflowProgress = widget.book.progress;

  @override
  void initState() {
    super.initState();
    _totalPages = widget.book.pageCount;
    widget.themeController.addListener(_onPaperChanged);
    // If the user last left PDFs in Reading view, extract text up front.
    if (_reflow) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureExtracted());
    }
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_onPaperChanged);
    if (_reflow) {
      widget.library.saveProgress(widget.book, progress: _reflowProgress);
    } else {
      _savePageProgress();
    }
    super.dispose();
  }

  void _onPaperChanged() {
    if (mounted) setState(() {});
  }

  String get _path => widget.library.bookFile(widget.book).path;

  // ---- Page view ---------------------------------------------------------
  void _paintPaperTint(Canvas canvas, Rect pageRect, PdfPage page) {
    final p = widget.themeController.palette;
    final paint = Paint();
    if (p.isDark) {
      paint
        ..color = Colors.white
        ..blendMode = BlendMode.difference;
    } else {
      paint
        ..color = p.page
        ..blendMode = BlendMode.multiply;
    }
    canvas.drawRect(pageRect, paint);
  }

  void _savePageProgress() {
    final total = _totalPages ?? widget.book.pageCount;
    if (total == null || total <= 0) return;
    widget.library.saveProgress(
      widget.book,
      progress: _currentPage / total,
      locator: _currentPage.toString(),
    );
  }

  // ---- Mode toggle + extraction -----------------------------------------
  Future<bool> _ensureExtracted() async {
    if (_paragraphs != null) return true;
    if (_noText) return false;
    setState(() => _extracting = true);
    try {
      final paras = await PdfTextExtractor.extractParagraphs(_path);
      if (!mounted) return false;
      if (paras.isEmpty) {
        setState(() {
          _noText = true;
          _extracting = false;
          _reflow = false; // nothing to reflow — fall back to pages
        });
        _snack('This PDF has no text to reflow — it may be scanned.');
        return false;
      }
      setState(() {
        _paragraphs = paras;
        _extracting = false;
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => _extracting = false);
      _snack('Could not read the text from this PDF.');
      return false;
    }
  }

  Future<void> _toggleMode() async {
    if (!_reflow) {
      final ok = await _ensureExtracted();
      if (!ok || !mounted) return;
    }
    setState(() => _reflow = !_reflow);
    widget.settings.setPdfReflowMode(_reflow);
  }

  void _openReadingSettings() {
    ReadingSettingsSheet.show(
      context,
      themeController: widget.themeController,
      fontScale: _fontScale,
      lineHeight: _lineHeight,
      onFontScale: (v) {
        widget.settings.setFontScale(v);
        setState(() => _fontScale = v);
      },
      onLineHeight: (v) {
        widget.settings.setLineHeight(v);
        setState(() => _lineHeight = v);
      },
    );
  }

  // ---- Bookmarks (page view) --------------------------------------------
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
    _snack('Bookmarked page $_currentPage');
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

  void _snack(String message) {
    final p = widget.themeController.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: PapyrTheme.ui(p.onAccent, size: 14)),
        backgroundColor: p.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.themeController.palette;
    final showReflow = _reflow && _paragraphs != null;
    return Scaffold(
      backgroundColor: p.page,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_extracting)
            Center(child: CircularProgressIndicator(color: p.accent))
          else if (showReflow)
            PdfReflowView(
              title: widget.book.title,
              paragraphs: _paragraphs!,
              palette: p,
              fontScale: _fontScale,
              lineHeight: _lineHeight,
              initialProgress: _reflowProgress,
              onProgress: (v) => _reflowProgress = v,
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              child: PdfViewer.file(
                _path,
                controller: _controller,
                initialPageNumber: _currentPage,
                params: PdfViewerParams(
                  backgroundColor: p.page,
                  pagePaintCallbacks: [_paintPaperTint],
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              visible: _chromeVisible,
              palette: p,
              title: widget.book.title,
              reflow: _reflow,
              onBack: () => Navigator.of(context).pop(),
              onToggleMode: _toggleMode,
              onPaper: () => PaperPickerSheet.show(context, widget.themeController),
              onReadingSettings: _reflow ? _openReadingSettings : null,
              onAddBookmark: _reflow ? null : _addBookmark,
              onBookmarks: _reflow ? null : _openBookmarks,
            ),
          ),
          if (!showReflow)
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
    required this.reflow,
    required this.onBack,
    required this.onToggleMode,
    required this.onPaper,
    required this.onReadingSettings,
    required this.onAddBookmark,
    required this.onBookmarks,
  });

  final bool visible;
  final PaperPalette palette;
  final String title;
  final bool reflow;
  final VoidCallback onBack;
  final VoidCallback onToggleMode;
  final VoidCallback onPaper;
  final VoidCallback? onReadingSettings;
  final VoidCallback? onAddBookmark;
  final VoidCallback? onBookmarks;

  @override
  Widget build(BuildContext context) {
    final hasOverflow =
        onReadingSettings != null || onAddBookmark != null || onBookmarks != null;
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
                    tooltip: reflow ? 'Page view' : 'Reading view',
                    icon: Icon(
                      reflow ? Icons.description_outlined : Icons.notes,
                      color: palette.inkSecondary,
                    ),
                    onPressed: onToggleMode,
                  ),
                  IconButton(
                    tooltip: 'Paper',
                    icon: Icon(Icons.contrast_outlined, color: palette.inkSecondary),
                    onPressed: onPaper,
                  ),
                  if (hasOverflow)
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      icon: Icon(Icons.more_vert, color: palette.inkSecondary),
                      color: palette.surface,
                      onSelected: (value) {
                        switch (value) {
                          case 'text':
                            onReadingSettings?.call();
                          case 'add':
                            onAddBookmark?.call();
                          case 'list':
                            onBookmarks?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onReadingSettings != null)
                          _item('text', 'Text size', palette),
                        if (onAddBookmark != null)
                          _item('add', 'Add bookmark', palette),
                        if (onBookmarks != null)
                          _item('list', 'Bookmarks', palette),
                      ],
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

  PopupMenuItem<String> _item(String value, String label, PaperPalette palette) =>
      PopupMenuItem(
        value: value,
        child: Text(label, style: PapyrTheme.ui(palette.inkPrimary, size: 14)),
      );
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

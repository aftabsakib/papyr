import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import '../theme/reading_options.dart';
import '../widgets/bookmarks_sheet.dart';
import '../widgets/reader_comfort.dart';
import '../widgets/reading_settings_sheet.dart';
import '../widgets/toc_sheet.dart';
import 'epub_search_screen.dart';

/// Reads a reflowable EPUB with flutter_epub_viewer. The selected paper drives
/// the page colours live, and font size / line spacing are adjustable. Reading
/// position is saved as an EPUB CFI plus a progress fraction.
class EpubReaderScreen extends StatefulWidget {
  const EpubReaderScreen({
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
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen>
    with ReaderComfort<EpubReaderScreen> {
  final _controller = EpubController();
  bool _loaded = false;
  String? _currentCfi;
  double _currentProgress = 0.0;
  List<EpubChapter> _chapters = [];

  late double _fontScale = widget.settings.fontScale;
  late double _lineHeight = widget.settings.lineHeight;
  late ReadingFont _font = widget.settings.readingFont;
  late ReadingMargin _margin = widget.settings.readingMargin;
  late double _warmth = widget.settings.warmth;
  late double? _brightness = widget.settings.brightness;

  /// @font-face rule (base64-embedded OpenDyslexic) for the web view, built once.
  Map<String, dynamic>? _dyslexicFace;

  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_onPaperChanged);
    enterReaderComfort(brightness: _brightness);
    if (_font == ReadingFont.dyslexic) _ensureDyslexicFont();
  }

  @override
  void dispose() {
    exitReaderComfort();
    widget.themeController.removeListener(_onPaperChanged);
    super.dispose();
  }

  Future<void> _ensureDyslexicFont() async {
    if (_dyslexicFace != null) return;
    try {
      final data = await rootBundle.load('assets/fonts/OpenDyslexic-Regular.otf');
      final b64 = base64Encode(data.buffer.asUint8List());
      _dyslexicFace = {
        'font-family': '"OpenDyslexic"',
        'font-style': 'normal',
        'font-weight': 'normal',
        'src': 'url(data:font/opentype;base64,$b64)',
      };
      if (_loaded) _controller.updateTheme(theme: _epubTheme());
    } catch (_) {
      // Fall back to the sans stack if the font can't be loaded.
    }
  }

  PaperPalette get _palette => widget.themeController.palette;

  int get _fontSizePx => (_fontScale * 19).round();

  void _onPaperChanged() {
    if (_loaded) _controller.updateTheme(theme: _epubTheme());
    if (mounted) setState(() {});
  }

  EpubTheme _epubTheme() {
    final p = _palette;
    final lh = _lineHeight.toStringAsFixed(2);
    final m = '${_margin.cssMargin}px';
    final css = <String, dynamic>{
      'body': {
        'background': _hex(p.page),
        'color': _hex(p.inkPrimary),
        'line-height': lh,
        'font-family': _font.cssFamily,
        'padding-left': m,
        'padding-right': m,
      },
      'p': {'line-height': lh},
      'a': {'color': _hex(p.accent)},
    };
    // Embed OpenDyslexic into the page when chosen and loaded.
    if (_font == ReadingFont.dyslexic && _dyslexicFace != null) {
      css['@font-face'] = _dyslexicFace;
    }
    return EpubTheme.custom(
      backgroundDecoration: BoxDecoration(color: p.page),
      foregroundColor: p.inkPrimary,
      customCss: css,
    );
  }

  void _onEpubLoaded() {
    _controller.updateTheme(theme: _epubTheme());
    _controller.setFontSize(fontSize: _fontSizePx.toDouble());
    // Rebuild so the loading overlay is removed once the book is displayed.
    if (mounted) {
      setState(() => _loaded = true);
    } else {
      _loaded = true;
    }
  }

  void _onRelocated(EpubLocation location) {
    _currentCfi = location.startCfi;
    _currentProgress = location.progress;
    widget.library.saveProgress(
      widget.book,
      progress: location.progress,
      locator: location.startCfi,
    );
  }

  void _addBookmark() {
    final cfi = _currentCfi;
    if (cfi == null) return;
    final percent = (_currentProgress * 100).round();
    widget.library.addBookmark(
      widget.book,
      Bookmark(
        locator: cfi,
        label: '$percent% through',
        progress: _currentProgress,
        createdAt: DateTime.now(),
      ),
    );
    final p = _palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark saved',
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
      palette: _palette,
      onJump: (bm) {
        if (_loaded) _controller.display(cfi: bm.locator);
      },
      onRemove: (bm) => widget.library.removeBookmark(widget.book, bm),
    );
  }

  void _openToc() {
    TocSheet.show(
      context,
      chapters: _chapters,
      palette: _palette,
      onJump: (href) {
        if (_loaded) _controller.display(cfi: href);
      },
    );
  }

  Future<void> _openSearch() async {
    final cfi = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EpubSearchScreen(
          controller: _controller,
          palette: _palette,
        ),
      ),
    );
    if (cfi != null && _loaded) _controller.display(cfi: cfi);
  }

  Future<void> _openSettings() async {
    await ReadingSettingsSheet.show(
      context,
      themeController: widget.themeController,
      fontScale: _fontScale,
      lineHeight: _lineHeight,
      font: _font,
      margin: _margin,
      warmth: _warmth,
      brightness: _brightness,
      onFontScale: (v) {
        setState(() => _fontScale = v);
        widget.settings.setFontScale(v);
        if (_loaded) _controller.setFontSize(fontSize: _fontSizePx.toDouble());
      },
      onLineHeight: (v) {
        setState(() => _lineHeight = v);
        widget.settings.setLineHeight(v);
        if (_loaded) _controller.updateTheme(theme: _epubTheme());
      },
      onFont: (v) {
        setState(() => _font = v);
        widget.settings.setReadingFont(v);
        if (v == ReadingFont.dyslexic && _dyslexicFace == null) {
          _ensureDyslexicFont();
        } else if (_loaded) {
          _controller.updateTheme(theme: _epubTheme());
        }
      },
      onMargin: (v) {
        setState(() => _margin = v);
        widget.settings.setReadingMargin(v);
        if (_loaded) _controller.updateTheme(theme: _epubTheme());
      },
      onWarmth: (v) {
        setState(() => _warmth = v);
        widget.settings.setWarmth(v);
      },
      onBrightness: (v) {
        setState(() => _brightness = v);
        widget.settings.setBrightness(v);
        if (v == null) {
          resetBrightness();
        } else {
          applyBrightness(v);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        backgroundColor: p.page,
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PapyrTheme.ui(p.inkPrimary, size: 15, weight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Contents',
            icon: Icon(Icons.toc, color: p.inkSecondary),
            onPressed: _openToc,
          ),
          IconButton(
            tooltip: 'Search',
            icon: Icon(Icons.search, color: p.inkSecondary),
            onPressed: _openSearch,
          ),
          IconButton(
            tooltip: 'Reading settings',
            icon: Icon(Icons.text_fields, color: p.inkSecondary),
            onPressed: _openSettings,
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(Icons.more_vert, color: p.inkSecondary),
            color: p.surface,
            onSelected: (value) {
              if (value == 'add') _addBookmark();
              if (value == 'list') _openBookmarks();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'add',
                child: Text('Add bookmark', style: PapyrTheme.ui(p.inkPrimary, size: 14)),
              ),
              PopupMenuItem(
                value: 'list',
                child: Text('Bookmarks', style: PapyrTheme.ui(p.inkPrimary, size: 14)),
              ),
            ],
          ),
          const SizedBox(width: PapyrTheme.space1),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: EpubViewer(
              epubController: _controller,
              epubSource: EpubSource.fromFile(
                widget.library.bookFile(widget.book),
              ),
              initialCfi: widget.book.locator,
              displaySettings: EpubDisplaySettings(
                fontSize: _fontSizePx,
                flow: EpubFlow.paginated,
                snap: true,
                theme: _epubTheme(),
              ),
              onEpubLoaded: _onEpubLoaded,
              onChaptersLoaded: (chapters) => setState(() => _chapters = chapters),
              onRelocated: _onRelocated,
            ),
          ),
          if (!_loaded)
            Positioned.fill(
              child: ColoredBox(
                color: p.page,
                child: Center(
                  child: CircularProgressIndicator(color: p.accent),
                ),
              ),
            ),
          WarmthOverlay(_warmth),
        ],
      ),
    );
  }

  static String _hex(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import '../widgets/reading_settings_sheet.dart';

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

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  final _controller = EpubController();
  bool _loaded = false;

  late double _fontScale = widget.settings.fontScale;
  late double _lineHeight = widget.settings.lineHeight;

  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_onPaperChanged);
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_onPaperChanged);
    super.dispose();
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
    return EpubTheme.custom(
      backgroundDecoration: BoxDecoration(color: p.page),
      foregroundColor: p.inkPrimary,
      customCss: {
        'body': {
          'background': _hex(p.page),
          'color': _hex(p.inkPrimary),
          'line-height': lh,
          'font-family': '"Georgia", "Times New Roman", serif',
        },
        'p': {'line-height': lh},
        'a': {'color': _hex(p.accent)},
      },
    );
  }

  void _onEpubLoaded() {
    _loaded = true;
    _controller.updateTheme(theme: _epubTheme());
    _controller.setFontSize(fontSize: _fontSizePx.toDouble());
  }

  void _onRelocated(EpubLocation location) {
    widget.library.saveProgress(
      widget.book,
      progress: location.progress,
      locator: location.startCfi,
    );
  }

  Future<void> _openSettings() async {
    await ReadingSettingsSheet.show(
      context,
      themeController: widget.themeController,
      fontScale: _fontScale,
      lineHeight: _lineHeight,
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
            tooltip: 'Reading settings',
            icon: Icon(Icons.text_fields, color: p.inkSecondary),
            onPressed: _openSettings,
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

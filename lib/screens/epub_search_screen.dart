import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// Full-text search within an open EPUB. Tapping a result returns its CFI so
/// the reader can jump there.
class EpubSearchScreen extends StatefulWidget {
  const EpubSearchScreen({
    super.key,
    required this.controller,
    required this.palette,
  });

  final EpubController controller;
  final PaperPalette palette;

  @override
  State<EpubSearchScreen> createState() => _EpubSearchScreenState();
}

class _EpubSearchScreenState extends State<EpubSearchScreen> {
  final _field = TextEditingController();
  List<EpubSearchResult> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final q = _field.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _searched = true;
    });
    try {
      final results = await widget.controller.search(query: q);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: TextField(
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _run(),
          style: PapyrTheme.ui(p.inkPrimary, size: 16),
          cursorColor: p.accent,
          decoration: InputDecoration(
            hintText: 'Search this book',
            hintStyle: PapyrTheme.ui(p.inkFaint, size: 16),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: Icon(Icons.search, color: p.inkSecondary),
            onPressed: _run,
          ),
        ],
      ),
      body: _searching
          ? Center(child: CircularProgressIndicator(color: p.accent))
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _searched ? 'No matches found.' : 'Type a word or phrase to search.',
                    style: PapyrTheme.reading(p.inkSecondary, size: 15),
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(color: p.divider, height: 1),
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return ListTile(
                      title: Text(
                        r.excerpt.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: PapyrTheme.reading(p.inkPrimary, size: 14, height: 1.4),
                      ),
                      onTap: () => Navigator.of(context).pop(r.cfi),
                    );
                  },
                ),
    );
  }
}

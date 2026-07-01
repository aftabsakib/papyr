import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../theme/library_options.dart';
import '../theme/paper_palette.dart';

/// A small "your reading" summary: counts by status and format, plus an
/// estimate of pages read across PDFs.
class LibraryStatsSheet extends StatelessWidget {
  const LibraryStatsSheet({
    super.key,
    required this.stats,
    required this.palette,
  });

  final LibraryStats stats;
  final PaperPalette palette;

  static Future<void> show(
    BuildContext context, {
    required List<Book> books,
    required PaperPalette palette,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PapyrTheme.radiusLg)),
      ),
      builder: (_) =>
          LibraryStatsSheet(stats: LibraryStats.from(books), palette: palette),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final s = stats;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PapyrTheme.space5,
          PapyrTheme.space3,
          PapyrTheme.space5,
          PapyrTheme.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: PapyrTheme.space4),
            Text('Your reading', style: PapyrTheme.title(p.inkPrimary, size: 20)),
            const SizedBox(height: PapyrTheme.space4),
            Row(
              children: [
                _Stat(value: '${s.total}', label: 'Books', palette: p),
                _Stat(value: '${s.reading}', label: 'Reading', palette: p),
                _Stat(value: '${s.finished}', label: 'Finished', palette: p),
              ],
            ),
            const SizedBox(height: PapyrTheme.space4),
            _Line(label: 'Not started', value: '${s.unread}', palette: p),
            _Line(label: 'PDFs', value: '${s.pdfs}', palette: p),
            _Line(label: 'EPUBs', value: '${s.epubs}', palette: p),
            if (s.pagesRead > 0)
              _Line(
                label: 'PDF pages read',
                value: '~${s.pagesRead}',
                palette: p,
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.palette});

  final String value;
  final String label;
  final PaperPalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: PapyrTheme.space2),
        padding: const EdgeInsets.symmetric(vertical: PapyrTheme.space4),
        decoration: BoxDecoration(
          color: palette.page,
          borderRadius: BorderRadius.circular(PapyrTheme.radiusMd),
          border: Border.all(color: palette.divider),
        ),
        child: Column(
          children: [
            Text(value, style: PapyrTheme.title(palette.accent, size: 26)),
            const SizedBox(height: PapyrTheme.space1),
            Text(label,
                style: PapyrTheme.ui(palette.inkSecondary,
                    size: 11, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, required this.palette});

  final String label;
  final String value;
  final PaperPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PapyrTheme.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: PapyrTheme.ui(palette.inkSecondary, size: 14)),
          Text(value,
              style: PapyrTheme.ui(palette.inkPrimary,
                  size: 14, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

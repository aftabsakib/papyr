import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// A book cover. Shows the extracted cover image when available, otherwise a
/// generated paper-like cover with the title and format — so the shelf always
/// looks intentional, never broken.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    required this.coverFile,
    required this.palette,
  });

  final Book book;
  final File? coverFile;
  final PaperPalette palette;

  static const aspectRatio = 2 / 3; // standard book proportion

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(PapyrTheme.radiusSm);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: palette.surface,
          border: Border.all(color: palette.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: coverFile != null && coverFile!.existsSync()
              ? Image.file(
                  coverFile!,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => _Fallback(book: book, palette: palette),
                )
              : _Fallback(book: book, palette: palette),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.book, required this.palette});

  final Book book;
  final PaperPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.surface,
      padding: const EdgeInsets.all(PapyrTheme.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 3,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: PapyrTheme.space3),
          Expanded(
            child: Text(
              book.title,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: PapyrTheme.title(palette.inkPrimary, size: 15),
            ),
          ),
          if (book.author != null && book.author!.isNotEmpty)
            Text(
              book.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PapyrTheme.ui(palette.inkSecondary, size: 11),
            ),
          const SizedBox(height: PapyrTheme.space1),
          Text(
            book.format.label,
            style: PapyrTheme.ui(palette.inkFaint, size: 10, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

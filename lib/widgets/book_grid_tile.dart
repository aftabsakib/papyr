import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import 'book_cover.dart';

/// A single shelf entry: cover, title, author, and a slim progress line.
class BookGridTile extends StatelessWidget {
  const BookGridTile({
    super.key,
    required this.book,
    required this.coverFile,
    required this.palette,
    required this.onTap,
    required this.onLongPress,
  });

  final Book book;
  final File? coverFile;
  final PaperPalette palette;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(PapyrTheme.radiusSm),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(book: book, coverFile: coverFile, palette: palette),
          const SizedBox(height: PapyrTheme.space2),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PapyrTheme.ui(palette.inkPrimary, size: 13, weight: FontWeight.w600),
          ),
          if (book.author != null && book.author!.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              book.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PapyrTheme.ui(palette.inkSecondary, size: 11),
            ),
          ],
          const SizedBox(height: PapyrTheme.space2),
          _ProgressLine(book: book, palette: palette),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.book, required this.palette});

  final Book book;
  final PaperPalette palette;

  @override
  Widget build(BuildContext context) {
    final label = book.isFinished
        ? 'Finished'
        : book.hasStarted
            ? '${book.progressPercent}%'
            : 'New';
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: book.progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: palette.divider,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
        ),
        const SizedBox(width: PapyrTheme.space2),
        Text(
          label,
          style: PapyrTheme.ui(palette.inkFaint, size: 10, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

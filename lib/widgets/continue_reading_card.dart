import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import 'book_cover.dart';

/// A prominent "pick up where you left off" card at the top of the library.
/// Shown for the most recently opened, still-in-progress book.
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.book,
    required this.coverFile,
    required this.palette,
    required this.onOpen,
  });

  final Book book;
  final File? coverFile;
  final PaperPalette palette;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PapyrTheme.space4,
        PapyrTheme.space3,
        PapyrTheme.space4,
        PapyrTheme.space1,
      ),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.all(PapyrTheme.space3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
              border: Border.all(color: p.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  child: BookCover(book: book, coverFile: coverFile, palette: p),
                ),
                const SizedBox(width: PapyrTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue reading',
                        style: PapyrTheme.ui(p.accent,
                            size: 11, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: PapyrTheme.space1),
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PapyrTheme.title(p.inkPrimary, size: 17),
                      ),
                      const SizedBox(height: PapyrTheme.space2),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: book.progress.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: p.divider,
                                valueColor: AlwaysStoppedAnimation(p.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: PapyrTheme.space2),
                          Text(
                            '${book.progressPercent}%',
                            style: PapyrTheme.ui(p.inkFaint,
                                size: 11, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PapyrTheme.space2),
                Icon(Icons.play_circle_fill, color: p.accent, size: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

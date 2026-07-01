import 'dart:io';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import 'book_cover.dart';

/// The long-press action menu for a book: edit details, toggle finished, or
/// remove. Replaces the old "long-press deletes immediately" behaviour with a
/// safer, more capable menu.
class BookOptionsSheet extends StatelessWidget {
  const BookOptionsSheet({
    super.key,
    required this.book,
    required this.coverFile,
    required this.palette,
    required this.onEdit,
    required this.onToggleFinished,
    required this.onAddToCollections,
    required this.onRemove,
  });

  final Book book;
  final File? coverFile;
  final PaperPalette palette;
  final VoidCallback onEdit;
  final VoidCallback onToggleFinished;
  final VoidCallback onAddToCollections;
  final VoidCallback onRemove;

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required File? coverFile,
    required PaperPalette palette,
    required VoidCallback onEdit,
    required VoidCallback onToggleFinished,
    required VoidCallback onAddToCollections,
    required VoidCallback onRemove,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PapyrTheme.radiusLg)),
      ),
      builder: (_) => BookOptionsSheet(
        book: book,
        coverFile: coverFile,
        palette: palette,
        onEdit: onEdit,
        onToggleFinished: onToggleFinished,
        onAddToCollections: onAddToCollections,
        onRemove: onRemove,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    const danger = Color(0xFFB3261E);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: PapyrTheme.space3),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: p.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PapyrTheme.space5,
              PapyrTheme.space4,
              PapyrTheme.space5,
              PapyrTheme.space2,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: BookCover(book: book, coverFile: coverFile, palette: p),
                ),
                const SizedBox(width: PapyrTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PapyrTheme.ui(p.inkPrimary,
                            size: 15, weight: FontWeight.w600),
                      ),
                      if (book.author != null && book.author!.isNotEmpty)
                        Text(
                          book.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PapyrTheme.ui(p.inkSecondary, size: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: p.divider, height: PapyrTheme.space4),
          _Action(
            icon: Icons.edit_outlined,
            label: 'Edit details',
            palette: p,
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          _Action(
            icon: book.isFinished
                ? Icons.restart_alt
                : Icons.check_circle_outline,
            label: book.isFinished ? 'Mark as unread' : 'Mark as finished',
            palette: p,
            onTap: () {
              Navigator.pop(context);
              onToggleFinished();
            },
          ),
          _Action(
            icon: Icons.collections_bookmark_outlined,
            label: 'Add to collections',
            palette: p,
            onTap: () {
              Navigator.pop(context);
              onAddToCollections();
            },
          ),
          _Action(
            icon: Icons.delete_outline,
            label: 'Remove from library',
            palette: p,
            color: danger,
            onTap: () {
              Navigator.pop(context);
              onRemove();
            },
          ),
          const SizedBox(height: PapyrTheme.space3),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final PaperPalette palette;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? palette.inkPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PapyrTheme.space5,
          vertical: PapyrTheme.space4,
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: PapyrTheme.space4),
            Text(label, style: PapyrTheme.ui(c, size: 15)),
          ],
        ),
      ),
    );
  }
}

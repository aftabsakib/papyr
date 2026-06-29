import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// Lists a book's bookmarks; tap to jump, trash to remove.
class BookmarksSheet extends StatefulWidget {
  const BookmarksSheet({
    super.key,
    required this.book,
    required this.palette,
    required this.onJump,
    required this.onRemove,
  });

  final Book book;
  final PaperPalette palette;
  final ValueChanged<Bookmark> onJump;
  final ValueChanged<Bookmark> onRemove;

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required PaperPalette palette,
    required ValueChanged<Bookmark> onJump,
    required ValueChanged<Bookmark> onRemove,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookmarksSheet(
        book: book,
        palette: palette,
        onJump: onJump,
        onRemove: onRemove,
      ),
    );
  }

  @override
  State<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<BookmarksSheet> {
  late final List<Bookmark> _bookmarks = List.of(widget.book.bookmarks);

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PapyrTheme.space5,
          PapyrTheme.space4,
          PapyrTheme.space5,
          PapyrTheme.space5,
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
                  color: p.inkFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: PapyrTheme.space4),
            Text('Bookmarks', style: PapyrTheme.title(p.inkPrimary, size: 20)),
            const SizedBox(height: PapyrTheme.space3),
            if (_bookmarks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: PapyrTheme.space4),
                child: Text(
                  'No bookmarks yet. Tap the bookmark icon while reading to save your spot.',
                  style: PapyrTheme.reading(p.inkSecondary, size: 15, height: 1.5),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _bookmarks.length,
                  separatorBuilder: (_, __) => Divider(color: p.divider, height: 1),
                  itemBuilder: (context, i) {
                    final bm = _bookmarks[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.bookmark, color: p.accent),
                      title: Text(
                        bm.label,
                        style: PapyrTheme.ui(p.inkPrimary, size: 15, weight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${(bm.progress * 100).round()}% through',
                        style: PapyrTheme.ui(p.inkSecondary, size: 12),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: p.inkFaint),
                        onPressed: () {
                          widget.onRemove(bm);
                          setState(() => _bookmarks.removeAt(i));
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onJump(bm);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

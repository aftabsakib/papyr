import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// Table of contents for an EPUB. Lists chapters (with nested sub-chapters
/// indented); tapping one jumps there.
class TocSheet extends StatelessWidget {
  const TocSheet({
    super.key,
    required this.chapters,
    required this.palette,
    required this.onJump,
  });

  final List<EpubChapter> chapters;
  final PaperPalette palette;
  final ValueChanged<String> onJump; // receives chapter href

  static Future<void> show(
    BuildContext context, {
    required List<EpubChapter> chapters,
    required PaperPalette palette,
    required ValueChanged<String> onJump,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TocSheet(
        chapters: chapters,
        palette: palette,
        onJump: onJump,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flat = <({EpubChapter chapter, int depth})>[];
    void walk(List<EpubChapter> items, int depth) {
      for (final c in items) {
        flat.add((chapter: c, depth: depth));
        if (c.subitems.isNotEmpty) walk(c.subitems, depth + 1);
      }
    }

    walk(chapters, 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: PapyrTheme.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PapyrTheme.space3),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.inkFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: PapyrTheme.space4),
              Text('Contents', style: PapyrTheme.title(palette.inkPrimary, size: 20)),
              const SizedBox(height: PapyrTheme.space2),
              Expanded(
                child: flat.isEmpty
                    ? Text('No chapters found.',
                        style: PapyrTheme.reading(palette.inkSecondary, size: 15))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: flat.length,
                        itemBuilder: (context, i) {
                          final entry = flat[i];
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              onJump(entry.chapter.href);
                            },
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                PapyrTheme.space2 + entry.depth * PapyrTheme.space4,
                                PapyrTheme.space3,
                                PapyrTheme.space2,
                                PapyrTheme.space3,
                              ),
                              child: Text(
                                entry.chapter.title.trim(),
                                style: PapyrTheme.reading(
                                  entry.depth == 0 ? palette.inkPrimary : palette.inkSecondary,
                                  size: entry.depth == 0 ? 16 : 14,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

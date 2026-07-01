import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// Rename or delete collections. Deleting a collection keeps the books — it
/// just removes the grouping.
class ManageCollectionsSheet extends StatelessWidget {
  const ManageCollectionsSheet({
    super.key,
    required this.library,
    required this.palette,
  });

  final LibraryStore library;
  final PaperPalette palette;

  static Future<void> show(
    BuildContext context, {
    required LibraryStore library,
    required PaperPalette palette,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PapyrTheme.radiusLg)),
      ),
      builder: (_) => ManageCollectionsSheet(library: library, palette: palette),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return SafeArea(
      child: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final collections = library.collections;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PapyrTheme.space3),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(PapyrTheme.space5,
                    PapyrTheme.space4, PapyrTheme.space5, PapyrTheme.space3),
                child: Text('Manage collections',
                    style: PapyrTheme.title(p.inkPrimary, size: 20)),
              ),
              if (collections.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(PapyrTheme.space5, 0,
                      PapyrTheme.space5, PapyrTheme.space5),
                  child: Text(
                    'No collections yet. Long-press a book and choose "Add to collections" to make one.',
                    style: PapyrTheme.reading(p.inkSecondary, size: 14, height: 1.5),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: PapyrTheme.space4),
                    children: [
                      for (final c in collections)
                        _Row(
                          name: c.name,
                          count: library.bookCountIn(c.id),
                          palette: p,
                          onRename: () => _rename(context, c),
                          onDelete: () => _delete(context, c),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, Collection collection) async {
    final p = palette;
    final controller = TextEditingController(text: collection.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Rename collection',
            style: PapyrTheme.title(p.inkPrimary, size: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: PapyrTheme.reading(p.inkPrimary, size: 16, height: 1.3),
          cursorColor: p.accent,
          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: p.accent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: PapyrTheme.ui(p.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text('Rename',
                style: PapyrTheme.ui(p.accent, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await library.renameCollection(collection, name);
    }
  }

  Future<void> _delete(BuildContext context, Collection collection) async {
    final p = palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Delete collection?',
            style: PapyrTheme.title(p.inkPrimary, size: 18)),
        content: Text(
          'Delete "${collection.name}"? Your books stay in the library — only the collection is removed.',
          style: PapyrTheme.reading(p.inkSecondary, size: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: PapyrTheme.ui(p.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: PapyrTheme.ui(const Color(0xFFB3261E),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) await library.deleteCollection(collection);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.name,
    required this.count,
    required this.palette,
    required this.onRename,
    required this.onDelete,
  });

  final String name;
  final int count;
  final PaperPalette palette;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: PapyrTheme.space5, vertical: PapyrTheme.space2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PapyrTheme.ui(p.inkPrimary,
                        size: 15, weight: FontWeight.w600)),
                Text('$count ${count == 1 ? 'book' : 'books'}',
                    style: PapyrTheme.ui(p.inkSecondary, size: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: Icon(Icons.edit_outlined, color: p.inkSecondary, size: 20),
            onPressed: onRename,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFB3261E), size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

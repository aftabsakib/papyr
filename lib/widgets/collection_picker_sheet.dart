import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/library_store.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// Lets the user tick which collections a book belongs to, and create a new
/// collection inline. A book can be in several at once.
class CollectionPickerSheet extends StatefulWidget {
  const CollectionPickerSheet({
    super.key,
    required this.book,
    required this.library,
    required this.palette,
  });

  final Book book;
  final LibraryStore library;
  final PaperPalette palette;

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required LibraryStore library,
    required PaperPalette palette,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PapyrTheme.radiusLg)),
      ),
      builder: (_) => CollectionPickerSheet(
          book: book, library: library, palette: palette),
    );
  }

  @override
  State<CollectionPickerSheet> createState() => _CollectionPickerSheetState();
}

class _CollectionPickerSheetState extends State<CollectionPickerSheet> {
  late final Set<String> _selected = widget.book.collectionIds.toSet();
  final _newController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _newController.dispose();
    super.dispose();
  }

  Future<void> _createAndSelect() async {
    final name = _newController.text.trim();
    if (name.isEmpty) return;
    final collection = await widget.library.createCollection(name);
    if (!mounted) return;
    setState(() {
      _selected.add(collection.id);
      _newController.clear();
      _creating = false;
    });
  }

  Future<void> _save() async {
    await widget.library.setBookCollections(widget.book, _selected);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final collections = widget.library.collections;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
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
                PapyrTheme.space4, PapyrTheme.space5, PapyrTheme.space2),
            child: Text('Add to collections',
                style: PapyrTheme.title(p.inkPrimary, size: 20)),
          ),
          Flexible(
            child: collections.isEmpty && !_creating
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PapyrTheme.space5, vertical: PapyrTheme.space4),
                    child: Text(
                      'No collections yet. Create one below to start grouping your books.',
                      style: PapyrTheme.reading(p.inkSecondary, size: 14, height: 1.5),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final c in collections)
                        _CheckRow(
                          label: c.name,
                          checked: _selected.contains(c.id),
                          palette: p,
                          onTap: () => setState(() {
                            if (_selected.contains(c.id)) {
                              _selected.remove(c.id);
                            } else {
                              _selected.add(c.id);
                            }
                          }),
                        ),
                    ],
                  ),
          ),
          Divider(color: p.divider, height: PapyrTheme.space4),
          if (_creating)
            Padding(
              padding: const EdgeInsets.fromLTRB(PapyrTheme.space5, 0,
                  PapyrTheme.space5, PapyrTheme.space3),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newController,
                      autofocus: true,
                      style: PapyrTheme.reading(p.inkPrimary, size: 16, height: 1.3),
                      cursorColor: p.accent,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createAndSelect(),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Collection name',
                        hintStyle: PapyrTheme.ui(p.inkFaint, size: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: PapyrTheme.space3,
                            vertical: PapyrTheme.space3),
                        filled: true,
                        fillColor: p.page,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PapyrTheme.radiusSm),
                          borderSide: BorderSide(color: p.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(PapyrTheme.radiusSm),
                          borderSide: BorderSide(color: p.accent, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: PapyrTheme.space2),
                  IconButton(
                    onPressed: _createAndSelect,
                    icon: Icon(Icons.check, color: p.accent),
                  ),
                ],
              ),
            )
          else
            _Action(
              icon: Icons.add,
              label: 'New collection',
              palette: p,
              onTap: () => setState(() => _creating = true),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(PapyrTheme.space5,
                PapyrTheme.space2, PapyrTheme.space5, PapyrTheme.space5),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: PapyrTheme.space4),
                ),
                child: Text('Done',
                    style: PapyrTheme.ui(p.onAccent, weight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.checked,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final PaperPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PapyrTheme.space5, vertical: PapyrTheme.space3),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              color: checked ? p.accent : p.inkFaint,
              size: 24,
            ),
            const SizedBox(width: PapyrTheme.space3),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PapyrTheme.ui(p.inkPrimary, size: 15)),
            ),
          ],
        ),
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
  });

  final IconData icon;
  final String label;
  final PaperPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PapyrTheme.space5, vertical: PapyrTheme.space3),
        child: Row(
          children: [
            Icon(icon, color: p.accent, size: 22),
            const SizedBox(width: PapyrTheme.space3),
            Text(label,
                style: PapyrTheme.ui(p.accent, size: 15, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

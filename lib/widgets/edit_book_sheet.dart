import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// A bottom sheet for editing a book's title and author. Returns the new
/// (title, author) via [onSave] when the user confirms.
class EditBookSheet extends StatefulWidget {
  const EditBookSheet({
    super.key,
    required this.book,
    required this.palette,
    required this.onSave,
  });

  final Book book;
  final PaperPalette palette;
  final void Function(String title, String author) onSave;

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required PaperPalette palette,
    required void Function(String title, String author) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PapyrTheme.radiusLg)),
      ),
      builder: (_) => EditBookSheet(book: book, palette: palette, onSave: onSave),
    );
  }

  @override
  State<EditBookSheet> createState() => _EditBookSheetState();
}

class _EditBookSheetState extends State<EditBookSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.book.title);
  late final TextEditingController _author =
      TextEditingController(text: widget.book.author ?? '');
  late bool _canSave = widget.book.title.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _title.addListener(() {
      final ok = _title.text.trim().isNotEmpty;
      if (ok != _canSave) setState(() => _canSave = ok);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: PapyrTheme.space5,
        right: PapyrTheme.space5,
        top: PapyrTheme.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + PapyrTheme.space5,
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
          Text('Edit details', style: PapyrTheme.title(p.inkPrimary, size: 20)),
          const SizedBox(height: PapyrTheme.space4),
          _Field(
            label: 'Title',
            controller: _title,
            palette: p,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: PapyrTheme.space4),
          _Field(
            label: 'Author',
            controller: _author,
            palette: p,
            hint: 'Optional',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: PapyrTheme.space5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: PapyrTheme.ui(p.inkSecondary)),
              ),
              const SizedBox(width: PapyrTheme.space2),
              FilledButton(
                onPressed: _canSave
                    ? () {
                        widget.onSave(_title.text, _author.text);
                        Navigator.pop(context);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  disabledBackgroundColor: p.divider,
                ),
                child: Text('Save',
                    style: PapyrTheme.ui(p.onAccent, weight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.palette,
    this.hint,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final PaperPalette palette;
  final String? hint;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PapyrTheme.ui(p.inkSecondary, size: 12, weight: FontWeight.w600)),
        const SizedBox(height: PapyrTheme.space1),
        TextField(
          controller: controller,
          textInputAction: textInputAction,
          style: PapyrTheme.reading(p.inkPrimary, size: 16, height: 1.3),
          cursorColor: p.accent,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: PapyrTheme.ui(p.inkFaint, size: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: PapyrTheme.space3,
              vertical: PapyrTheme.space3,
            ),
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
      ],
    );
  }
}

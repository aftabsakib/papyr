import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_picker_sheet.dart';

/// The library — Papyr's home. In this foundation build it shows the empty
/// state and a working paper switcher; importing and shelving real books is
/// wired up in the next phases.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.themeController,
    required this.settings,
  });

  final ThemeController themeController;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final p = themeController.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papyr'),
        actions: [
          IconButton(
            tooltip: 'Paper',
            icon: const Icon(Icons.contrast_outlined),
            onPressed: () => PaperPickerSheet.show(context, themeController),
          ),
          const SizedBox(width: PapyrTheme.space1),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PapyrTheme.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 56, color: p.inkFaint),
              const SizedBox(height: PapyrTheme.space4),
              Text(
                'Your library is empty',
                textAlign: TextAlign.center,
                style: PapyrTheme.title(p.inkPrimary, size: 22),
              ),
              const SizedBox(height: PapyrTheme.space2),
              Text(
                'Import a PDF or EPUB to start reading.\nEverything stays on your device.',
                textAlign: TextAlign.center,
                style: PapyrTheme.reading(p.inkSecondary, size: 15, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Importing books arrives in the next step.',
                  style: PapyrTheme.ui(p.onAccent, size: 14)),
              backgroundColor: p.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        icon: const Icon(Icons.add),
        label: Text('Add book', style: PapyrTheme.ui(p.onAccent, size: 14, weight: FontWeight.w600)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// Bottom sheet that lets the reader switch papers (Cream / Sepia / E-ink /
/// Night) and see each one previewed as a small page swatch.
class PaperPickerSheet extends StatelessWidget {
  const PaperPickerSheet({super.key, required this.controller});

  final ThemeController controller;

  static Future<void> show(BuildContext context, ThemeController controller) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: controller.palette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PaperPickerSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = controller.palette;
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
            Text('Paper', style: PapyrTheme.title(p.inkPrimary, size: 20)),
            const SizedBox(height: PapyrTheme.space4),
            Row(
              children: [
                for (final palette in PaperPalette.all)
                  Expanded(
                    child: _PaperSwatch(
                      palette: palette,
                      selected: palette.theme == controller.paper,
                      onTap: () {
                        controller.setPaper(palette.theme);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperSwatch extends StatelessWidget {
  const _PaperSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final PaperPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = palette.theme.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PapyrTheme.space1),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 76,
              decoration: BoxDecoration(
                color: palette.page,
                borderRadius: BorderRadius.circular(PapyrTheme.radiusMd),
                border: Border.all(
                  color: selected ? active.accent : palette.divider,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Aa',
                        style: PapyrTheme.title(palette.inkPrimary, size: 22)),
                    const SizedBox(height: 2),
                    Container(
                      width: 26,
                      height: 3,
                      decoration: BoxDecoration(
                        color: palette.inkSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: PapyrTheme.space2),
          Text(
            palette.theme.label,
            style: PapyrTheme.ui(
              selected ? active.inkPrimary : active.inkSecondary,
              size: 12,
              weight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

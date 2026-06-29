import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// Reading controls for the EPUB reader: paper, font size, and line spacing.
class ReadingSettingsSheet extends StatefulWidget {
  const ReadingSettingsSheet({
    super.key,
    required this.themeController,
    required this.fontScale,
    required this.lineHeight,
    required this.onFontScale,
    required this.onLineHeight,
  });

  final ThemeController themeController;
  final double fontScale;
  final double lineHeight;
  final ValueChanged<double> onFontScale;
  final ValueChanged<double> onLineHeight;

  static Future<void> show(
    BuildContext context, {
    required ThemeController themeController,
    required double fontScale,
    required double lineHeight,
    required ValueChanged<double> onFontScale,
    required ValueChanged<double> onLineHeight,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: themeController.palette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReadingSettingsSheet(
        themeController: themeController,
        fontScale: fontScale,
        lineHeight: lineHeight,
        onFontScale: onFontScale,
        onLineHeight: onLineHeight,
      ),
    );
  }

  @override
  State<ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<ReadingSettingsSheet> {
  late double _fontScale = widget.fontScale;
  late double _lineHeight = widget.lineHeight;

  @override
  Widget build(BuildContext context) {
    final p = widget.themeController.palette;
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
            _label('Text size', p),
            _Stepper(
              palette: p,
              value: _fontScale,
              min: 0.7,
              max: 2.2,
              step: 0.1,
              displayLabel: 'Aa',
              onChanged: (v) {
                setState(() => _fontScale = v);
                widget.onFontScale(v);
              },
            ),
            const SizedBox(height: PapyrTheme.space4),
            _label('Line spacing', p),
            _Stepper(
              palette: p,
              value: _lineHeight,
              min: 1.2,
              max: 2.4,
              step: 0.1,
              displayLabel: '↕',
              onChanged: (v) {
                setState(() => _lineHeight = v);
                widget.onLineHeight(v);
              },
            ),
            const SizedBox(height: PapyrTheme.space5),
            _label('Paper', p),
            const SizedBox(height: PapyrTheme.space2),
            Row(
              children: [
                for (final palette in PaperPalette.all)
                  Expanded(
                    child: _PaperDot(
                      palette: palette,
                      selected: palette.theme == widget.themeController.paper,
                      onTap: () {
                        widget.themeController.setPaper(palette.theme);
                        setState(() {});
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

  Widget _label(String text, PaperPalette p) => Padding(
        padding: const EdgeInsets.only(bottom: PapyrTheme.space2),
        child: Text(text,
            style: PapyrTheme.ui(p.inkSecondary, size: 12, weight: FontWeight.w600)),
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.palette,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.displayLabel,
    required this.onChanged,
  });

  final PaperPalette palette;
  final double value;
  final double min;
  final double max;
  final double step;
  final String displayLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(PapyrTheme.radiusMd),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          _btn(Icons.remove, value > min, () {
            final v = (value - step).clamp(min, max);
            onChanged(double.parse(v.toStringAsFixed(2)));
          }),
          Expanded(
            child: Center(
              child: Text(
                displayLabel,
                style: PapyrTheme.reading(palette.inkPrimary,
                    size: 16 + (value - 1) * 6, height: 1.0),
              ),
            ),
          ),
          _btn(Icons.add, value < max, () {
            final v = (value + step).clamp(min, max);
            onChanged(double.parse(v.toStringAsFixed(2)));
          }),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, bool enabled, VoidCallback onTap) => IconButton(
        icon: Icon(icon,
            color: enabled ? palette.inkPrimary : palette.inkFaint),
        onPressed: enabled ? onTap : null,
      );
}

class _PaperDot extends StatelessWidget {
  const _PaperDot({
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
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 44,
              decoration: BoxDecoration(
                color: palette.page,
                borderRadius: BorderRadius.circular(PapyrTheme.radiusSm),
                border: Border.all(
                  color: selected ? active.accent : palette.divider,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Center(
                child: Text('A',
                    style: PapyrTheme.title(palette.inkPrimary, size: 16)),
              ),
            ),
            const SizedBox(height: PapyrTheme.space1),
            Text(
              palette.theme.label,
              style: PapyrTheme.ui(
                selected ? active.inkPrimary : active.inkSecondary,
                size: 11,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

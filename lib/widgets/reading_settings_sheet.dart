import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import '../theme/reading_options.dart';

/// Full reading controls: text size, line spacing, font, margins, warmth,
/// brightness, and paper. Shared by the EPUB reader and the PDF Reading view.
class ReadingSettingsSheet extends StatefulWidget {
  const ReadingSettingsSheet({
    super.key,
    required this.themeController,
    required this.fontScale,
    required this.lineHeight,
    required this.font,
    required this.margin,
    required this.warmth,
    required this.brightness,
    required this.onFontScale,
    required this.onLineHeight,
    required this.onFont,
    required this.onMargin,
    required this.onWarmth,
    required this.onBrightness,
  });

  final ThemeController themeController;
  final double fontScale;
  final double lineHeight;
  final ReadingFont font;
  final ReadingMargin margin;
  final double warmth;
  final double? brightness; // null = follow system

  final ValueChanged<double> onFontScale;
  final ValueChanged<double> onLineHeight;
  final ValueChanged<ReadingFont> onFont;
  final ValueChanged<ReadingMargin> onMargin;
  final ValueChanged<double> onWarmth;
  final ValueChanged<double?> onBrightness;

  static Future<void> show(
    BuildContext context, {
    required ThemeController themeController,
    required double fontScale,
    required double lineHeight,
    required ReadingFont font,
    required ReadingMargin margin,
    required double warmth,
    required double? brightness,
    required ValueChanged<double> onFontScale,
    required ValueChanged<double> onLineHeight,
    required ValueChanged<ReadingFont> onFont,
    required ValueChanged<ReadingMargin> onMargin,
    required ValueChanged<double> onWarmth,
    required ValueChanged<double?> onBrightness,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: themeController.palette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReadingSettingsSheet(
        themeController: themeController,
        fontScale: fontScale,
        lineHeight: lineHeight,
        font: font,
        margin: margin,
        warmth: warmth,
        brightness: brightness,
        onFontScale: onFontScale,
        onLineHeight: onLineHeight,
        onFont: onFont,
        onMargin: onMargin,
        onWarmth: onWarmth,
        onBrightness: onBrightness,
      ),
    );
  }

  @override
  State<ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<ReadingSettingsSheet> {
  late double _fontScale = widget.fontScale;
  late double _lineHeight = widget.lineHeight;
  late ReadingFont _font = widget.font;
  late ReadingMargin _margin = widget.margin;
  late double _warmth = widget.warmth;
  late double? _brightness = widget.brightness;

  @override
  Widget build(BuildContext context) {
    final p = widget.themeController.palette;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: SingleChildScrollView(
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
              Center(child: _grabber(p)),
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
                displayLabel: _lineHeight.toStringAsFixed(1),
                onChanged: (v) {
                  setState(() => _lineHeight = v);
                  widget.onLineHeight(v);
                },
              ),
              const SizedBox(height: PapyrTheme.space4),
              _label('Font', p),
              _Segmented<ReadingFont>(
                palette: p,
                value: _font,
                options: ReadingFont.values,
                labelOf: (f) => f.label,
                onChanged: (f) {
                  setState(() => _font = f);
                  widget.onFont(f);
                },
              ),
              const SizedBox(height: PapyrTheme.space4),
              _label('Margins', p),
              _Segmented<ReadingMargin>(
                palette: p,
                value: _margin,
                options: ReadingMargin.values,
                labelOf: (m) => m.label,
                onChanged: (m) {
                  setState(() => _margin = m);
                  widget.onMargin(m);
                },
              ),
              const SizedBox(height: PapyrTheme.space4),
              _label('Warmth', p),
              _SliderRow(
                palette: p,
                icon: Icons.wb_sunny_outlined,
                value: _warmth,
                onChanged: (v) {
                  setState(() => _warmth = v);
                  widget.onWarmth(v);
                },
              ),
              const SizedBox(height: PapyrTheme.space4),
              Row(
                children: [
                  Expanded(child: _label('Brightness', p)),
                  _AutoChip(
                    palette: p,
                    active: _brightness == null,
                    onTap: () {
                      setState(() => _brightness = null);
                      widget.onBrightness(null);
                    },
                  ),
                ],
              ),
              _SliderRow(
                palette: p,
                icon: Icons.brightness_6_outlined,
                value: _brightness ?? 0.5,
                dimmed: _brightness == null,
                onChanged: (v) {
                  setState(() => _brightness = v);
                  widget.onBrightness(v);
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
      ),
    );
  }

  Widget _grabber(PaperPalette p) => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: p.inkFaint,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _label(String text, PaperPalette p) => Padding(
        padding: const EdgeInsets.only(bottom: PapyrTheme.space2),
        child: Text(text,
            style: PapyrTheme.ui(p.inkSecondary, size: 12, weight: FontWeight.w600)),
      );
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.palette,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final PaperPalette palette;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.page,
        borderRadius: BorderRadius.circular(PapyrTheme.radiusMd),
        border: Border.all(color: palette.divider),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: PapyrTheme.space3),
                  decoration: BoxDecoration(
                    color: o == value ? palette.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(PapyrTheme.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      labelOf(o),
                      style: PapyrTheme.ui(
                        o == value ? palette.onAccent : palette.inkSecondary,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.palette,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.dimmed = false,
  });

  final PaperPalette palette;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: dimmed ? palette.inkFaint : palette.inkSecondary),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: dimmed ? palette.inkFaint : palette.accent,
              inactiveTrackColor: palette.divider,
              thumbColor: dimmed ? palette.inkFaint : palette.accent,
              overlayColor: palette.accent.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(value: value.clamp(0.0, 1.0), onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

class _AutoChip extends StatelessWidget {
  const _AutoChip({required this.palette, required this.active, required this.onTap});

  final PaperPalette palette;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: PapyrTheme.space3, vertical: 4),
        decoration: BoxDecoration(
          color: active ? palette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(PapyrTheme.radiusLg),
          border: Border.all(color: active ? palette.accent : palette.divider),
        ),
        child: Text('Auto',
            style: PapyrTheme.ui(active ? palette.onAccent : palette.inkSecondary,
                size: 11, weight: FontWeight.w600)),
      ),
    );
  }
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
        icon: Icon(icon, color: enabled ? palette.inkPrimary : palette.inkFaint),
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
                child: Text('A', style: PapyrTheme.title(palette.inkPrimary, size: 16)),
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

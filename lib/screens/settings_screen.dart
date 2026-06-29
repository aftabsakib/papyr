import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// App settings: default paper, default reading typography, and an about note.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.themeController,
    required this.settings,
  });

  final ThemeController themeController;
  final SettingsStore settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _fontScale = widget.settings.fontScale;
  late double _lineHeight = widget.settings.lineHeight;

  @override
  Widget build(BuildContext context) {
    final p = widget.themeController.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(PapyrTheme.space5),
        children: [
          _sectionTitle('Paper', p),
          const SizedBox(height: PapyrTheme.space3),
          Row(
            children: [
              for (final palette in PaperPalette.all)
                Expanded(
                  child: _PaperSwatch(
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
          const SizedBox(height: PapyrTheme.space6),
          _sectionTitle('Reading defaults', p),
          const SizedBox(height: PapyrTheme.space2),
          Text(
            'Applied to EPUB books. You can still adjust each book while reading.',
            style: PapyrTheme.ui(p.inkSecondary, size: 12),
          ),
          const SizedBox(height: PapyrTheme.space3),
          _StepperRow(
            palette: p,
            label: 'Text size',
            valueText: '${(_fontScale * 100).round()}%',
            onMinus: _fontScale > 0.7 ? () => _setFont(_fontScale - 0.1) : null,
            onPlus: _fontScale < 2.2 ? () => _setFont(_fontScale + 0.1) : null,
          ),
          const SizedBox(height: PapyrTheme.space3),
          _StepperRow(
            palette: p,
            label: 'Line spacing',
            valueText: _lineHeight.toStringAsFixed(1),
            onMinus: _lineHeight > 1.2 ? () => _setLine(_lineHeight - 0.1) : null,
            onPlus: _lineHeight < 2.4 ? () => _setLine(_lineHeight + 0.1) : null,
          ),
          const SizedBox(height: PapyrTheme.space7),
          _sectionTitle('About', p),
          const SizedBox(height: PapyrTheme.space3),
          Text('Papyr', style: PapyrTheme.title(p.inkPrimary, size: 22)),
          const SizedBox(height: PapyrTheme.space1),
          Text(
            'A calm, paper-like reader for your PDF and EPUB library.\n'
            'Everything stays on your device — no accounts, no cloud.',
            style: PapyrTheme.reading(p.inkSecondary, size: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _setFont(double v) {
    final clamped = double.parse(v.clamp(0.7, 2.2).toStringAsFixed(2));
    setState(() => _fontScale = clamped);
    widget.settings.setFontScale(clamped);
  }

  void _setLine(double v) {
    final clamped = double.parse(v.clamp(1.2, 2.4).toStringAsFixed(2));
    setState(() => _lineHeight = clamped);
    widget.settings.setLineHeight(clamped);
  }

  Widget _sectionTitle(String text, PaperPalette p) => Text(
        text.toUpperCase(),
        style: PapyrTheme.ui(p.inkSecondary, size: 12, weight: FontWeight.w700),
      );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.palette,
    required this.label,
    required this.valueText,
    required this.onMinus,
    required this.onPlus,
  });

  final PaperPalette palette;
  final String label;
  final String valueText;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: PapyrTheme.ui(palette.inkPrimary, size: 15, weight: FontWeight.w600)),
        ),
        IconButton(
          icon: Icon(Icons.remove, color: onMinus != null ? palette.inkPrimary : palette.inkFaint),
          onPressed: onMinus,
        ),
        SizedBox(
          width: 56,
          child: Text(
            valueText,
            textAlign: TextAlign.center,
            style: PapyrTheme.ui(palette.inkPrimary, size: 14, weight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: onPlus != null ? palette.inkPrimary : palette.inkFaint),
          onPressed: onPlus,
        ),
      ],
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
              duration: const Duration(milliseconds: 160),
              height: 64,
              decoration: BoxDecoration(
                color: palette.page,
                borderRadius: BorderRadius.circular(PapyrTheme.radiusMd),
                border: Border.all(
                  color: selected ? active.accent : palette.divider,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Center(
                child: Text('Aa', style: PapyrTheme.title(palette.inkPrimary, size: 18)),
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

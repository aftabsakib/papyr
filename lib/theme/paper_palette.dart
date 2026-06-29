import 'package:flutter/material.dart';

/// The four reading "papers" the user can switch between.
///
/// Each paper drives the colour of the *entire* app, not just the reading
/// screen — the library, settings, and chrome all adopt the selected paper so
/// the whole experience feels like one continuous sheet of paper.
enum PaperTheme {
  cream,
  sepia,
  eink,
  night;

  String get label => switch (this) {
        PaperTheme.cream => 'Cream',
        PaperTheme.sepia => 'Sepia',
        PaperTheme.eink => 'E-ink',
        PaperTheme.night => 'Night',
      };

  PaperPalette get palette => switch (this) {
        PaperTheme.cream => PaperPalette.cream,
        PaperTheme.sepia => PaperPalette.sepia,
        PaperTheme.eink => PaperPalette.eink,
        PaperTheme.night => PaperPalette.night,
      };
}

/// A concrete set of colours for one paper.
///
/// Contrast notes (WCAG): every `inkPrimary` on `page` pair below clears 4.5:1
/// for body text; `inkSecondary` clears 3:1 for muted/large text.
@immutable
class PaperPalette {
  const PaperPalette({
    required this.theme,
    required this.page,
    required this.surface,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkFaint,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.isDark,
  });

  /// Which paper this palette belongs to.
  final PaperTheme theme;

  /// The page background — the dominant colour of the whole app.
  final Color page;

  /// Slightly distinct surface for cards/tiles resting on the page.
  final Color surface;

  /// Main reading/text colour.
  final Color inkPrimary;

  /// Muted text: metadata, captions, secondary labels.
  final Color inkSecondary;

  /// Very low-emphasis text: hints, disabled.
  final Color inkFaint;

  /// Hairline dividers and borders.
  final Color divider;

  /// Single interactive highlight colour (selection, active controls, progress).
  final Color accent;

  /// Readable text/icon colour to place on top of [accent].
  final Color onAccent;

  /// True for dark papers — drives status-bar icon brightness, etc.
  final bool isDark;

  /// A fresh paperback: warm off-white with near-black warm ink.
  static const cream = PaperPalette(
    theme: PaperTheme.cream,
    page: Color(0xFFF6F0E2),
    surface: Color(0xFFFCF8EE),
    inkPrimary: Color(0xFF2B2622),
    inkSecondary: Color(0xFF6B6258),
    inkFaint: Color(0xFF9A9080),
    divider: Color(0xFFE3D9C4),
    accent: Color(0xFF9A6A3C),
    onAccent: Color(0xFFFFFFFF),
    isDark: false,
  );

  /// Aged paper: warm tan with dark brown ink. Easy on the eyes at night.
  static const sepia = PaperPalette(
    theme: PaperTheme.sepia,
    page: Color(0xFFE7D8BC),
    surface: Color(0xFFEFE2CB),
    inkPrimary: Color(0xFF43341F),
    inkSecondary: Color(0xFF6E5C40),
    inkFaint: Color(0xFF94835F),
    divider: Color(0xFFD4C2A0),
    accent: Color(0xFF8A5A2B),
    onAccent: Color(0xFFFFFFFF),
    isDark: false,
  );

  /// Stark like a physical e-ink screen: light grey with true-black ink.
  static const eink = PaperPalette(
    theme: PaperTheme.eink,
    page: Color(0xFFEAEAE7),
    surface: Color(0xFFF4F4F1),
    inkPrimary: Color(0xFF111111),
    inkSecondary: Color(0xFF4F4F4F),
    inkFaint: Color(0xFF8A8A8A),
    divider: Color(0xFFCFCFCB),
    accent: Color(0xFF2E2E2E),
    onAccent: Color(0xFFFFFFFF),
    isDark: false,
  );

  /// Dark-room reading: near-black warm page with soft warm-grey ink.
  static const night = PaperPalette(
    theme: PaperTheme.night,
    page: Color(0xFF14120E),
    surface: Color(0xFF1E1B16),
    inkPrimary: Color(0xFFCDC6B7),
    inkSecondary: Color(0xFF918A7C),
    inkFaint: Color(0xFF615C51),
    divider: Color(0xFF2C2820),
    accent: Color(0xFFC79A5E),
    onAccent: Color(0xFF14120E),
    isDark: true,
  );

  static const all = [cream, sepia, eink, night];
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'paper_palette.dart';

/// Design tokens + theme construction for Papyr.
///
/// One [PaperPalette] produces one cohesive [ThemeData] so the whole app —
/// library, settings, and reader — shares the selected paper's colours.
class PapyrTheme {
  PapyrTheme._();

  // ---- Spacing (4 / 8 rhythm) -------------------------------------------
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 48;

  // ---- Corner radii ------------------------------------------------------
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 18;

  // ---- Typography --------------------------------------------------------
  // Reading text: a serif designed for on-screen body copy.
  static TextStyle reading(Color color, {double size = 19, double height = 1.6}) =>
      GoogleFonts.sourceSerif4(
        color: color,
        fontSize: size,
        height: height,
        fontWeight: FontWeight.w400,
      );

  // Book + screen titles: an elegant, bookish display face.
  static TextStyle title(Color color, {double size = 22}) =>
      GoogleFonts.playfairDisplay(
        color: color,
        fontSize: size,
        height: 1.2,
        fontWeight: FontWeight.w700,
      );

  // UI chrome: a quiet sans that stays out of the way.
  static TextStyle ui(Color color,
          {double size = 14, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(
        color: color,
        fontSize: size,
        height: 1.4,
        fontWeight: weight,
      );

  /// Build a full [ThemeData] from a paper palette.
  static ThemeData build(PaperPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.inkPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.page,
      canvasColor: p.page,
      dividerColor: p.divider,
      splashColor: p.accent.withValues(alpha: 0.10),
      highlightColor: p.accent.withValues(alpha: 0.06),
      textTheme: TextTheme(
        titleLarge: title(p.inkPrimary, size: 22),
        titleMedium: ui(p.inkPrimary, size: 16, weight: FontWeight.w600),
        bodyLarge: reading(p.inkPrimary),
        bodyMedium: ui(p.inkSecondary, size: 14),
        labelLarge: ui(p.inkPrimary, size: 14, weight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.page,
        foregroundColor: p.inkPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: title(p.inkPrimary, size: 20),
      ),
      iconTheme: IconThemeData(color: p.inkSecondary),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      // Quiet, paper-friendly Material defaults.
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    );
  }
}

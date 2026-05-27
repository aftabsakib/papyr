import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BedBreakerTheme {
  static const _bgPrimary = Color(0xFF0D0D0D);
  static const _bgSurface = Color(0xFF1A1A1A);
  static const _bgSurface2 = Color(0xFF242424);
  static const _accent = Color(0xFF3D8EFF);
  static const _accentGlow = Color(0xFF5CA3FF);
  static const _danger = Color(0xFFFF4444);
  static const _success = Color(0xFF00E676);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFF8A8A8A);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: _accent,
        secondary: _accentGlow,
        surface: _bgSurface,
        error: _danger,
        onPrimary: Colors.white,
        onSurface: _textPrimary,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 80, fontWeight: FontWeight.w900, color: _textPrimary, height: 1.0,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 56, fontWeight: FontWeight.w900, color: _textPrimary, height: 1.0,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32, fontWeight: FontWeight.w800, color: _textPrimary,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24, fontWeight: FontWeight.w700, color: _textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16, fontWeight: FontWeight.w400, color: _textPrimary,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14, fontWeight: FontWeight.w400, color: _textSecondary,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary, letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: _bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _bgPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 24, fontWeight: FontWeight.w900, color: _textPrimary,
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? _accent : _textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? _accent.withValues(alpha: 0.3)
                : _bgSurface2),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _bgSurface2,
        labelStyle: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }

  // Expose constants for direct use in widgets
  static const bgPrimary = _bgPrimary;
  static const bgSurface = _bgSurface;
  static const bgSurface2 = _bgSurface2;
  static const accent = _accent;
  static const accentGlow = _accentGlow;
  static const danger = _danger;
  static const success = _success;
  static const textSecondary = _textSecondary;
  static const textPrimary = _textPrimary;
  static const onSuccess = Colors.black;
  static const transparent = Colors.transparent;
}

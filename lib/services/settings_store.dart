import 'package:hive/hive.dart';

import '../theme/paper_palette.dart';

/// Lightweight, Hive-backed key/value store for app-wide settings.
///
/// Reading-time preferences (font scale, line spacing, margins) and the
/// selected paper live here so they survive restarts. Kept deliberately simple:
/// primitive values in a single box, no generated adapters needed.
class SettingsStore {
  SettingsStore(this._box);

  static const _boxName = 'papyr_settings';

  static const _kPaper = 'paper_theme';
  static const _kFontScale = 'reading_font_scale';
  static const _kLineHeight = 'reading_line_height';
  static const _kOnboarded = 'onboarding_done';
  static const _kPdfReflow = 'pdf_reflow_mode';

  final Box _box;

  /// Opens (or creates) the settings box. Call after `Hive.initFlutter()`.
  static Future<SettingsStore> open() async {
    final box = await Hive.openBox(_boxName);
    return SettingsStore(box);
  }

  // ---- Selected paper ----------------------------------------------------
  PaperTheme get paper {
    final name = _box.get(_kPaper) as String?;
    return PaperTheme.values.firstWhere(
      (t) => t.name == name,
      orElse: () => PaperTheme.cream,
    );
  }

  Future<void> setPaper(PaperTheme t) => _box.put(_kPaper, t.name);

  // ---- Reading typography (used by the EPUB reader) ----------------------
  /// Relative font size multiplier for reflowable text. 1.0 == default.
  double get fontScale => (_box.get(_kFontScale) as num?)?.toDouble() ?? 1.0;
  Future<void> setFontScale(double v) =>
      _box.put(_kFontScale, v.clamp(0.7, 2.2));

  /// Line-height multiplier for reflowable text.
  double get lineHeight => (_box.get(_kLineHeight) as num?)?.toDouble() ?? 1.6;
  Future<void> setLineHeight(double v) =>
      _box.put(_kLineHeight, v.clamp(1.2, 2.4));

  // ---- First-run onboarding ---------------------------------------------
  bool get onboardingDone => _box.get(_kOnboarded, defaultValue: false) as bool;
  Future<void> setOnboardingDone() => _box.put(_kOnboarded, true);

  // ---- PDF reading mode --------------------------------------------------
  /// When true, text-based PDFs open in the reflowed "Reading view" (ebook
  /// style) rather than the fixed "Page view".
  bool get pdfReflowMode => _box.get(_kPdfReflow, defaultValue: false) as bool;
  Future<void> setPdfReflowMode(bool v) => _box.put(_kPdfReflow, v);
}

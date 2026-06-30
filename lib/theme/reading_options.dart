// Reader typography and layout options shared by the PDF reflow view and the
// EPUB reader.

enum ReadingFont {
  serif,
  sans,
  dyslexic;

  String get label => switch (this) {
        ReadingFont.serif => 'Serif',
        ReadingFont.sans => 'Sans',
        ReadingFont.dyslexic => 'Dyslexic',
      };

  /// CSS font stack for the EPUB web view.
  String get cssFamily => switch (this) {
        ReadingFont.serif => '"Georgia", "Times New Roman", serif',
        ReadingFont.sans =>
          'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif',
        ReadingFont.dyslexic => '"OpenDyslexic", sans-serif',
      };
}

enum ReadingMargin {
  narrow,
  normal,
  wide;

  String get label => switch (this) {
        ReadingMargin.narrow => 'Narrow',
        ReadingMargin.normal => 'Normal',
        ReadingMargin.wide => 'Wide',
      };

  /// Horizontal padding (logical px) for the native PDF reflow view.
  double get horizontal => switch (this) {
        ReadingMargin.narrow => 12,
        ReadingMargin.normal => 24,
        ReadingMargin.wide => 44,
      };

  /// Horizontal margin (CSS px) for the EPUB web view.
  int get cssMargin => switch (this) {
        ReadingMargin.narrow => 12,
        ReadingMargin.normal => 28,
        ReadingMargin.wide => 56,
      };
}

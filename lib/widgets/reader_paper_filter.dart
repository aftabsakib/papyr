import 'package:flutter/widgets.dart';

import '../theme/paper_palette.dart';

/// Builds the [ColorFilter] that tints a white-rendered PDF to match the
/// selected paper.
///
/// - Light papers (Cream / Sepia / E-ink): multiply by the page colour, so a
///   white page becomes the paper colour while dark text stays dark.
/// - Night: invert luminance, turning the white page near-black and the text
///   light, for comfortable dark-room reading.
class ReaderPaperFilter {
  ReaderPaperFilter._();

  static ColorFilter forPalette(PaperPalette p) {
    if (p.isDark) return _invert;
    return ColorFilter.mode(p.page, BlendMode.multiply);
  }

  static const ColorFilter _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);
}

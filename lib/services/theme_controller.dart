import 'package:flutter/material.dart';

import '../theme/paper_palette.dart';
import 'settings_store.dart';

/// Holds the currently-selected paper and notifies listeners when it changes,
/// persisting the choice through [SettingsStore].
///
/// The app's root [MaterialApp] listens to this so switching papers re-themes
/// every screen instantly.
class ThemeController extends ChangeNotifier {
  ThemeController(this._settings) : _paper = _settings.paper;

  final SettingsStore _settings;
  PaperTheme _paper;

  PaperTheme get paper => _paper;
  PaperPalette get palette => _paper.palette;

  Future<void> setPaper(PaperTheme paper) async {
    if (paper == _paper) return;
    _paper = paper;
    notifyListeners();
    await _settings.setPaper(paper);
  }
}

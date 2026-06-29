import 'package:flutter/material.dart';

import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import 'library_screen.dart';
import 'onboarding_screen.dart';

/// Decides between the first-launch welcome and the library.
class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    required this.themeController,
    required this.settings,
    required this.library,
  });

  final ThemeController themeController;
  final SettingsStore settings;
  final LibraryStore library;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late bool _showOnboarding = !widget.settings.onboardingDone;

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        themeController: widget.themeController,
        onDone: () {
          widget.settings.setOnboardingDone();
          setState(() => _showOnboarding = false);
        },
      );
    }
    return LibraryScreen(
      themeController: widget.themeController,
      settings: widget.settings,
      library: widget.library,
    );
  }
}

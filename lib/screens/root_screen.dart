import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/book_importer.dart';
import '../services/library_store.dart';
import '../services/settings_store.dart';
import '../services/theme_controller.dart';
import 'library_screen.dart';
import 'onboarding_screen.dart';
import 'reader_router.dart';

/// Decides between the first-launch welcome and the library, and handles books
/// opened from other apps ("Open with Papyr" / share sheet) via a native
/// MethodChannel.
class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    required this.themeController,
    required this.settings,
    required this.library,
    required this.navigatorKey,
  });

  final ThemeController themeController;
  final SettingsStore settings;
  final LibraryStore library;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  static const _channel = MethodChannel('papyr/intent');

  late bool _showOnboarding = !widget.settings.onboardingDone;
  bool _handlingShared = false;

  @override
  void initState() {
    super.initState();
    // Files opened while the app is already running.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFile' && call.arguments is String) {
        await _handleFile(call.arguments as String);
      }
      return null;
    });
    // A file that launched the app cold.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final path = await _channel.invokeMethod<String>('getInitialFile');
      if (path != null) await _handleFile(path);
    });
  }

  Future<void> _handleFile(String path) async {
    if (_handlingShared) return;
    _handlingShared = true;
    try {
      if (_showOnboarding) {
        await widget.settings.setOnboardingDone();
        if (mounted) setState(() => _showOnboarding = false);
      }
      final book = await BookImporter(widget.library).importPath(path);
      final navContext = widget.navigatorKey.currentContext;
      if (book != null && navContext != null && navContext.mounted) {
        await ReaderRouter.open(
          navContext,
          book: book,
          library: widget.library,
          settings: widget.settings,
          themeController: widget.themeController,
        );
      }
    } finally {
      _handlingShared = false;
    }
  }

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

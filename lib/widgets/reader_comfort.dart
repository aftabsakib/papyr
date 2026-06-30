import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Shared reader behaviours: keep the screen awake, go full-immersion (hide the
/// system bars), and optionally override screen brightness — all restored when
/// the reader closes.
mixin ReaderComfort<T extends StatefulWidget> on State<T> {
  final ScreenBrightness _brightness = ScreenBrightness();
  bool _brightnessApplied = false;

  void enterReaderComfort({double? brightness}) {
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (brightness != null) applyBrightness(brightness);
  }

  void exitReaderComfort() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values);
    if (_brightnessApplied) {
      _brightness.resetApplicationScreenBrightness();
      _brightnessApplied = false;
    }
  }

  Future<void> applyBrightness(double value) async {
    try {
      await _brightness.setApplicationScreenBrightness(value);
      _brightnessApplied = true;
    } catch (_) {
      // Some devices/emulators don't support app brightness override.
    }
  }

  Future<void> resetBrightness() async {
    if (!_brightnessApplied) return;
    try {
      await _brightness.resetApplicationScreenBrightness();
    } catch (_) {}
    _brightnessApplied = false;
  }
}

/// A warm amber wash placed over reading content for low-light comfort.
/// Add as a [Stack] child above the page and below the chrome.
class WarmthOverlay extends StatelessWidget {
  const WarmthOverlay(this.warmth, {super.key});

  final double warmth; // 0.0–1.0

  @override
  Widget build(BuildContext context) {
    if (warmth <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: const Color(0xFFFF7A00).withValues(alpha: warmth * 0.35),
        ),
      ),
    );
  }
}

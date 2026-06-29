import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';

/// A calm one-screen welcome shown on first launch.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.themeController,
    required this.onDone,
  });

  final ThemeController themeController;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final p = themeController.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PapyrTheme.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text('Papyr', style: PapyrTheme.title(p.inkPrimary, size: 44)),
              const SizedBox(height: PapyrTheme.space3),
              Text(
                'A calm, paper-like reader for your\nown PDFs and ebooks.',
                style: PapyrTheme.reading(p.inkSecondary, size: 18, height: 1.5),
              ),
              const SizedBox(height: PapyrTheme.space7),
              _Point(
                palette: p,
                icon: Icons.file_open_outlined,
                title: 'Bring your own books',
                body: 'Import PDFs and EPUBs from your device.',
              ),
              _Point(
                palette: p,
                icon: Icons.contrast_outlined,
                title: 'Read on paper',
                body: 'Cream, sepia, e-ink, or night — your choice.',
              ),
              _Point(
                palette: p,
                icon: Icons.lock_outline,
                title: 'Entirely yours',
                body: 'No accounts, no cloud. Everything stays on this device.',
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: p.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: PapyrTheme.space4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PapyrTheme.radiusMd),
                    ),
                  ),
                  child: Text('Get started',
                      style: PapyrTheme.ui(p.onAccent, size: 16, weight: FontWeight.w600)),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.palette,
    required this.icon,
    required this.title,
    required this.body,
  });

  final PaperPalette palette;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PapyrTheme.space5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.accent, size: 24),
          const SizedBox(width: PapyrTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: PapyrTheme.ui(palette.inkPrimary, size: 16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body,
                    style: PapyrTheme.reading(palette.inkSecondary, size: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

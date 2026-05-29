import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/alarm_scheduler.dart';
import '../theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _locationGranted = false;
  bool _cameraGranted = false;
  bool _notificationGranted = false;
  bool _requesting = false;

  Future<void> _requestAll() async {
    setState(() => _requesting = true);

    final location = await Permission.locationAlways.request();
    final camera = await Permission.camera.request();
    final notification = await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
    // Full-screen intent: required on Android 14+ for the alarm to pop up on
    // the lock screen. No-op on older versions (auto-granted there).
    await AlarmScheduler.requestFullScreenIntentPermission();
    // Exact alarm permission is handled by the HomeScreen banner using the
    // correct flutter_local_notifications API (permission_handler has a bug).

    final allGranted = location.isGranted && camera.isGranted && notification.isGranted;

    if (mounted) {
      setState(() {
        _locationGranted = location.isGranted;
        _cameraGranted = camera.isGranted;
        _notificationGranted = notification.isGranted;
        _requesting = false;
      });

      if (allGranted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BedBreakerTheme.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'BedBreaker\nneeds 3 things.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: BedBreakerTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Without these, the alarm cannot work.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: BedBreakerTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              _PermissionRow(
                icon: Icons.location_on_rounded,
                title: 'Location — always on',
                subtitle: 'Tracks when you reach your mission target',
                granted: _locationGranted,
              ),
              const SizedBox(height: 12),
              _PermissionRow(
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Takes proof photo at your destination',
                granted: _cameraGranted,
              ),
              const SizedBox(height: 12),
              _PermissionRow(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Rings the alarm',
                granted: _notificationGranted,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _requesting ? null : _requestAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: BedBreakerTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: BedBreakerTheme.textPrimary),
                        )
                      : Text(
                          'Grant Permissions',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: BedBreakerTheme.textPrimary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BedBreakerTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted
              ? BedBreakerTheme.success.withValues(alpha: 0.3)
              : BedBreakerTheme.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: granted
                  ? BedBreakerTheme.success.withValues(alpha: 0.12)
                  : BedBreakerTheme.bgSurface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: granted ? BedBreakerTheme.success : BedBreakerTheme.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BedBreakerTheme.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, color: BedBreakerTheme.textSecondary)),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: granted ? BedBreakerTheme.success : BedBreakerTheme.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

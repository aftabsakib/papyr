import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';
import '../storage/alarm_storage.dart';
import '../theme.dart';
import '../widgets/home_alarm_list.dart';
import 'create_alarm_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _storage = AlarmStorage();
  bool _loaded = false;
  bool _exactAlarmGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from the "Alarms & reminders" settings screen,
    // re-check permission and reschedule alarms if it was just granted.
    if (state == AppLifecycleState.resumed) _recheckAlarmPermission();
  }

  Future<void> _recheckAlarmPermission() async {
    if (!Platform.isAndroid) return;
    final granted = await Permission.scheduleExactAlarm.isGranted;
    if (!mounted) return;
    final wasGranted = _exactAlarmGranted;
    setState(() => _exactAlarmGranted = granted);
    if (granted && !wasGranted) {
      // Permission just granted — reschedule everything
      for (final alarm in _storage.getAllAlarms()) {
        if (!alarm.isActive) continue;
        final next = AlarmScheduler.nextFireTime(alarm);
        if (next != null) {
          try { await AlarmScheduler.scheduleAlarm(alarm); } catch (_) {}
        }
      }
    }
  }

  Future<void> _init() async {
    await _storage.init();
    // Show UI immediately — never block on platform calls
    if (mounted) setState(() => _loaded = true);

    if (Platform.isAndroid) {
      final granted = await Permission.scheduleExactAlarm.isGranted;
      if (mounted) setState(() => _exactAlarmGranted = granted);
      if (!granted) {
        // Opens "Alarms & reminders" settings on Android 12;
        // no-op on Android 13+ where USE_EXACT_ALARM is auto-granted.
        await Permission.scheduleExactAlarm.request();
        final recheck = await Permission.scheduleExactAlarm.isGranted;
        if (mounted) setState(() => _exactAlarmGranted = recheck);
      }
    }

    for (final alarm in _storage.getAllAlarms()) {
      if (!alarm.isActive) continue;
      final next = AlarmScheduler.nextFireTime(alarm);
      if (next == null) {
        alarm.isActive = false;
        await alarm.save();
        if (mounted) setState(() {});
      } else {
        try {
          await AlarmScheduler.scheduleAlarm(alarm);
        } catch (_) {}
      }
    }
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    alarm.isActive = !alarm.isActive;
    await alarm.save();
    if (alarm.isActive) {
      try { await AlarmScheduler.scheduleAlarm(alarm); } catch (_) {}
    } else {
      await AlarmScheduler.cancelAlarm(alarm);
    }
    setState(() {});
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    await AlarmScheduler.cancelAlarm(alarm);
    await _storage.deleteAlarm(alarm.id);
    setState(() {});
  }

  Future<void> _fixAlarmPermission() async {
    if (!mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BedBreakerTheme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Allow Alarm Permission',
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w900, color: BedBreakerTheme.textPrimary),
        ),
        content: Text(
          'Open Settings, find BedBreaker, tap "Alarms & reminders", and toggle it ON.',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 14, color: BedBreakerTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.spaceGrotesk(
                    color: BedBreakerTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Open Settings',
                style: GoogleFonts.spaceGrotesk(
                    color: BedBreakerTheme.accent,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (open == true) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: BedBreakerTheme.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: BedBreakerTheme.accent)),
      );
    }

    final alarms = _storage.getAllAlarms()
      ..sort((a, b) {
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });
    final streak = _storage.getCurrentStreak();
    final cheats = _storage.getTotalCheats();

    return Scaffold(
      backgroundColor: BedBreakerTheme.bgPrimary,
      appBar: AppBar(
        title: Text(
          'BedBreaker',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: BedBreakerTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_exactAlarmGranted)
            _AlarmPermissionBanner(onFix: _fixAlarmPermission),
          HomeStatsBar(streak: streak, cheats: cheats),
          Expanded(
            child: alarms.isEmpty
                ? const EmptyAlarmsView()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: alarms.length,
                    itemBuilder: (context, i) => AlarmCard(
                      alarm: alarms[i],
                      onToggle: () => _toggleAlarm(alarms[i]),
                      onDelete: () => _deleteAlarm(alarms[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAlarmScreen()),
        ).then((_) => setState(() {})),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Alarm',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _AlarmPermissionBanner extends StatelessWidget {
  final VoidCallback onFix;
  const _AlarmPermissionBanner({required this.onFix});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFix,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        color: BedBreakerTheme.danger.withValues(alpha: 0.18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: BedBreakerTheme.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alarms won\'t ring — tap here to fix',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: BedBreakerTheme.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BedBreakerTheme.danger,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'FIX',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

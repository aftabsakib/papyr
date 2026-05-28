import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // User returned from the system Alarms & reminders settings page.
    if (state == AppLifecycleState.resumed) _recheckAlarmPermission();
  }

  Future<void> _recheckAlarmPermission() async {
    final granted = await AlarmScheduler.canScheduleExactAlarms();
    if (!mounted) return;
    final wasGranted = _exactAlarmGranted;
    setState(() => _exactAlarmGranted = granted);
    if (granted && !wasGranted) {
      // Just got permission — reschedule all active alarms now.
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
    if (mounted) setState(() => _loaded = true);

    // Check using AlarmManager.canScheduleExactAlarms() via flutter_local_notifications.
    // permission_handler v11 has a confirmed bug for scheduleExactAlarm — don't use it.
    final granted = await AlarmScheduler.canScheduleExactAlarms();
    if (mounted) setState(() => _exactAlarmGranted = granted);

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
    // requestExactAlarmsPermission() launches Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM
    // directly — the correct Alarms & reminders page for Android 12+.
    await AlarmScheduler.requestExactAlarmPermission();
    // didChangeAppLifecycleState will handle rechecking when user returns.
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
          if (!_exactAlarmGranted) _buildPermissionBanner(),
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

  Widget _buildPermissionBanner() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _fixAlarmPermission,
        icon: const Icon(Icons.warning_amber_rounded, size: 18),
        label: Text(
          'Alarms won\'t ring — tap to grant permission',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: BedBreakerTheme.danger,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

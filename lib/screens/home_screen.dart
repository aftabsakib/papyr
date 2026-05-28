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

class _HomeScreenState extends State<HomeScreen> {
  final _storage = AlarmStorage();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _storage.init();
    // Show UI immediately — never block on platform calls
    if (mounted) setState(() => _loaded = true);
    // Reschedule active alarms in the background
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
      await AlarmScheduler.scheduleAlarm(alarm);
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

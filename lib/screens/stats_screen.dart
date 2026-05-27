import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../storage/alarm_storage.dart';
import '../theme.dart';
import '../widgets/stats_ui.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _storage = AlarmStorage();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _storage.init().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: BedBreakerTheme.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: BedBreakerTheme.accent)),
      );
    }

    final history = _storage.getAllHistory()
      ..sort((a, b) => b.firedAt.compareTo(a.firedAt));
    final streak = _storage.getCurrentStreak();
    final cheats = _storage.getTotalCheats();
    final total = history.length;
    final completed = history.where((h) => h.status.name == 'completed').length;
    final rate = total == 0 ? 0 : (completed / total * 100).round();

    return Scaffold(
      backgroundColor: BedBreakerTheme.bgPrimary,
      appBar: AppBar(
        title: Text('Stats',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        children: [
          StatsHeader(
            streak: streak,
            totalCheats: cheats,
            completionRate: rate,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'HISTORY',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: BedBreakerTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          HistoryList(history: history),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

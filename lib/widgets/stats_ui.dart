import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/alarm_history.dart';
import '../theme.dart';

class StatsHeader extends StatelessWidget {
  final int streak;
  final int totalCheats;
  final int completionRate;

  const StatsHeader({
    super.key,
    required this.streak,
    required this.totalCheats,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main streak display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BedBreakerTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: streak > 0
                    ? BedBreakerTheme.accent.withValues(alpha:0.3)
                    : BedBreakerTheme.bgSurface2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Streak',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: BedBreakerTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$streak',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: streak > 0 ? BedBreakerTheme.accent : BedBreakerTheme.textSecondary,
                              height: 1.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 6),
                            child: Text(
                              streak == 1 ? 'day' : 'days',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: BedBreakerTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _CompletionRing(rate: completionRate),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: 'Completion',
                  value: '$completionRate%',
                  color: BedBreakerTheme.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: 'Cheats',
                  value: '$totalCheats',
                  color: totalCheats == 0 ? BedBreakerTheme.textSecondary : BedBreakerTheme.danger,
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  final int rate;

  const _CompletionRing({required this.rate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: rate / 100,
            strokeWidth: 6,
            backgroundColor: BedBreakerTheme.bgSurface2,
            color: rate >= 80
                ? BedBreakerTheme.success
                : rate >= 50
                    ? BedBreakerTheme.accent
                    : BedBreakerTheme.danger,
            strokeCap: StrokeCap.round,
          ),
          Text(
            '$rate%',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: BedBreakerTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BedBreakerTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.0,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: BedBreakerTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  final List<AlarmHistory> history;

  const HistoryList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No history yet.\nComplete your first mission.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: BedBreakerTheme.textSecondary.withValues(alpha:0.5),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, i) => HistoryTile(history: history[i]),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final AlarmHistory history;

  const HistoryTile({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final isCompleted = history.status == AlarmStatus.completed;
    final isCheated = history.status == AlarmStatus.cheated;
    final color = isCompleted
        ? BedBreakerTheme.success
        : isCheated
            ? BedBreakerTheme.danger
            : BedBreakerTheme.textSecondary;
    final icon = isCompleted
        ? Icons.check_circle_rounded
        : isCheated
            ? Icons.cancel_rounded
            : Icons.radio_button_unchecked;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BedBreakerTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d · HH:mm').format(history.firedAt),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BedBreakerTheme.textPrimary,
                  ),
                ),
                Text(
                  isCompleted && history.secondsToComplete != null
                      ? 'Mission complete in ${_formatDuration(history.secondsToComplete!)}'
                      : isCheated
                          ? 'Force stopped'
                          : 'Missed',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: BedBreakerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: BedBreakerTheme.success.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: BedBreakerTheme.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}

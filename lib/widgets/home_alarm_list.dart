import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm.dart';
import '../theme.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: BedBreakerTheme.danger.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BedBreakerTheme.danger.withValues(alpha:0.4)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: BedBreakerTheme.danger, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: BedBreakerTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alarm.isActive
                ? BedBreakerTheme.accent.withValues(alpha:0.25)
                : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.timeString,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: alarm.isActive ? Colors.white : BedBreakerTheme.textSecondary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alarm.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: BedBreakerTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RepeatDaysRow(repeatDays: alarm.repeatDays, isActive: alarm.isActive),
                    const SizedBox(height: 8),
                    _MissionBadge(missionType: alarm.missionType, radiusMeters: alarm.radiusMeters),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: alarm.isActive,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepeatDaysRow extends StatelessWidget {
  final List<bool> repeatDays;
  final bool isActive;

  const _RepeatDaysRow({required this.repeatDays, required this.isActive});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: List.generate(7, (i) {
        final active = repeatDays[i];
        return Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: active && isActive
                ? BedBreakerTheme.accent.withValues(alpha:0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active && isActive
                  ? BedBreakerTheme.accent
                  : BedBreakerTheme.bgSurface2,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              labels[i],
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active && isActive ? BedBreakerTheme.accent : BedBreakerTheme.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MissionBadge extends StatelessWidget {
  final MissionType missionType;
  final double radiusMeters;

  const _MissionBadge({required this.missionType, required this.radiusMeters});

  @override
  Widget build(BuildContext context) {
    final isDistance = missionType == MissionType.distance;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDistance ? Icons.directions_walk : Icons.pin_drop,
          size: 12,
          color: BedBreakerTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          isDistance ? '${radiusMeters.round()}m from home' : 'Go to pinned location',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: BedBreakerTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class HomeStatsBar extends StatelessWidget {
  final int streak;
  final int cheats;

  const HomeStatsBar({super.key, required this.streak, required this.cheats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _StatChip(
            label: streak == 0 ? 'No streak yet' : '$streak day streak',
            color: BedBreakerTheme.accent,
          ),
          const SizedBox(width: 8),
          if (cheats > 0)
            _StatChip(
              label: '$cheats cheat${cheats == 1 ? '' : 's'}',
              color: BedBreakerTheme.danger,
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class EmptyAlarmsView extends StatelessWidget {
  const EmptyAlarmsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_off, size: 64, color: BedBreakerTheme.textSecondary.withValues(alpha:0.3)),
          const SizedBox(height: 16),
          Text(
            'No alarms yet.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BedBreakerTheme.textSecondary.withValues(alpha:0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to break your first bed.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: BedBreakerTheme.textSecondary.withValues(alpha:0.35),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class BigTimePicker extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const BigTimePicker({super.key, required this.time, required this.onTap});

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        decoration: BoxDecoration(
          color: BedBreakerTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BedBreakerTheme.accent.withValues(alpha:0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _pad(time.hour),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: BedBreakerTheme.textPrimary,
                height: 1.0,
              ),
            ),
            Text(
              ':',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: BedBreakerTheme.accent,
                height: 1.0,
              ),
            ),
            Text(
              _pad(time.minute),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: BedBreakerTheme.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.edit_rounded, color: BedBreakerTheme.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class RepeatDaysSelector extends StatelessWidget {
  final List<bool> repeatDays;
  final ValueChanged<int> onToggle;

  const RepeatDaysSelector({
    super.key,
    required this.repeatDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPEAT',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: BedBreakerTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final selected = repeatDays[i];
            return GestureDetector(
              onTap: () => onToggle(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? BedBreakerTheme.accent
                      : BedBreakerTheme.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? BedBreakerTheme.accent
                        : BedBreakerTheme.bgSurface2,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? BedBreakerTheme.textPrimary : BedBreakerTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class MissionTypeSelector extends StatelessWidget {
  final bool isDistance;
  final double distanceMeters;
  final bool hasPinnedLocation;
  final ValueChanged<bool> onTypeChanged;
  final ValueChanged<double> onDistanceChanged;
  final VoidCallback onPinLocation;

  const MissionTypeSelector({
    super.key,
    required this.isDistance,
    required this.distanceMeters,
    required this.hasPinnedLocation,
    required this.onTypeChanged,
    required this.onDistanceChanged,
    required this.onPinLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MISSION',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: BedBreakerTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        _MissionOption(
          icon: Icons.directions_walk_rounded,
          title: 'Distance from home',
          subtitle: isDistance ? '${distanceMeters.round()}m walk required' : 'Walk away from where you sleep',
          selected: isDistance,
          onTap: () => onTypeChanged(true),
        ),
        if (isDistance) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: BedBreakerTheme.bgSurface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '100m',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: BedBreakerTheme.textSecondary),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: BedBreakerTheme.accent,
                      inactiveTrackColor: BedBreakerTheme.bgSurface,
                      thumbColor: BedBreakerTheme.accent,
                      overlayColor: BedBreakerTheme.accent.withValues(alpha:0.2),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: distanceMeters,
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      onChanged: onDistanceChanged,
                    ),
                  ),
                ),
                Text(
                  '2km',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: BedBreakerTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        _MissionOption(
          icon: Icons.pin_drop_rounded,
          title: 'Go to a location',
          subtitle: hasPinnedLocation ? 'Location pinned on map' : 'Pin a place on the map',
          selected: !isDistance,
          onTap: () {
            onTypeChanged(false);
            onPinLocation();
          },
          trailing: !isDistance
              ? GestureDetector(
                  onTap: onPinLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: BedBreakerTheme.accent.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BedBreakerTheme.accent.withValues(alpha:0.4)),
                    ),
                    child: Text(
                      hasPinnedLocation ? 'Change' : 'Set pin',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: BedBreakerTheme.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _MissionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MissionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? BedBreakerTheme.accent.withValues(alpha:0.08)
              : BedBreakerTheme.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? BedBreakerTheme.accent : BedBreakerTheme.bgSurface2,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? BedBreakerTheme.accent.withValues(alpha:0.2)
                    : BedBreakerTheme.bgSurface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? BedBreakerTheme.accent : BedBreakerTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? BedBreakerTheme.textPrimary : BedBreakerTheme.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: BedBreakerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!
            else if (selected)
              const Icon(Icons.check_circle_rounded, color: BedBreakerTheme.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class SaveAlarmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveAlarmButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: BedBreakerTheme.accent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Set Alarm',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: BedBreakerTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

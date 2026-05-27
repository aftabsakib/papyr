import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class DistanceRing extends StatelessWidget {
  final double distanceRemaining;
  final double totalDistance;
  final bool inRange;

  const DistanceRing({
    super.key,
    required this.distanceRemaining,
    required this.totalDistance,
    required this.inRange,
  });

  double get _progress {
    if (totalDistance <= 0) return 0;
    return (1 - (distanceRemaining / totalDistance)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = inRange ? BedBreakerTheme.success : BedBreakerTheme.accent;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 10,
              backgroundColor: BedBreakerTheme.bgSurface2,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inRange)
                Text(
                  "You're here!",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BedBreakerTheme.success,
                  ),
                )
              else ...[
                Text(
                  distanceRemaining > 999
                      ? '${(distanceRemaining / 1000).toStringAsFixed(1)}km'
                      : '${distanceRemaining.round()}m',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: BedBreakerTheme.textPrimary,
                    height: 1.0,
                  ),
                ),
                Text(
                  'to go',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: BedBreakerTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CameraUnlockButton extends StatefulWidget {
  final bool unlocked;
  final VoidCallback? onPressed;

  const CameraUnlockButton({
    super.key,
    required this.unlocked,
    this.onPressed,
  });

  @override
  State<CameraUnlockButton> createState() => _CameraUnlockButtonState();
}

class _CameraUnlockButtonState extends State<CameraUnlockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CameraUnlockButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unlocked && !oldWidget.unlocked) {
      _glowController.repeat(reverse: true);
    } else if (!widget.unlocked) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          decoration: widget.unlocked
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: BedBreakerTheme.success.withValues(alpha:_glow.value * 0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: child,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.unlocked ? widget.onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: widget.unlocked
                  ? BedBreakerTheme.success
                  : BedBreakerTheme.bgSurface,
              disabledBackgroundColor: BedBreakerTheme.bgSurface,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: Icon(
              widget.unlocked ? Icons.camera_alt_rounded : Icons.lock_outline,
              color: widget.unlocked ? BedBreakerTheme.onSuccess : BedBreakerTheme.textSecondary,
            ),
            label: Text(
              widget.unlocked ? 'Take Photo — Stop Alarm' : 'Get closer to unlock',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: widget.unlocked ? BedBreakerTheme.onSuccess : BedBreakerTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GpsStatusBar extends StatelessWidget {
  final bool hasSignal;
  final double? accuracy;

  const GpsStatusBar({super.key, required this.hasSignal, this.accuracy});

  @override
  Widget build(BuildContext context) {
    final accuracyText = accuracy != null ? ' ±${accuracy!.round()}m' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasSignal ? Icons.gps_fixed : Icons.gps_not_fixed,
          size: 14,
          color: hasSignal ? BedBreakerTheme.success : BedBreakerTheme.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          hasSignal ? 'GPS$accuracyText' : 'Searching...',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: hasSignal ? BedBreakerTheme.success : BedBreakerTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

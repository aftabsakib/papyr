import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PulsingTimeDisplay extends StatefulWidget {
  final String timeString;
  final String label;

  const PulsingTimeDisplay({
    super.key,
    required this.timeString,
    required this.label,
  });

  @override
  State<PulsingTimeDisplay> createState() => _PulsingTimeDisplayState();
}

class _PulsingTimeDisplayState extends State<PulsingTimeDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Column(
        children: [
          Text(
            widget.timeString,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 88,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: BedBreakerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class MissionInstructionCard extends StatelessWidget {
  final String instruction;
  final String subtitle;

  const MissionInstructionCard({
    super.key,
    required this.instruction,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BedBreakerTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BedBreakerTheme.accent.withValues(alpha:0.3)),
        boxShadow: [
          BoxShadow(
            color: BedBreakerTheme.accent.withValues(alpha:0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BedBreakerTheme.accent.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_walk, color: BedBreakerTheme.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: BedBreakerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StartMissionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StartMissionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: BedBreakerTheme.accent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: Text(
            'Start Mission',
            style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class CheatDismissButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CheatDismissButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'Force Stop — counts as a cheat',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          color: BedBreakerTheme.danger.withValues(alpha:0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class RingingGlowBackground extends StatefulWidget {
  const RingingGlowBackground({super.key});

  @override
  State<RingingGlowBackground> createState() => _RingingGlowBackgroundState();
}

class _RingingGlowBackgroundState extends State<RingingGlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.03, end: 0.09).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              BedBreakerTheme.accent.withValues(alpha:_opacity.value),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

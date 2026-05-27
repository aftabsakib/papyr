import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/alarm_history.dart';
import '../storage/alarm_storage.dart';
import '../theme.dart';
import '../widgets/ringing_screen_ui.dart';
import 'mission_active_screen.dart';

class RingingScreen extends StatelessWidget {
  final Alarm alarm;
  const RingingScreen({super.key, required this.alarm});

  Future<void> _cheatDismiss(BuildContext context) async {
    final storage = AlarmStorage();
    await storage.init();
    await storage.saveHistory(AlarmHistory(
      id: const Uuid().v4(),
      alarmId: alarm.id,
      firedAt: DateTime.now(),
      status: AlarmStatus.cheated,
    ));
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: BedBreakerTheme.bgPrimary,
        body: Stack(
          children: [
            const RingingGlowBackground(),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  PulsingTimeDisplay(
                    timeString: alarm.timeString,
                    label: alarm.label,
                  ),
                  const SizedBox(height: 48),
                  MissionInstructionCard(
                    instruction: alarm.missionType == MissionType.distance
                        ? 'Walk ${alarm.radiusMeters.round()}m from home'
                        : 'Reach your pinned location',
                    subtitle: 'Take a photo there to stop this alarm',
                  ),
                  const Spacer(),
                  StartMissionButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MissionActiveScreen(alarm: alarm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheatDismissButton(onPressed: () => _cheatDismiss(context)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

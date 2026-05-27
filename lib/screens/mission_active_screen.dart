import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/alarm_history.dart';
import '../services/alarm_scheduler.dart';
import '../services/gps_service.dart';
import '../storage/alarm_storage.dart';
import '../theme.dart';
import '../widgets/mission_active_ui.dart';
import 'camera_screen.dart';

class MissionActiveScreen extends StatefulWidget {
  final Alarm alarm;
  const MissionActiveScreen({super.key, required this.alarm});

  @override
  State<MissionActiveScreen> createState() => _MissionActiveScreenState();
}

class _MissionActiveScreenState extends State<MissionActiveScreen> {
  double _distanceRemaining = double.infinity;
  bool _inRange = false;
  bool _hasSignal = false;
  double? _accuracy;
  StreamSubscription<Position>? _sub;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sub = GpsService.trackLocation().listen(
      (pos) {
        final dist = GpsService.distanceBetween(
          pos.latitude, pos.longitude,
          widget.alarm.targetLat, widget.alarm.targetLng,
        );
        if (mounted) {
          setState(() {
            _distanceRemaining = dist;
            _accuracy = pos.accuracy;
            _inRange = GpsService.isWithinRadius(
              currentLat: pos.latitude,
              currentLng: pos.longitude,
              targetLat: widget.alarm.targetLat,
              targetLng: widget.alarm.targetLng,
              radiusMeters: widget.alarm.radiusMeters,
            );
            _hasSignal = true;
          });
        }
      },
      onError: (_) {
        if (mounted) setState(() { _hasSignal = false; _accuracy = null; });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _forceStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BedBreakerTheme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Force Stop?',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: BedBreakerTheme.textPrimary,
          ),
        ),
        content: Text(
          'This counts as a cheat and will be logged in your stats.',
          style: GoogleFonts.spaceGrotesk(color: BedBreakerTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep going',
                style: GoogleFonts.spaceGrotesk(color: BedBreakerTheme.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Force Stop',
                style: GoogleFonts.spaceGrotesk(color: BedBreakerTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final storage = AlarmStorage();
    await storage.init();
    await storage.saveHistory(AlarmHistory(
      id: const Uuid().v4(),
      alarmId: widget.alarm.id,
      firedAt: _startTime,
      status: AlarmStatus.cheated,
    ));
    await AlarmScheduler.dismissNotification(widget.alarm.id);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: BedBreakerTheme.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mission Active',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: BedBreakerTheme.textPrimary,
                      ),
                    ),
                    GpsStatusBar(hasSignal: _hasSignal, accuracy: _accuracy),
                  ],
                ),
              ),
              const Spacer(),
              DistanceRing(
                distanceRemaining: _distanceRemaining == double.infinity
                    ? widget.alarm.radiusMeters
                    : _distanceRemaining,
                totalDistance: widget.alarm.missionType == MissionType.distance
                    ? widget.alarm.radiusMeters
                    : (widget.alarm.radiusMeters * 3).clamp(200, 3000),
                inRange: _inRange,
              ),
              const Spacer(),
              CameraUnlockButton(
                unlocked: _inRange,
                onPressed: _inRange
                    ? () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CameraScreen(
                              alarm: widget.alarm,
                              startTime: _startTime,
                            ),
                          ),
                        )
                    : null,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _forceStop,
                child: Text(
                  'Force Stop — counts as a cheat',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: BedBreakerTheme.danger.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

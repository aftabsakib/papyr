import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm.dart';
import '../services/gps_service.dart';
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
        if (mounted) setState(() => _hasSignal = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
                    GpsStatusBar(hasSignal: _hasSignal),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';
import '../services/gps_service.dart';
import '../storage/alarm_storage.dart';
import '../theme.dart';
import '../widgets/create_alarm_ui.dart';
import 'mission_setup_screen.dart';

class CreateAlarmScreen extends StatefulWidget {
  const CreateAlarmScreen({super.key});

  @override
  State<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  TimeOfDay _time = TimeOfDay.now();
  final _labelController = TextEditingController(text: 'Morning Mission');
  final List<bool> _repeatDays = List.filled(7, false);
  MissionType? _missionType;
  double _distanceMeters = 500;
  double? _targetLat, _targetLng;
  String? _selectedActivity;
  bool _saving = false;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: BedBreakerTheme.bgSurface,
            hourMinuteColor: BedBreakerTheme.bgSurface2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_missionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pick a mission type.', style: GoogleFonts.spaceGrotesk()),
        backgroundColor: BedBreakerTheme.danger,
      ));
      return;
    }
    if (_missionType == MissionType.activity &&
        (_selectedActivity == null || _selectedActivity!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pick or type an activity.', style: GoogleFonts.spaceGrotesk()),
        backgroundColor: BedBreakerTheme.danger,
      ));
      return;
    }
    if (_missionType == MissionType.pin && (_targetLat == null || _targetLng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pin a target location on the map.', style: GoogleFonts.spaceGrotesk()),
        backgroundColor: BedBreakerTheme.danger,
      ));
      return;
    }

    setState(() => _saving = true);

    double homeLat = 0, homeLng = 0, targetLat = 0, targetLng = 0;

    if (_missionType != MissionType.activity) {
      final pos = await GpsService.getCurrentPosition();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Cannot get your location. Enable GPS.', style: GoogleFonts.spaceGrotesk()),
            backgroundColor: BedBreakerTheme.danger,
          ));
        }
        setState(() => _saving = false);
        return;
      }
      homeLat = pos.latitude;
      homeLng = pos.longitude;
      targetLat = _missionType == MissionType.distance ? pos.latitude : _targetLat!;
      targetLng = _missionType == MissionType.distance ? pos.longitude : _targetLng!;
    }

    final alarm = Alarm(
      id: const Uuid().v4(),
      label: _labelController.text.trim().isEmpty
          ? 'Morning Mission'
          : _labelController.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      repeatDays: _repeatDays,
      missionType: _missionType!,
      homeLat: homeLat,
      homeLng: homeLng,
      targetLat: targetLat,
      targetLng: targetLng,
      radiusMeters: _missionType == MissionType.distance ? _distanceMeters : 50,
      isActive: true,
      missionLabel: _missionType == MissionType.activity ? _selectedActivity!.trim() : null,
    );

    final storage = AlarmStorage();
    await storage.init();
    await storage.saveAlarm(alarm);
    await AlarmScheduler.scheduleAlarm(alarm);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BedBreakerTheme.bgPrimary,
      appBar: AppBar(
        title: Text('New Alarm',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: BedBreakerTheme.accent),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          BigTimePicker(time: _time, onTap: _pickTime),
          const SizedBox(height: 20),
          TextField(
            controller: _labelController,
            style: GoogleFonts.spaceGrotesk(color: BedBreakerTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Label',
              labelStyle: GoogleFonts.spaceGrotesk(color: BedBreakerTheme.textSecondary),
              filled: true,
              fillColor: BedBreakerTheme.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          RepeatDaysSelector(
            repeatDays: _repeatDays,
            onToggle: (i) => setState(() => _repeatDays[i] = !_repeatDays[i]),
          ),
          const SizedBox(height: 20),
          MissionTypeSelector(
            selectedType: _missionType,
            distanceMeters: _distanceMeters,
            hasPinnedLocation: _targetLat != null,
            selectedActivity: _selectedActivity,
            onTypeChanged: (type) => setState(() => _missionType = type),
            onDistanceChanged: (v) => setState(() => _distanceMeters = v),
            onActivityChanged: (v) => setState(() => _selectedActivity = v),
            onPinLocation: () async {
              final result = await Navigator.push<Map<String, double>>(
                context,
                MaterialPageRoute(builder: (_) => const MissionSetupScreen()),
              );
              if (result != null) {
                setState(() {
                  _targetLat = result['lat'];
                  _targetLng = result['lng'];
                });
              }
            },
          ),
        ],
      ),
      bottomSheet: SafeArea(child: SaveAlarmButton(onPressed: _saving ? () {} : _save)),
    );
  }
}

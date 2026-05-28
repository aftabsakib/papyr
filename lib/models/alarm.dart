import 'package:hive/hive.dart';

part 'alarm.g.dart';

@HiveType(typeId: 2)
enum MissionType {
  @HiveField(0)
  distance,
  @HiveField(1)
  pin,
  @HiveField(2)
  activity,
}

@HiveType(typeId: 0)
class Alarm extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String label;

  @HiveField(2)
  int hour;

  @HiveField(3)
  int minute;

  @HiveField(4)
  List<bool> repeatDays;

  @HiveField(5)
  MissionType missionType;

  @HiveField(6)
  double homeLat;

  @HiveField(7)
  double homeLng;

  @HiveField(8)
  double targetLat;

  @HiveField(9)
  double targetLng;

  @HiveField(10)
  double radiusMeters;

  @HiveField(11)
  bool isActive;

  @HiveField(12)
  String? missionLabel;

  Alarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.missionType,
    required this.homeLat,
    required this.homeLng,
    required this.targetLat,
    required this.targetLng,
    required this.radiusMeters,
    required this.isActive,
    this.missionLabel,
  });

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

import 'package:hive/hive.dart';

part 'alarm_history.g.dart';

@HiveType(typeId: 3)
enum AlarmStatus {
  @HiveField(0)
  completed,
  @HiveField(1)
  cheated,
  @HiveField(2)
  missed,
}

@HiveType(typeId: 1)
class AlarmHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String alarmId;

  @HiveField(2)
  final DateTime firedAt;

  @HiveField(3)
  AlarmStatus status;

  @HiveField(4)
  String? photoPath;

  @HiveField(5)
  int? secondsToComplete;

  AlarmHistory({
    required this.id,
    required this.alarmId,
    required this.firedAt,
    required this.status,
    this.photoPath,
    this.secondsToComplete,
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bedbreaker/models/alarm.dart';
import 'package:bedbreaker/models/alarm_history.dart';
import 'package:bedbreaker/storage/alarm_storage.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AlarmAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AlarmHistoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MissionTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AlarmStatusAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Alarm makeAlarm(String id) => Alarm(
    id: id,
    label: 'Test',
    hour: 7, minute: 0,
    repeatDays: List.filled(7, false),
    missionType: MissionType.distance,
    homeLat: 0, homeLng: 0,
    targetLat: 0, targetLng: 0,
    radiusMeters: 200,
    isActive: true,
  );

  test('saves and retrieves alarm', () async {
    final storage = AlarmStorage();
    await storage.init();
    await storage.saveAlarm(makeAlarm('test-1'));
    final alarms = storage.getAllAlarms();
    expect(alarms.length, 1);
    expect(alarms.first.id, 'test-1');
  });

  test('deletes alarm', () async {
    final storage = AlarmStorage();
    await storage.init();
    await storage.saveAlarm(makeAlarm('delete-me'));
    await storage.deleteAlarm('delete-me');
    expect(storage.getAllAlarms(), isEmpty);
  });

  test('getTotalCheats counts only cheated entries', () async {
    final storage = AlarmStorage();
    await storage.init();
    await storage.saveHistory(AlarmHistory(
      id: '1', alarmId: 'a',
      firedAt: DateTime.now(),
      status: AlarmStatus.cheated,
    ));
    await storage.saveHistory(AlarmHistory(
      id: '2', alarmId: 'a',
      firedAt: DateTime.now(),
      status: AlarmStatus.completed,
    ));
    expect(storage.getTotalCheats(), 1);
  });

  test('getCurrentStreak counts consecutive completed days', () async {
    final storage = AlarmStorage();
    await storage.init();
    final now = DateTime.now();
    await storage.saveHistory(AlarmHistory(
      id: '1', alarmId: 'a',
      firedAt: now,
      status: AlarmStatus.completed,
      secondsToComplete: 300,
    ));
    await storage.saveHistory(AlarmHistory(
      id: '2', alarmId: 'a',
      firedAt: now.subtract(const Duration(days: 1)),
      status: AlarmStatus.completed,
      secondsToComplete: 400,
    ));
    expect(storage.getCurrentStreak(), 2);
  });

  test('getCurrentStreak returns 0 when last completion was 2+ days ago', () async {
    final storage = AlarmStorage();
    await storage.init();
    await storage.saveHistory(AlarmHistory(
      id: '1', alarmId: 'a',
      firedAt: DateTime.now().subtract(const Duration(days: 3)),
      status: AlarmStatus.completed,
      secondsToComplete: 300,
    ));
    expect(storage.getCurrentStreak(), 0);
  });

  test('getCurrentStreak handles duplicate completions on same day', () async {
    final storage = AlarmStorage();
    await storage.init();
    final now = DateTime.now();
    await storage.saveHistory(AlarmHistory(
      id: '1', alarmId: 'a',
      firedAt: now,
      status: AlarmStatus.completed,
      secondsToComplete: 300,
    ));
    await storage.saveHistory(AlarmHistory(
      id: '2', alarmId: 'a',
      firedAt: now.add(const Duration(hours: 1)),
      status: AlarmStatus.completed,
      secondsToComplete: 200,
    ));
    // Two entries today — streak should be 1, not break to 0
    expect(storage.getCurrentStreak(), greaterThanOrEqualTo(1));
  });
}

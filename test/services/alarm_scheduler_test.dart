import 'package:flutter_test/flutter_test.dart';
import 'package:bedbreaker/models/alarm.dart';
import 'package:bedbreaker/services/alarm_scheduler.dart';

void main() {
  Alarm makeAlarm({
    required int hour,
    required int minute,
    required List<bool> repeatDays,
    bool isActive = true,
  }) =>
      Alarm(
        id: 'test',
        label: 'Test',
        hour: hour, minute: minute,
        repeatDays: repeatDays,
        missionType: MissionType.distance,
        homeLat: 0, homeLng: 0,
        targetLat: 0, targetLng: 0,
        radiusMeters: 200,
        isActive: isActive,
      );

  group('AlarmScheduler.nextFireTime', () {
    test('returns null for inactive alarm', () {
      final alarm = makeAlarm(hour: 6, minute: 0, repeatDays: List.filled(7, false), isActive: false);
      expect(AlarmScheduler.nextFireTime(alarm, DateTime.now()), isNull);
    });

    test('one-time alarm fires today if time has not passed', () {
      final now = DateTime(2026, 5, 28, 5, 0); // 5am
      final alarm = makeAlarm(hour: 6, minute: 30, repeatDays: List.filled(7, false));
      final next = AlarmScheduler.nextFireTime(alarm, now);
      expect(next?.hour, 6);
      expect(next?.minute, 30);
      expect(next?.day, 28);
    });

    test('one-time alarm fires tomorrow if today time has passed', () {
      final now = DateTime(2026, 5, 28, 7, 0); // 7am — after 6:30
      final alarm = makeAlarm(hour: 6, minute: 30, repeatDays: List.filled(7, false));
      final next = AlarmScheduler.nextFireTime(alarm, now);
      expect(next?.day, 29);
    });

    test('repeating alarm fires on next matching weekday', () {
      final now = DateTime(2026, 5, 28, 5, 0); // Wednesday, 5am
      final repeatDays = [false, false, true, false, false, false, false]; // Wed only
      final alarm = makeAlarm(hour: 6, minute: 30, repeatDays: repeatDays);
      final next = AlarmScheduler.nextFireTime(alarm, now);
      expect(next?.weekday, DateTime.wednesday);
      expect(next?.hour, 6);
    });

    test('repeating alarm wraps to same weekday next week when today has passed', () {
      // Wednesday at 7am — alarm fires on Wednesday at 6am (already passed today)
      final now = DateTime(2026, 5, 27, 7, 0); // Wednesday
      final repeatDays = [false, false, true, false, false, false, false]; // Wed only
      final alarm = makeAlarm(hour: 6, minute: 0, repeatDays: repeatDays);
      final next = AlarmScheduler.nextFireTime(alarm, now);
      expect(next?.weekday, DateTime.wednesday);
      expect(next?.isAfter(now), isTrue);
      // Should be exactly 7 days ahead (next Wednesday)
      expect(next?.difference(DateTime(2026, 5, 27)).inDays, 7);
    });
  });
}

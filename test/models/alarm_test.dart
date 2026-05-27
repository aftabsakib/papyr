import 'package:flutter_test/flutter_test.dart';
import 'package:bedbreaker/models/alarm.dart';

void main() {
  group('Alarm model', () {
    test('creates alarm with required fields', () {
      final alarm = Alarm(
        id: 'test-id',
        label: 'Morning Run',
        hour: 6,
        minute: 30,
        repeatDays: [true, true, true, true, true, false, false],
        missionType: MissionType.distance,
        homeLat: 27.7172,
        homeLng: 85.3240,
        targetLat: 27.7172,
        targetLng: 85.3240,
        radiusMeters: 500,
        isActive: true,
      );

      expect(alarm.id, 'test-id');
      expect(alarm.label, 'Morning Run');
      expect(alarm.hour, 6);
      expect(alarm.missionType, MissionType.distance);
      expect(alarm.radiusMeters, 500);
    });

    test('timeString formats correctly', () {
      final alarm = Alarm(
        id: 'test-id',
        label: 'Test',
        hour: 6,
        minute: 5,
        repeatDays: List.filled(7, false),
        missionType: MissionType.distance,
        homeLat: 0, homeLng: 0,
        targetLat: 0, targetLng: 0,
        radiusMeters: 100,
        isActive: true,
      );
      expect(alarm.timeString, '06:05');
    });
  });
}

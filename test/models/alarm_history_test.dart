import 'package:flutter_test/flutter_test.dart';
import 'package:bedbreaker/models/alarm_history.dart';

void main() {
  group('AlarmHistory model', () {
    test('creates history entry with completed status', () {
      final history = AlarmHistory(
        id: 'history-id',
        alarmId: 'alarm-id',
        firedAt: DateTime(2026, 5, 27, 6, 30),
        status: AlarmStatus.completed,
        photoPath: '/data/user/0/photo.jpg',
        secondsToComplete: 420,
      );

      expect(history.status, AlarmStatus.completed);
      expect(history.secondsToComplete, 420);
    });

    test('creates cheat entry with null photo', () {
      final history = AlarmHistory(
        id: 'history-id',
        alarmId: 'alarm-id',
        firedAt: DateTime(2026, 5, 27, 6, 30),
        status: AlarmStatus.cheated,
        photoPath: null,
        secondsToComplete: null,
      );

      expect(history.status, AlarmStatus.cheated);
      expect(history.photoPath, isNull);
    });
  });
}

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm.dart';

class AlarmScheduler {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await AndroidAlarmManager.initialize();
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  static DateTime? nextFireTime(Alarm alarm, [DateTime? from]) {
    if (!alarm.isActive) return null;
    final now = from ?? DateTime.now();
    final hasRepeat = alarm.repeatDays.any((d) => d);

    if (!hasRepeat) {
      var candidate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 1));
      return candidate;
    }

    for (int i = 0; i < 8; i++) {
      final candidate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute)
          .add(Duration(days: i));
      final dayIndex = candidate.weekday - 1;
      if (alarm.repeatDays[dayIndex] && !candidate.isBefore(now)) {
        return candidate;
      }
    }
    return null;
  }

  static int _alarmIntId(String uuid) =>
      int.parse(uuid.replaceAll('-', '').substring(0, 8), radix: 16);

  static Future<void> scheduleAlarm(Alarm alarm) async {
    final next = nextFireTime(alarm);
    if (next == null) return;
    final alarmId = _alarmIntId(alarm.id);
    await AndroidAlarmManager.oneShotAt(
      next,
      alarmId,
      _onAlarmFired,
      exact: true,
      wakeup: true,
      alarmClock: true,
    );
  }

  static Future<void> cancelAlarm(Alarm alarm) async {
    await AndroidAlarmManager.cancel(_alarmIntId(alarm.id));
  }

  @pragma('vm:entry-point')
  static void _onAlarmFired() {
    // Foreground service handles the ringing — see Task 12
  }
}

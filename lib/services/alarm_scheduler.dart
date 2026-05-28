import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/alarm.dart';

class AlarmScheduler {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  static Future<void> init({
    void Function(NotificationResponse)? onNotificationTap,
    void Function(NotificationResponse)? onBackgroundNotificationTap,
  }) async {
    if (!_tzInitialized) {
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      _tzInitialized = true;
    }

    await _notifications.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTap,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'bedbreaker_alarm',
          'BedBreaker Alarms',
          description: 'Alarm notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ));
  }

  static int _baseId(String alarmId) =>
      int.parse(alarmId.replaceAll('-', '').substring(0, 7), radix: 16) &
      0x0FFFFFFF;

  static int _notifId(String alarmId, [int dayOffset = 0]) =>
      _baseId(alarmId) + dayOffset;

  static DateTime? nextFireTime(Alarm alarm, [DateTime? from]) {
    if (!alarm.isActive) return null;
    final now = from ?? DateTime.now();
    final hasRepeat = alarm.repeatDays.any((d) => d);

    if (!hasRepeat) {
      var candidate =
          DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      if (!candidate.isAfter(now)) candidate = candidate.add(const Duration(days: 1));
      return candidate;
    }

    for (int i = 0; i < 8; i++) {
      final candidate =
          DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute)
              .add(Duration(days: i));
      final dayIndex = candidate.weekday - 1;
      if (alarm.repeatDays[dayIndex] && !candidate.isBefore(now)) {
        return candidate;
      }
    }
    return null;
  }

  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isActive) return;
    await cancelAlarm(alarm);

    final hasRepeat = alarm.repeatDays.any((d) => d);

    if (!hasRepeat) {
      final next = nextFireTime(alarm);
      if (next == null) return;
      await _notifications.zonedSchedule(
        _notifId(alarm.id),
        'Wake up! Mission time.',
        _missionBody(alarm),
        tz.TZDateTime.from(next, tz.local),
        _buildNotifDetails(alarm),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: alarm.id,
      );
    } else {
      for (int i = 0; i < 7; i++) {
        if (!alarm.repeatDays[i]) continue;
        final targetWeekday = i + 1;
        final next = _nextForWeekday(alarm.hour, alarm.minute, targetWeekday);
        await _notifications.zonedSchedule(
          _notifId(alarm.id, i + 1),
          'Wake up! Mission time.',
          _missionBody(alarm),
          next,
          _buildNotifDetails(alarm),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: alarm.id,
        );
      }
    }
  }

  static Future<void> cancelAlarm(Alarm alarm) async {
    await _notifications.cancel(_notifId(alarm.id));
    for (int i = 1; i <= 7; i++) {
      await _notifications.cancel(_notifId(alarm.id, i));
    }
  }

  static Future<void> dismissNotification(String alarmId) async {
    await _notifications.cancel(_notifId(alarmId));
    for (int i = 1; i <= 7; i++) {
      await _notifications.cancel(_notifId(alarmId, i));
    }
  }

  static tz.TZDateTime _nextForWeekday(int hour, int minute, int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var c = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (c.weekday != weekday || !c.isAfter(now)) {
      c = c.add(const Duration(days: 1));
    }
    return c;
  }

  static String _missionBody(Alarm alarm) {
    switch (alarm.missionType) {
      case MissionType.activity:
        return 'Mission: ${alarm.missionLabel ?? 'Complete your mission'}';
      case MissionType.distance:
        return 'Walk ${alarm.radiusMeters.round()}m from home and take a photo';
      case MissionType.pin:
        return 'Reach your pinned location and take a photo';
    }
  }

  static NotificationDetails _buildNotifDetails(Alarm alarm) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'bedbreaker_alarm',
        'BedBreaker Alarms',
        channelDescription: 'Alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: true,
      ),
    );
  }
}

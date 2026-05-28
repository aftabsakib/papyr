import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/alarm.dart';

class AlarmScheduler {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  static Future<void> _ensureTimezone() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 4));
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _tzInitialized = true;
  }

  static Future<void> init({
    void Function(NotificationResponse)? onNotificationTap,
    void Function(NotificationResponse)? onBackgroundNotificationTap,
  }) async {
    await _notifications.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTap,
    );

    // Channel ID v2 — forces recreation with alarm audio stream.
    // Android ignores changes to existing channels, so a new ID is required.
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'bedbreaker_alarmv2',
          'BedBreaker Alarms',
          description: 'Alarm notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
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
    await _ensureTimezone();
    await cancelAlarm(alarm);

    final hasRepeat = alarm.repeatDays.any((d) => d);
    final details = _buildNotifDetails(alarm);

    if (!hasRepeat) {
      final next = nextFireTime(alarm);
      if (next == null) return;
      try {
        await _notifications.zonedSchedule(
          _notifId(alarm.id),
          'Wake up! Mission time.',
          _missionBody(alarm),
          tz.TZDateTime.from(next, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: alarm.id,
        );
      } catch (_) {}
    } else {
      for (int i = 0; i < 7; i++) {
        if (!alarm.repeatDays[i]) continue;
        final next = _nextForWeekday(alarm.hour, alarm.minute, i + 1);
        try {
          await _notifications.zonedSchedule(
            _notifId(alarm.id, i + 1),
            'Wake up! Mission time.',
            _missionBody(alarm),
            next,
            details,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: alarm.id,
          );
        } catch (_) {}
      }
    }
  }

  static Future<void> cancelAlarm(Alarm alarm) async {
    try { await _notifications.cancel(_notifId(alarm.id)); } catch (_) {}
    for (int i = 1; i <= 7; i++) {
      try { await _notifications.cancel(_notifId(alarm.id, i)); } catch (_) {}
    }
  }

  static Future<void> dismissNotification(String alarmId) async {
    // Only cancel the one-shot (base) ID. Repeating day-offset notifications
    // use matchDateTimeComponents and self-reschedule — cancelling them here
    // would wipe all future occurrences of a repeating alarm.
    try { await _notifications.cancel(_notifId(alarmId)); } catch (_) {}
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
        'bedbreaker_alarmv2',
        'BedBreaker Alarms',
        channelDescription: 'Alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }
}

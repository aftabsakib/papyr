import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm.dart';
import '../models/alarm_history.dart';

class AlarmStorage {
  static const _alarmsBox = 'alarms';
  static const _historyBox = 'alarm_history';

  late Box<Alarm> _alarms;
  late Box<AlarmHistory> _history;

  Future<void> init() async {
    _alarms = await Hive.openBox<Alarm>(_alarmsBox);
    _history = await Hive.openBox<AlarmHistory>(_historyBox);
  }

  Future<void> saveAlarm(Alarm alarm) async {
    await _alarms.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(String id) async {
    await _alarms.delete(id);
  }

  List<Alarm> getAllAlarms() => _alarms.values.toList();

  Alarm? getAlarm(String id) => _alarms.get(id);

  Future<void> saveHistory(AlarmHistory history) async {
    await _history.put(history.id, history);
  }

  List<AlarmHistory> getHistoryForAlarm(String alarmId) =>
      _history.values.where((h) => h.alarmId == alarmId).toList();

  List<AlarmHistory> getAllHistory() => _history.values.toList();

  int getTotalCheats() =>
      _history.values.where((h) => h.status == AlarmStatus.cheated).length;

  int getCurrentStreak() {
    final completed = _history.values
        .where((h) => h.status == AlarmStatus.completed)
        .toList()
      ..sort((a, b) => b.firedAt.compareTo(a.firedAt));

    int streak = 0;
    DateTime? lastDate;
    for (final entry in completed) {
      final date = DateTime(entry.firedAt.year, entry.firedAt.month, entry.firedAt.day);
      if (lastDate == null) {
        lastDate = date;
        streak = 1;
      } else if (lastDate.difference(date).inDays == 1) {
        lastDate = date;
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

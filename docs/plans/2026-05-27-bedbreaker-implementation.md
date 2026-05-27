# BedBreaker Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build BedBreaker — a Flutter alarm clock that only stops ringing when you physically travel to a GPS location and take a photo there.

**Architecture:** Pure Flutter app, no backend. All data stored locally in Hive. Alarm fires via flutter_local_notifications + android_alarm_manager_plus, GPS tracking runs in a foreground service, camera captures proof of presence at the target. UI designed in Google Stitch first, exported as Flutter widgets, then logic wired behind them.

**Tech Stack:** Flutter 3.x, Dart, Hive 2.x, geolocator, flutter_local_notifications, android_alarm_manager_plus, flutter_foreground_task, camera, flutter_map, OpenStreetMap, permission_handler

---

## Task 1: Create Flutter Project + Folder Structure

**Files:**
- Create: `bedbreaker/` (Flutter project root)
- Create: `lib/models/`
- Create: `lib/services/`
- Create: `lib/screens/`
- Create: `lib/widgets/`
- Create: `lib/storage/`

**Step 1: Create the Flutter project**

Run:
```bash
flutter create bedbreaker --org com.bedbreaker --platforms android,ios
cd bedbreaker
```

**Step 2: Create folder structure**

Run:
```bash
mkdir -p lib/models lib/services lib/screens lib/widgets lib/storage
```

**Step 3: Replace pubspec.yaml dependencies**

Edit `pubspec.yaml` — replace the `dependencies` section:
```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  geolocator: ^13.0.0
  flutter_local_notifications: ^18.0.0
  android_alarm_manager_plus: ^4.0.0
  flutter_foreground_task: ^8.0.0
  camera: ^0.11.0
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
  permission_handler: ^11.0.0
  uuid: ^4.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.0
  build_runner: ^2.4.0
  mockito: ^5.4.0
```

**Step 4: Get packages**

Run:
```bash
flutter pub get
```
Expected: no errors, all packages resolved.

**Step 5: Verify project runs**

Run:
```bash
flutter run
```
Expected: default Flutter counter app launches on device/emulator.

**Step 6: Commit**

```bash
git init
git add .
git commit -m "feat: initialise BedBreaker Flutter project with dependencies"
```

---

## Task 2: Configure Android Permissions + Services

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle`

**Step 1: Add permissions and services to AndroidManifest.xml**

Open `android/app/src/main/AndroidManifest.xml`. Inside `<manifest>`, before `<application>`, add:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

Inside `<application>`, add the foreground service and alarm receiver:
```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="location"
    android:exported="false"/>

<receiver
    android:name="dev.fluttercommunity.plus.androidalarmmanager.AlarmBroadcastReceiver"
    android:exported="false"/>

<receiver
    android:name="dev.fluttercommunity.plus.androidalarmmanager.RebootBroadcastReceiver"
    android:enabled="true"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

**Step 2: Set minimum SDK to 23 in android/app/build.gradle**

Find `minSdkVersion` and set:
```gradle
minSdkVersion 23
```

**Step 3: Verify build still works**

Run:
```bash
flutter build apk --debug
```
Expected: BUILD SUCCESSFUL

**Step 4: Commit**

```bash
git add android/
git commit -m "feat: configure Android permissions and foreground service"
```

---

## Task 3: Alarm Data Model

**Files:**
- Create: `lib/models/alarm.dart`
- Create: `lib/models/alarm.g.dart` (generated)
- Create: `test/models/alarm_test.dart`

**Step 1: Write the failing test**

Create `test/models/alarm_test.dart`:
```dart
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
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/models/alarm_test.dart
```
Expected: FAIL — `alarm.dart` not found.

**Step 3: Create the Alarm model**

Create `lib/models/alarm.dart`:
```dart
import 'package:hive/hive.dart';

part 'alarm.g.dart';

enum MissionType { distance, pin }

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
  List<bool> repeatDays; // Mon=0 ... Sun=6

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
  });

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
```

**Step 4: Generate Hive adapter**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
Expected: `lib/models/alarm.g.dart` created.

**Step 5: Run test to verify it passes**

```bash
flutter test test/models/alarm_test.dart
```
Expected: PASS

**Step 6: Commit**

```bash
git add lib/models/ test/models/
git commit -m "feat: add Alarm model with Hive adapter"
```

---

## Task 4: AlarmHistory Data Model

**Files:**
- Create: `lib/models/alarm_history.dart`
- Create: `lib/models/alarm_history.g.dart` (generated)
- Create: `test/models/alarm_history_test.dart`

**Step 1: Write the failing test**

Create `test/models/alarm_history_test.dart`:
```dart
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
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/models/alarm_history_test.dart
```
Expected: FAIL

**Step 3: Create the AlarmHistory model**

Create `lib/models/alarm_history.dart`:
```dart
import 'package:hive/hive.dart';

part 'alarm_history.g.dart';

enum AlarmStatus { completed, cheated, missed }

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
```

**Step 4: Regenerate Hive adapters**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 5: Run test to verify it passes**

```bash
flutter test test/models/alarm_history_test.dart
```
Expected: PASS

**Step 6: Commit**

```bash
git add lib/models/ test/models/
git commit -m "feat: add AlarmHistory model with Hive adapter"
```

---

## Task 5: Hive Storage Service

**Files:**
- Create: `lib/storage/alarm_storage.dart`
- Create: `test/storage/alarm_storage_test.dart`
- Modify: `lib/main.dart`

**Step 1: Write the failing test**

Create `test/storage/alarm_storage_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bedbreaker/models/alarm.dart';
import 'package:bedbreaker/models/alarm_history.dart';
import 'package:bedbreaker/storage/alarm_storage.dart';

void main() {
  setUp(() async {
    await Hive.initFlutter('test_hive');
    Hive.registerAdapter(AlarmAdapter());
    Hive.registerAdapter(AlarmHistoryAdapter());
    Hive.registerAdapter(MissionTypeAdapter());
    Hive.registerAdapter(AlarmStatusAdapter());
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('saves and retrieves alarm', () async {
    final storage = AlarmStorage();
    await storage.init();

    final alarm = Alarm(
      id: 'test-1',
      label: 'Test',
      hour: 7,
      minute: 0,
      repeatDays: List.filled(7, false),
      missionType: MissionType.distance,
      homeLat: 0, homeLng: 0,
      targetLat: 0, targetLng: 0,
      radiusMeters: 200,
      isActive: true,
    );

    await storage.saveAlarm(alarm);
    final alarms = storage.getAllAlarms();

    expect(alarms.length, 1);
    expect(alarms.first.id, 'test-1');
  });

  test('deletes alarm', () async {
    final storage = AlarmStorage();
    await storage.init();

    final alarm = Alarm(
      id: 'delete-me',
      label: 'Delete',
      hour: 8, minute: 0,
      repeatDays: List.filled(7, false),
      missionType: MissionType.distance,
      homeLat: 0, homeLng: 0,
      targetLat: 0, targetLng: 0,
      radiusMeters: 200,
      isActive: true,
    );

    await storage.saveAlarm(alarm);
    await storage.deleteAlarm('delete-me');
    expect(storage.getAllAlarms(), isEmpty);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/storage/alarm_storage_test.dart
```
Expected: FAIL

**Step 3: Create the storage service**

Create `lib/storage/alarm_storage.dart`:
```dart
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
```

**Step 4: Register adapters and init Hive in main.dart**

Replace `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/alarm.dart';
import 'models/alarm_history.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmAdapter());
  Hive.registerAdapter(AlarmHistoryAdapter());
  Hive.registerAdapter(MissionTypeAdapter());
  Hive.registerAdapter(AlarmStatusAdapter());
  runApp(const BedBreakerApp());
}

class BedBreakerApp extends StatelessWidget {
  const BedBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BedBreaker',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
```

**Step 5: Run tests**

```bash
flutter test test/storage/
```
Expected: PASS

**Step 6: Commit**

```bash
git add lib/storage/ lib/main.dart test/storage/
git commit -m "feat: add Hive storage service with streak + cheat count"
```

---

## Task 6: GPS Distance Service

**Files:**
- Create: `lib/services/gps_service.dart`
- Create: `test/services/gps_service_test.dart`

**Step 1: Write the failing test**

Create `test/services/gps_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bedbreaker/services/gps_service.dart';

void main() {
  group('GpsService distance calculation', () {
    test('calculates distance between two points', () {
      // Kathmandu to roughly 500m away
      final distance = GpsService.distanceBetween(
        27.7172, 85.3240,
        27.7217, 85.3240, // ~500m north
      );
      expect(distance, closeTo(500, 50));
    });

    test('returns 0 for same point', () {
      final distance = GpsService.distanceBetween(
        27.7172, 85.3240,
        27.7172, 85.3240,
      );
      expect(distance, 0.0);
    });

    test('isWithinRadius returns true when inside', () {
      expect(
        GpsService.isWithinRadius(
          currentLat: 27.7172, currentLng: 85.3240,
          targetLat: 27.7172, targetLng: 85.3240,
          radiusMeters: 100,
        ),
        isTrue,
      );
    });

    test('isWithinRadius returns false when outside', () {
      expect(
        GpsService.isWithinRadius(
          currentLat: 27.7172, currentLng: 85.3240,
          targetLat: 27.7500, targetLng: 85.3240,
          radiusMeters: 100,
        ),
        isFalse,
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/services/gps_service_test.dart
```
Expected: FAIL

**Step 3: Create GPS service**

Create `lib/services/gps_service.dart`:
```dart
import 'dart:math';
import 'package:geolocator/geolocator.dart';

class GpsService {
  static const double _minAccuracyMeters = 50.0;

  static double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  static bool isWithinRadius({
    required double currentLat,
    required double currentLng,
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) {
    final distance = distanceBetween(currentLat, currentLng, targetLat, targetLng);
    return distance <= radiusMeters;
  }

  Stream<Position> trackLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).where((pos) => pos.accuracy <= _minAccuracyMeters);
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }
}
```

**Step 4: Run test to verify it passes**

```bash
flutter test test/services/gps_service_test.dart
```
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/gps_service.dart test/services/
git commit -m "feat: add GPS service with distance calculation and location tracking"
```

---

## Task 7: Alarm Scheduler Service

**Files:**
- Create: `lib/services/alarm_scheduler.dart`
- Create: `test/services/alarm_scheduler_test.dart`

**Step 1: Write the failing test**

Create `test/services/alarm_scheduler_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bedbreaker/models/alarm.dart';
import 'package:bedbreaker/services/alarm_scheduler.dart';

void main() {
  group('AlarmScheduler', () {
    test('nextFireTime returns correct DateTime for today', () {
      final now = DateTime(2026, 5, 27, 5, 0); // Wednesday 5am
      final alarm = Alarm(
        id: 'test',
        label: 'Test',
        hour: 6,
        minute: 30,
        repeatDays: [false, false, true, false, false, false, false], // Wed=true
        missionType: MissionType.distance,
        homeLat: 0, homeLng: 0,
        targetLat: 0, targetLng: 0,
        radiusMeters: 200,
        isActive: true,
      );

      final next = AlarmScheduler.nextFireTime(alarm, now);
      expect(next?.hour, 6);
      expect(next?.minute, 30);
      expect(next?.weekday, DateTime.wednesday);
    });

    test('nextFireTime returns null for inactive alarm', () {
      final alarm = Alarm(
        id: 'test',
        label: 'Test',
        hour: 6, minute: 0,
        repeatDays: List.filled(7, false),
        missionType: MissionType.distance,
        homeLat: 0, homeLng: 0,
        targetLat: 0, targetLng: 0,
        radiusMeters: 200,
        isActive: false,
      );

      expect(AlarmScheduler.nextFireTime(alarm, DateTime.now()), isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/services/alarm_scheduler_test.dart
```
Expected: FAIL

**Step 3: Create alarm scheduler**

Create `lib/services/alarm_scheduler.dart`:
```dart
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
      // One-time alarm: next occurrence of this time
      var candidate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
      if (candidate.isBefore(now)) candidate = candidate.add(const Duration(days: 1));
      return candidate;
    }

    // Find next matching weekday (Mon=0 in list, Mon=1 in DateTime.weekday)
    for (int i = 0; i < 7; i++) {
      final candidate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute)
          .add(Duration(days: i));
      final dayIndex = candidate.weekday - 1; // DateTime: Mon=1, our list: Mon=0
      if (alarm.repeatDays[dayIndex] && candidate.isAfter(now)) {
        return candidate;
      }
    }
    return null;
  }

  static Future<void> scheduleAlarm(Alarm alarm) async {
    final next = nextFireTime(alarm);
    if (next == null) return;

    final alarmId = alarm.id.hashCode;
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
    await AndroidAlarmManager.cancel(alarm.id.hashCode);
  }

  @pragma('vm:entry-point')
  static void _onAlarmFired() {
    // Handled by foreground service — see ForegroundAlarmService
  }
}
```

**Step 4: Run test to verify it passes**

```bash
flutter test test/services/alarm_scheduler_test.dart
```
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/alarm_scheduler.dart test/services/
git commit -m "feat: add alarm scheduler service with repeat day logic"
```

---

## Task 8: Design All Screens in Google Stitch

**This task has no code. Do it before writing any screen UI.**

**Step 1: Open Google Stitch**

Go to: https://stitch.withgoogle.com

**Step 2: Design Home Screen**

Prompt to use in Stitch:
> "Dark mode alarm clock home screen. Shows a list of alarms with time (large bold), label, repeat days chips, and an on/off toggle. Floating action button to add alarm. Top shows streak count and cheat count as chips. Material 3, very bold typography, dark background #0D0D0D, accent color electric blue #3D8EFF."

Export the Flutter widget code. Save to `lib/widgets/home_alarm_list.dart`.

**Step 3: Design Ringing Screen**

Prompt:
> "Full screen alarm ringing screen. Dark background, pulsing large time display in center. Below: mission instruction card saying 'Walk 500m from home — unlock camera when you arrive'. Red glowing dismiss button at bottom labeled 'Force Stop (cheat)'. No snooze button. Urgent, dramatic feel."

Export. Save to `lib/widgets/ringing_screen_ui.dart`.

**Step 4: Design Mission Active Screen**

Prompt:
> "Mission active screen. Shows large distance remaining '347m to go'. Progress ring around it. Below: OpenStreetMap showing user location (blue dot) and target pin. Camera button greyed out with lock icon until in range. When in range, camera button glows green."

Export. Save to `lib/widgets/mission_active_ui.dart`.

**Step 5: Design Create Alarm Screen**

Prompt:
> "Create alarm screen. Time picker at top. Below: label text field, repeat days toggle row (M T W T F S S). Mission type card with two options: 'Distance from home' with slider for meters, 'Go to location' with map pin button. Save button at bottom. Dark Material 3."

Export. Save to `lib/widgets/create_alarm_ui.dart`.

**Step 6: Design Stats Screen**

Prompt:
> "Stats screen for a discipline alarm app. Shows: current streak number (large, bold), total cheats counter, completion rate percentage as a ring chart, scrollable list of past alarm history entries with status icons (green checkmark, red X). Dark Material 3."

Export. Save to `lib/widgets/stats_ui.dart`.

**Step 7: Commit all Stitch exports**

```bash
git add lib/widgets/
git commit -m "feat: add Stitch-generated UI widget exports for all screens"
```

---

## Task 9: Permissions Onboarding Screen

**Files:**
- Create: `lib/screens/onboarding_screen.dart`

**Step 1: Create onboarding screen**

Create `lib/screens/onboarding_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _locationGranted = false;
  bool _cameraGranted = false;
  bool _notificationGranted = false;

  Future<void> _requestAll() async {
    final location = await Permission.locationAlways.request();
    final camera = await Permission.camera.request();
    final notification = await Permission.notification.request();

    // Ask to disable battery optimization
    await Permission.ignoreBatteryOptimizations.request();

    setState(() {
      _locationGranted = location.isGranted;
      _cameraGranted = camera.isGranted;
      _notificationGranted = notification.isGranted;
    });

    if (_locationGranted && _cameraGranted && _notificationGranted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Text('BedBreaker needs\n3 permissions.',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Without these, the alarm cannot work.',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 48),
              _PermissionTile(
                icon: Icons.location_on,
                title: 'Location (always on)',
                subtitle: 'To track when you reach your mission target',
                granted: _locationGranted,
              ),
              _PermissionTile(
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'To take the proof photo at your destination',
                granted: _cameraGranted,
              ),
              _PermissionTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'To ring the alarm',
                granted: _notificationGranted,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D8EFF),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Grant Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: granted ? const Color(0xFF3D8EFF) : Colors.white54),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Icon(
        granted ? Icons.check_circle : Icons.circle_outlined,
        color: granted ? Colors.greenAccent : Colors.white24,
      ),
    );
  }
}
```

**Step 2: Update main.dart to check permissions on launch**

In `lib/main.dart`, update the `home:` parameter:
```dart
import 'package:permission_handler/permission_handler.dart';
import 'screens/onboarding_screen.dart';

// In BedBreakerApp.build(), replace home:
home: FutureBuilder<bool>(
  future: _permissionsGranted(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox.shrink();
    return snapshot.data! ? const HomeScreen() : const OnboardingScreen();
  },
),

// Add this function to BedBreakerApp:
Future<bool> _permissionsGranted() async {
  return await Permission.locationAlways.isGranted &&
      await Permission.camera.isGranted &&
      await Permission.notification.isGranted;
}
```

**Step 3: Verify it runs**

```bash
flutter run
```
Expected: Onboarding screen appears on first launch.

**Step 4: Commit**

```bash
git add lib/screens/onboarding_screen.dart lib/main.dart
git commit -m "feat: add permissions onboarding screen"
```

---

## Task 10: Home Screen

**Files:**
- Create: `lib/screens/home_screen.dart`

**Step 1: Create home screen wiring Stitch widget to storage**

Create `lib/screens/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm.dart';
import '../storage/alarm_storage.dart';
import '../services/alarm_scheduler.dart';
import 'create_alarm_screen.dart';
import 'stats_screen.dart';
// Import Stitch widgets:
// import '../widgets/home_alarm_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AlarmStorage _storage;

  @override
  void initState() {
    super.initState();
    _storage = AlarmStorage();
    _storage.init();
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    alarm.isActive = !alarm.isActive;
    await alarm.save();
    if (alarm.isActive) {
      await AlarmScheduler.scheduleAlarm(alarm);
    } else {
      await AlarmScheduler.cancelAlarm(alarm);
    }
    setState(() {});
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    await AlarmScheduler.cancelAlarm(alarm);
    await _storage.deleteAlarm(alarm.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final alarms = _storage.getAllAlarms();
    final streak = _storage.getCurrentStreak();
    final cheats = _storage.getTotalCheats();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('BedBreaker',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Streak + cheat chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Chip(
                label: Text('$streak day streak',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF3D8EFF).withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('$cheats cheats',
                    style: const TextStyle(color: Colors.redAccent)),
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
            ]),
          ),
          Expanded(
            child: alarms.isEmpty
                ? const Center(
                    child: Text('No alarms yet.\nTap + to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 18)))
                : ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, i) {
                      final alarm = alarms[i];
                      return _AlarmCard(
                        alarm: alarm,
                        onToggle: () => _toggleAlarm(alarm),
                        onDelete: () => _deleteAlarm(alarm),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAlarmScreen()),
        ).then((_) => setState(() {})),
        backgroundColor: const Color(0xFF3D8EFF),
        icon: const Icon(Icons.add),
        label: const Text('New Alarm', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlarmCard({required this.alarm, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alarm.timeString,
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(alarm.label,
                      style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(7, (i) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: alarm.repeatDays[i]
                            ? const Color(0xFF3D8EFF).withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: alarm.repeatDays[i]
                              ? const Color(0xFF3D8EFF)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(days[i],
                          style: TextStyle(
                              fontSize: 10,
                              color: alarm.repeatDays[i] ? Colors.white : Colors.white38)),
                    )),
                  ),
                ],
              ),
            ),
            Switch(
              value: alarm.isActive,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF3D8EFF),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Verify it compiles**

```bash
flutter build apk --debug
```
Expected: BUILD SUCCESSFUL (HomeScreen and StatsScreen stubs needed — create empty ones if needed).

**Step 3: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat: add home screen with alarm list, streak, and cheat count"
```

---

## Task 11: Create Alarm Screen

**Files:**
- Create: `lib/screens/create_alarm_screen.dart`
- Create: `lib/screens/mission_setup_screen.dart`

**Step 1: Create the alarm creation screen**

Create `lib/screens/create_alarm_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';
import '../services/gps_service.dart';
import '../storage/alarm_storage.dart';
import 'mission_setup_screen.dart';

class CreateAlarmScreen extends StatefulWidget {
  const CreateAlarmScreen({super.key});

  @override
  State<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  TimeOfDay _time = TimeOfDay.now();
  final _labelController = TextEditingController(text: 'Morning Mission');
  List<bool> _repeatDays = List.filled(7, false);
  MissionType _missionType = MissionType.distance;
  double _distanceMeters = 500;
  double? _targetLat, _targetLng;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final gps = GpsService();
    final pos = await gps.getCurrentPosition();
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot get your location. Enable GPS.')));
      return;
    }

    final targetLat = _missionType == MissionType.distance ? pos.latitude : _targetLat;
    final targetLng = _missionType == MissionType.distance ? pos.longitude : _targetLng;

    if (targetLat == null || targetLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a target location.')));
      return;
    }

    final alarm = Alarm(
      id: const Uuid().v4(),
      label: _labelController.text,
      hour: _time.hour,
      minute: _time.minute,
      repeatDays: _repeatDays,
      missionType: _missionType,
      homeLat: pos.latitude,
      homeLng: pos.longitude,
      targetLat: targetLat,
      targetLng: targetLng,
      radiusMeters: _missionType == MissionType.distance ? _distanceMeters : 50,
      isActive: true,
    );

    final storage = AlarmStorage();
    await storage.init();
    await storage.saveAlarm(alarm);
    await AlarmScheduler.scheduleAlarm(alarm);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('New Alarm', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Color(0xFF3D8EFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Time picker
          GestureDetector(
            onTap: _pickTime,
            child: Center(
              child: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Label
          TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Label',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          // Repeat days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) => GestureDetector(
              onTap: () => setState(() => _repeatDays[i] = !_repeatDays[i]),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _repeatDays[i] ? const Color(0xFF3D8EFF) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(days[i],
                    style: TextStyle(color: _repeatDays[i] ? Colors.white : Colors.white38, fontWeight: FontWeight.bold))),
              ),
            )),
          ),
          const SizedBox(height: 24),
          // Mission type
          const Text('Mission Type', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          _MissionCard(
            title: 'Distance from home',
            subtitle: 'Walk at least ${_distanceMeters.round()}m from where you are now',
            icon: Icons.directions_walk,
            selected: _missionType == MissionType.distance,
            onTap: () => setState(() => _missionType = MissionType.distance),
          ),
          if (_missionType == MissionType.distance) ...[
            Slider(
              value: _distanceMeters,
              min: 100,
              max: 2000,
              divisions: 19,
              label: '${_distanceMeters.round()}m',
              activeColor: const Color(0xFF3D8EFF),
              onChanged: (v) => setState(() => _distanceMeters = v),
            ),
          ],
          _MissionCard(
            title: 'Go to a location',
            subtitle: _targetLat != null ? 'Location set' : 'Pin a location on the map',
            icon: Icons.pin_drop,
            selected: _missionType == MissionType.pin,
            onTap: () async {
              setState(() => _missionType = MissionType.pin);
              final result = await Navigator.push<Map<String, double>>(
                context,
                MaterialPageRoute(builder: (_) => const MissionSetupScreen()),
              );
              if (result != null) {
                setState(() {
                  _targetLat = result['lat'];
                  _targetLng = result['lng'];
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MissionCard({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF3D8EFF) : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF3D8EFF) : Colors.white38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ]),
            ),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF3D8EFF)),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Create mission setup map screen**

Create `lib/screens/mission_setup_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MissionSetupScreen extends StatefulWidget {
  const MissionSetupScreen({super.key});

  @override
  State<MissionSetupScreen> createState() => _MissionSetupScreenState();
}

class _MissionSetupScreenState extends State<MissionSetupScreen> {
  LatLng? _pinned;
  LatLng _center = const LatLng(27.7172, 85.3240);

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Pin Target Location', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (_pinned != null)
            TextButton(
              onPressed: () => Navigator.pop(context, {'lat': _pinned!.latitude, 'lng': _pinned!.longitude}),
              child: const Text('Done', style: TextStyle(color: Color(0xFF3D8EFF), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tap the map to drop your target pin.',
                style: TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 15,
                onTap: (_, point) => setState(() => _pinned = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bedbreaker',
                ),
                if (_pinned != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _pinned!,
                      child: const Icon(Icons.location_pin, color: Color(0xFF3D8EFF), size: 40),
                    ),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 3: Verify compilation**

```bash
flutter build apk --debug
```
Expected: BUILD SUCCESSFUL

**Step 4: Commit**

```bash
git add lib/screens/
git commit -m "feat: add create alarm and map pin screens"
```

---

## Task 12: Ringing Screen + Mission Active Screen

**Files:**
- Create: `lib/screens/ringing_screen.dart`
- Create: `lib/screens/mission_active_screen.dart`
- Create: `lib/screens/camera_screen.dart`

**Step 1: Create ringing screen**

Create `lib/screens/ringing_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/alarm_history.dart';
import '../storage/alarm_storage.dart';
import 'mission_active_screen.dart';

class RingingScreen extends StatelessWidget {
  final Alarm alarm;
  const RingingScreen({super.key, required this.alarm});

  Future<void> _cheatDismiss(BuildContext context) async {
    final storage = AlarmStorage();
    await storage.init();
    await storage.saveHistory(AlarmHistory(
      id: const Uuid().v4(),
      alarmId: alarm.id,
      firedAt: DateTime.now(),
      status: AlarmStatus.cheated,
    ));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm, size: 64, color: Color(0xFF3D8EFF)),
              const SizedBox(height: 24),
              Text(alarm.timeString,
                  style: const TextStyle(
                      fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(alarm.label,
                  style: const TextStyle(fontSize: 20, color: Colors.white54)),
              const SizedBox(height: 48),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3D8EFF).withOpacity(0.4)),
                ),
                child: Column(children: [
                  const Icon(Icons.directions_walk, color: Color(0xFF3D8EFF)),
                  const SizedBox(height: 8),
                  Text(
                    alarm.missionType == MissionType.distance
                        ? 'Walk ${alarm.radiusMeters.round()}m from home'
                        : 'Reach your pinned location',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Take a photo there to stop this alarm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => MissionActiveScreen(alarm: alarm)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D8EFF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Mission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _cheatDismiss(context),
                child: const Text('Force Stop (counts as cheat)',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Create mission active screen**

Create `lib/screens/mission_active_screen.dart`:
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alarm.dart';
import '../services/gps_service.dart';
import 'camera_screen.dart';

class MissionActiveScreen extends StatefulWidget {
  final Alarm alarm;
  const MissionActiveScreen({super.key, required this.alarm});

  @override
  State<MissionActiveScreen> createState() => _MissionActiveScreenState();
}

class _MissionActiveScreenState extends State<MissionActiveScreen> {
  final _gps = GpsService();
  double _distanceRemaining = double.infinity;
  bool _inRange = false;
  StreamSubscription<Position>? _sub;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sub = _gps.trackLocation().listen((pos) {
      final dist = GpsService.distanceBetween(
        pos.latitude, pos.longitude,
        widget.alarm.targetLat, widget.alarm.targetLng,
      );
      setState(() {
        _distanceRemaining = dist;
        _inRange = dist <= widget.alarm.radiusMeters;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _distanceRemaining == double.infinity
        ? 0.0
        : (1 - (_distanceRemaining / widget.alarm.radiusMeters)).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 200, height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white12,
                    color: _inRange ? Colors.greenAccent : const Color(0xFF3D8EFF),
                  ),
                ),
                Column(children: [
                  Text(
                    _distanceRemaining == double.infinity
                        ? '---'
                        : '${_distanceRemaining.round()}m',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const Text('to go', style: TextStyle(color: Colors.white38)),
                ]),
              ]),
              const SizedBox(height: 48),
              AnimatedOpacity(
                opacity: _inRange ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: _inRange
                      ? () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => CameraScreen(
                              alarm: widget.alarm,
                              startTime: _startTime,
                            )),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  icon: Icon(_inRange ? Icons.camera_alt : Icons.lock),
                  label: Text(
                    _inRange ? 'Take Photo — Dismiss Alarm' : 'Get closer to unlock camera',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Create camera screen**

Create `lib/screens/camera_screen.dart`:
```dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/alarm_history.dart';
import '../storage/alarm_storage.dart';

class CameraScreen extends StatefulWidget {
  final Alarm alarm;
  final DateTime startTime;
  const CameraScreen({super.key, required this.alarm, required this.startTime});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final file = await _controller!.takePicture();

    final storage = AlarmStorage();
    await storage.init();
    final seconds = DateTime.now().difference(widget.startTime).inSeconds;
    await storage.saveHistory(AlarmHistory(
      id: const Uuid().v4(),
      alarmId: widget.alarm.id,
      firedAt: widget.startTime,
      status: AlarmStatus.completed,
      photoPath: file.path,
      secondsToComplete: seconds,
    ));

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller?.value.isInitialized == true
          ? Stack(children: [
              CameraPreview(_controller!),
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 4),
                      ),
                      child: const Icon(Icons.camera_alt, size: 36, color: Colors.black),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 60, left: 0, right: 0,
                child: Text('Take a photo to dismiss the alarm',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ])
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
```

**Step 4: Verify compilation**

```bash
flutter build apk --debug
```
Expected: BUILD SUCCESSFUL

**Step 5: Commit**

```bash
git add lib/screens/
git commit -m "feat: add ringing, mission active, and camera screens"
```

---

## Task 13: Stats Screen

**Files:**
- Create: `lib/screens/stats_screen.dart`

**Step 1: Create stats screen**

Create `lib/screens/stats_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_history.dart';
import '../storage/alarm_storage.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = AlarmStorage();
    storage.init();

    final history = storage.getAllHistory()
      ..sort((a, b) => b.firedAt.compareTo(a.firedAt));
    final streak = storage.getCurrentStreak();
    final cheats = storage.getTotalCheats();
    final total = history.length;
    final completed = history.where((h) => h.status == AlarmStatus.completed).length;
    final rate = total == 0 ? 0 : (completed / total * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Stats', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _StatCard(label: 'Streak', value: '$streak days', color: const Color(0xFF3D8EFF)),
            const SizedBox(width: 12),
            _StatCard(label: 'Completion', value: '$rate%', color: Colors.greenAccent),
            const SizedBox(width: 12),
            _StatCard(label: 'Cheats', value: '$cheats', color: Colors.redAccent),
          ]),
          const SizedBox(height: 24),
          const Text('History', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          ...history.map((h) => _HistoryTile(history: h)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AlarmHistory history;
  const _HistoryTile({required this.history});

  @override
  Widget build(BuildContext context) {
    final isCompleted = history.status == AlarmStatus.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.cancel,
          color: isCompleted ? Colors.greenAccent : Colors.redAccent,
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            DateFormat('EEE, MMM d · HH:mm').format(history.firedAt),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (history.secondsToComplete != null)
            Text('Completed in ${history.secondsToComplete}s',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          if (history.status == AlarmStatus.cheated)
            const Text('Force stopped', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ]),
      ]),
    );
  }
}
```

**Step 2: Run all tests**

```bash
flutter test
```
Expected: All tests PASS

**Step 3: Build and smoke-test on device**

```bash
flutter run
```
Manually verify:
- Create an alarm
- Alarm appears on home screen
- Stats screen opens
- Onboarding shows on fresh install

**Step 4: Commit**

```bash
git add lib/screens/stats_screen.dart
git commit -m "feat: add stats screen with streak, completion rate, and history"
```

---

## Task 14: Open Source Setup

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `.gitignore` updates

**Step 1: Create README.md**

Create `README.md`:
```markdown
# BedBreaker

An alarm clock that only stops when you get up and go somewhere.

Set a mission — walk 500m from home, or reach a pinned location. When you arrive, take a photo. That's the only way to stop it.

## Features
- GPS-verified alarm dismissal
- Distance from home or map-pinned target
- Photo proof at destination
- Cheat counter (force dismiss is logged, not blocked)
- Streak tracking
- 100% free, no backend, no accounts

## Built With
- Flutter
- Hive (local storage)
- OpenStreetMap (flutter_map)
- geolocator
- Google Stitch (UI design)

## Build & Run

```bash
git clone https://github.com/YOUR_USERNAME/bedbreaker
cd bedbreaker
flutter pub get
flutter run
```

No API keys needed. No accounts. Just clone and run.

## Contributing
PRs welcome. Open an issue first for major changes.

## License
MIT
```

**Step 2: Create MIT LICENSE**

Create `LICENSE`:
```
MIT License

Copyright (c) 2026 BedBreaker Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Step 3: Final commit**

```bash
git add README.md LICENSE
git commit -m "docs: add README and MIT license for open source release"
```

**Step 4: Create GitHub repo and push**

```bash
gh repo create bedbreaker --public --description "Alarm clock that only stops when you get up and go somewhere"
git remote add origin https://github.com/YOUR_USERNAME/bedbreaker.git
git push -u origin main
```

---

## Build Order Summary

1. Flutter project + folder structure
2. Android permissions config
3. Alarm model
4. AlarmHistory model
5. Hive storage service
6. GPS service
7. Alarm scheduler service
8. **Google Stitch UI design** (do before any screen code)
9. Permissions onboarding
10. Home screen
11. Create alarm + mission setup screens
12. Ringing + mission active + camera screens
13. Stats screen
14. Open source setup (README, LICENSE, GitHub)

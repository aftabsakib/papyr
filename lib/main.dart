import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/alarm.dart';
import 'models/alarm_history.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/ringing_screen.dart';
import 'services/alarm_scheduler.dart';
import 'storage/alarm_storage.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse details) {
  // Background tap handled on next app open via getNotificationAppLaunchDetails
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmAdapter());
  Hive.registerAdapter(AlarmHistoryAdapter());
  Hive.registerAdapter(MissionTypeAdapter());
  Hive.registerAdapter(AlarmStatusAdapter());

  try {
    await AlarmScheduler.init(
      onNotificationTap: _handleNotificationTap,
      onBackgroundNotificationTap: _onBackgroundNotificationTap,
    );
  } catch (_) {};

  runApp(const BedBreakerApp());
}

void _handleNotificationTap(NotificationResponse details) {
  final payload = details.payload;
  if (payload == null || payload.isEmpty) return;
  _navigateToRinging(payload);
}

Future<void> _navigateToRinging(String alarmUuid) async {
  final storage = AlarmStorage();
  await storage.init();
  final alarm = storage.getAlarm(alarmUuid);
  if (alarm == null) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => RingingScreen(alarm: alarm)),
      (route) => route.isFirst,
    );
  });
}

class BedBreakerApp extends StatelessWidget {
  const BedBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'BedBreaker',
      debugShowCheckedModeBanner: false,
      theme: BedBreakerTheme.dark,
      home: const _AppEntryPoint(),
    );
  }
}

class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkLaunch();
  }

  Future<void> _checkLaunch() async {
    try {
      final details = await FlutterLocalNotificationsPlugin()
          .getNotificationAppLaunchDetails()
          .timeout(const Duration(seconds: 3));
      if (details?.didNotificationLaunchApp == true) {
        final payload = details!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          await _navigateToRinging(payload);
        }
      }
    } catch (_) {
      // Never block app open on notification check failure
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: BedBreakerTheme.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: BedBreakerTheme.accent),
        ),
      );
    }
    return FutureBuilder<bool>(
      future: _permissionsGranted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: BedBreakerTheme.bgPrimary,
            body: Center(
              child: CircularProgressIndicator(color: BedBreakerTheme.accent),
            ),
          );
        }
        return snapshot.data! ? const HomeScreen() : const OnboardingScreen();
      },
    );
  }

  Future<bool> _permissionsGranted() async {
    return await Permission.camera.isGranted &&
        await Permission.notification.isGranted;
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/alarm.dart';
import 'models/alarm_history.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

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
      debugShowCheckedModeBanner: false,
      theme: BedBreakerTheme.dark,
      home: FutureBuilder<bool>(
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
      ),
    );
  }

  Future<bool> _permissionsGranted() async {
    return await Permission.locationAlways.isGranted &&
        await Permission.camera.isGranted &&
        await Permission.notification.isGranted;
  }
}

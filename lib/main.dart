import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/alarm.dart';
import 'models/alarm_history.dart';

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
      home: const Scaffold(
        body: Center(child: Text('BedBreaker', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900))),
      ),
    );
  }
}

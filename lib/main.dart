import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdfrx/pdfrx.dart';

import 'models/book.dart';
import 'screens/library_screen.dart';
import 'services/library_store.dart';
import 'services/settings_store.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(BookAdapter());
  Hive.registerAdapter(BookFormatAdapter());

  // Warm up the PDF engine so the first cover render / open is snappy.
  await pdfrxFlutterInitialize();

  final settings = await SettingsStore.open();
  final library = await LibraryStore.open();
  final themeController = ThemeController(settings);

  runApp(PapyrApp(
    themeController: themeController,
    settings: settings,
    library: library,
  ));
}

class PapyrApp extends StatelessWidget {
  const PapyrApp({
    super.key,
    required this.themeController,
    required this.settings,
    required this.library,
  });

  final ThemeController themeController;
  final SettingsStore settings;
  final LibraryStore library;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final palette = themeController.palette;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                palette.isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: palette.page,
            systemNavigationBarIconBrightness:
                palette.isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return MaterialApp(
          title: 'Papyr',
          debugShowCheckedModeBanner: false,
          theme: PapyrTheme.build(palette),
          home: LibraryScreen(
            themeController: themeController,
            settings: settings,
            library: library,
          ),
        );
      },
    );
  }
}

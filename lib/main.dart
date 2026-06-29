import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/library_screen.dart';
import 'services/settings_store.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settings = await SettingsStore.open();
  final themeController = ThemeController(settings);
  runApp(PapyrApp(themeController: themeController, settings: settings));
}

class PapyrApp extends StatelessWidget {
  const PapyrApp({
    super.key,
    required this.themeController,
    required this.settings,
  });

  final ThemeController themeController;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final palette = themeController.palette;
        // Match the system status/navigation bars to the current paper.
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
          ),
        );
      },
    );
  }
}

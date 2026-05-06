import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'data/services/firebase/firebase_providers.dart';
import 'core/guards/global_app_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await authService.initPersistence();
  await pushNavigationService.init();
  foregroundNotificationService.init();

  final darkMode = await appStateService.isDarkMode();

  runApp(AmedsporApp(initialDarkMode: darkMode));
}

class AmedsporApp extends StatefulWidget {
  final bool initialDarkMode;

  const AmedsporApp({super.key, this.initialDarkMode = true});

  static AmedsporAppController of(BuildContext context) {
    final state = context.findAncestorStateOfType<AmedsporAppController>();
    if (state == null) {
      throw StateError('AmedsporApp state not found');
    }
    return state;
  }

  @override
  State<AmedsporApp> createState() => AmedsporAppController();
}

class AmedsporAppController extends State<AmedsporApp> {
  late bool darkMode;

  @override
  void initState() {
    super.initState();
    darkMode = widget.initialDarkMode;
  }

  Future<void> setDarkMode(bool value) async {
    setState(() => darkMode = value);
    await appStateService.setDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Amedspor',
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => GlobalAppGuard(child: child!),
    );
  }
}

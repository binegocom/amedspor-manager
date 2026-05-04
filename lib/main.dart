import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'data/services/firebase/firebase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await fcmService.init();
  await pushNavigationService.init();
  foregroundNotificationService.init();


  


  runApp(const AmedsporApp());
}

class AmedsporApp extends StatelessWidget {
  const AmedsporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Amedspor',
      routerConfig: appRouter,
      theme: AppTheme.darkTheme,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'data/services/firebase/firebase_providers.dart';
import 'core/errors/error_reporting_service.dart';
import 'core/guards/global_app_guard.dart';

/// Background message handler (top-level static function required by Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Handle background message if needed
  if (kDebugMode) {
    print('Background message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Firestore Settings
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // FCM Token Refresh Handler - Auto-update Firestore when token changes
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      final user = authService.currentUser;
      if (user != null && newToken.isNotEmpty) {
        await firestoreService.users.doc(user.uid).update({
          'fcmToken': newToken,
          'lastFcmTokenUpdate': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          print('FCM token updated for user ${user.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update FCM token: $e');
      }
    }
  });

  // 3. Global Error Handling
  FlutterError.onError = ErrorReportingService.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReportingService.recordError(error, stack, fatal: true);
    return true;
  };

  // 4. Initialization
  await authService.initPersistence();
  await fcmService.init();
  await pushNavigationService.init();
  foregroundNotificationService.init();

  final darkMode = await appStateService.isDarkMode();

  runApp(ProviderScope(child: AmedsporApp(initialDarkMode: darkMode)));
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

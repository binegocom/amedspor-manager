import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/services/firebase/firebase_providers.dart';

class ErrorReportingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Throttle Firestore writes to prevent cost bombs during cascading failures
  static int _writeCount = 0;
  static DateTime _windowStart = DateTime.now();
  static const int _maxWritesPerMinute = 10;

  static Future<void> recordError(dynamic error, StackTrace? stack, {String? reason, bool fatal = false}) async {
    if (kDebugMode) {
      print('Reporting Error: $error');
      if (stack != null) print(stack);
    }

    // 1. Record to Crashlytics (if not Web) — always, no throttle
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: fatal);
    }

    // 2. Record to Firestore errorReports collection — throttled
    try {
      // Throttle: max 10 writes per minute to prevent cost explosion
      final now = DateTime.now();
      if (now.difference(_windowStart).inSeconds > 60) {
        _writeCount = 0;
        _windowStart = now;
      }
      if (_writeCount >= _maxWritesPerMinute) {
        if (kDebugMode) print('ErrorReportingService: Throttled — skipping Firestore write');
        return;
      }
      _writeCount++;

      final user = authService.currentUser;
      final packageInfo = await PackageInfo.fromPlatform();
      
      await _firestore.collection('errorReports').add({
        'error': error.toString(),
        'stackTrace': stack?.toString(),
        'reason': reason,
        'fatal': fatal,
        'userId': user?.uid,
        'userEmail': user?.email,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'severity': fatal ? 'critical' : 'medium',
      });
    } catch (e) {
      if (kDebugMode) print('ErrorReportingService: Failed to record error to Firestore: $e');
    }
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    recordError(details.exception, details.stack, reason: details.context?.toString(), fatal: true);
  }

  static Future<void> log(String message) async {
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.log(message);
    }
    if (kDebugMode) print('Log: $message');
  }

  static Future<void> setUserIdentifier(String identifier) async {
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    }
  }
}

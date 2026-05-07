import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/services/firebase/firebase_providers.dart';

class ErrorReportingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> recordError(dynamic error, StackTrace? stack, {String? reason, bool fatal = false}) async {
    if (kDebugMode) {
      print('Reporting Error: $error');
      if (stack != null) print(stack);
    }

    // 1. Record to Crashlytics (if not Web)
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: fatal);
    }

    // 2. Record to Firestore errorReports collection
    try {
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

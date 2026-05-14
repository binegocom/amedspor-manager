import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  FcmService(this._messaging);

  final FirebaseMessaging _messaging;

  /// Initialize FCM and request permissions
  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setAutoInitEnabled(true);
  }

  /// Get the current FCM token
  Future<String?> getToken() {
    return _messaging.getToken();
  }

  /// Stream of foreground messages
  Stream<RemoteMessage> foregroundMessages() {
    return FirebaseMessaging.onMessage;
  }

  /// Stream of notification clicks (when app is in foreground/background)
  Stream<RemoteMessage> notificationClicks() {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  /// Get the initial message that opened the app
  Future<RemoteMessage?> initialMessage() {
    return _messaging.getInitialMessage();
  }

  /// Stream of token refreshes
  Stream<String> tokenRefreshes() {
    return _messaging.onTokenRefresh;
  }
}

/// Background message handler (must be a top-level function).
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background işlemleri buraya gelecek.
}

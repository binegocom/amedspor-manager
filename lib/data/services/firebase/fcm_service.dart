import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  FcmService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.setAutoInitEnabled(true);
  }

  Future<String?> getToken() {
    return _messaging.getToken();
  }

  Stream<RemoteMessage> foregroundMessages() {
    return FirebaseMessaging.onMessage;
  }

  Stream<RemoteMessage> notificationClicks() {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  Future<RemoteMessage?> initialMessage() {
    return _messaging.getInitialMessage();
  }

  Stream<String> tokenRefreshes() {
    return _messaging.onTokenRefresh;
  }
}

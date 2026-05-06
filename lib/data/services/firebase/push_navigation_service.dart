import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/router/app_router.dart';
import 'firebase_providers.dart';

class PushNavigationService {
  Future<void> init() async {
    final initialMessage = await fcmService.initialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    fcmService.notificationClicks().listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final route = message.data['route'];

    if (route == null || route is! String || route.isEmpty) {
      appRouter.go('/notifications');
      return;
    }

    appRouter.go(route);
  }
}

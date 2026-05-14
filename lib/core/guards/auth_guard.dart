import '../../data/services/firebase/firebase_providers.dart';

class AuthGuard {
  static const List<String> authRequiredRoutes = [
    '/profile-setup',
    '/create-post',
    '/notifications',
    '/feedback',
    '/reports',
  ];

  static String? redirect(String location) {
    final user = authService.currentUser;
    final bool isAuthRequired = authRequiredRoutes.any(
      (r) => location.startsWith(r),
    );

    if (isAuthRequired && user == null) {
      return '/login';
    }

    if (location == '/login' && user != null) {
      return '/home';
    }

    if (location == '/profile-setup' && user == null) {
      return '/login';
    }

    return null;
  }
}

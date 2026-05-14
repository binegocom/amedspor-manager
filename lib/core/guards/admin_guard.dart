import 'package:flutter/foundation.dart';

import '../../data/services/firebase/firebase_providers.dart';

class AdminGuard {
  static Future<bool> isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    try {
      // Custom Claims Verification as Primary Security Boundary
      final idTokenResult = await user.getIdTokenResult(true);
      final claims = idTokenResult.claims;
      if (claims?['admin'] == true || claims?['role'] == 'admin') {
        return true;
      }

      // Fallback read to Firestore profile cache view if claims not deployed locally
      final doc = await firestoreService.users.doc(user.uid).get();
      return doc.data()?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isAdminOrModerator() async {
    final user = authService.currentUser;
    if (user == null) return false;

    try {
      final idTokenResult = await user.getIdTokenResult(true);
      final claims = idTokenResult.claims;
      final roleClaim = claims?['role'];
      if (claims?['admin'] == true || roleClaim == 'admin' || roleClaim == 'moderator') {
        return true;
      }

      final doc = await firestoreService.users.doc(user.uid).get();
      final role = doc.data()?['role'];
      return role == 'admin' || role == 'moderator';
    } catch (e) {
      return false;
    }
  }

  static Future<String?> redirect(String location) async {
    if (!location.startsWith('/admin')) return null;

    if (!kIsWeb) return '/home';

    final user = authService.currentUser;
    if (user == null) return '/login';

    final isAuthorized = await isAdminOrModerator();
    if (!isAuthorized) return '/home';

    return null;
  }
}

import '../../../data/services/firebase/firebase_providers.dart';

class AdminGuard {
  static Future<bool> isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    try {
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
      final doc = await firestoreService.users.doc(user.uid).get();
      final role = doc.data()?['role'];
      return role == 'admin' || role == 'moderator';
    } catch (e) {
      return false;
    }
  }
}

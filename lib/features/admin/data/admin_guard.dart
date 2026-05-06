import '../../../data/services/firebase/firebase_providers.dart';

class AdminGuard {
  static Future<bool> isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  static Future<bool> isAdminOrModerator() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    final role = doc.data()?['role'];

    return role == 'admin' || role == 'moderator';
  }
}

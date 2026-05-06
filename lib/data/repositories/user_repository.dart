import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_model.dart';
import '../services/firebase/firebase_providers.dart';

class UserRepository {
  Future<void> createOrUpdateUser(AppUserModel user) async {
    await firestoreService.users
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUserModel?> getUser(String userId) async {
    final doc = await firestoreService.users.doc(userId).get();

    if (!doc.exists || doc.data() == null) return null;

    return AppUserModel.fromMap(doc.id, doc.data()!);
  }

  // 🔥 Leaderboard stream
  Stream<List<AppUserModel>> watchLeaderboard() {
    return firestoreService.users
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUserModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}

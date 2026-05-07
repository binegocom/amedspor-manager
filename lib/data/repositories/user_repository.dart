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

  Future<void> updateNotificationPrefs(String userId, Map<String, bool> prefs) async {
    await firestoreService.users.doc(userId).update({
      'notificationPrefs': prefs,
    });
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final doc = await firestoreService.users
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    final batch = FirebaseFirestore.instance.batch();

    final currentUserRef = firestoreService.users.doc(currentUserId);
    final targetUserRef = firestoreService.users.doc(targetUserId);

    final followingRef = currentUserRef.collection('following').doc(targetUserId);
    final followersRef = targetUserRef.collection('followers').doc(currentUserId);

    batch.set(followingRef, {'createdAt': FieldValue.serverTimestamp()});
    batch.set(followersRef, {'createdAt': FieldValue.serverTimestamp()});

    batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
    batch.update(targetUserRef, {'followersCount': FieldValue.increment(1)});

    await batch.commit();
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = FirebaseFirestore.instance.batch();

    final currentUserRef = firestoreService.users.doc(currentUserId);
    final targetUserRef = firestoreService.users.doc(targetUserId);

    final followingRef = currentUserRef.collection('following').doc(targetUserId);
    final followersRef = targetUserRef.collection('followers').doc(currentUserId);

    batch.delete(followingRef);
    batch.delete(followersRef);

    batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
    batch.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});

    await batch.commit();
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

  Future<QuerySnapshot> getUsersSnapshotPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
  }) async {
    Query query = firestoreService.users.orderBy('createdAt', descending: true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Simple prefix search for username
      query = firestoreService.users
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .limit(limit);
    } else {
      query = query.limit(limit);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
    }

    return await query.get();
  }
}

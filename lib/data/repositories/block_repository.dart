import 'package:cloud_firestore/cloud_firestore.dart';

class BlockRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> blockUser(String currentUserId, String targetUserId) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(targetUserId)
        .set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(targetUserId)
        .delete();
  }

  Stream<List<String>> getBlockedUserIds(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(targetUserId)
        .get();
    return doc.exists;
  }
}

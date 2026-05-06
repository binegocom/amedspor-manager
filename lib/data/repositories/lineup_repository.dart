import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lineup_model.dart';
import '../models/comment_model.dart';
import '../services/firebase/firebase_providers.dart';

class LineupRepository {
  Future<void> saveLineup(LineupModel lineup) async {
    await firestoreService.lineups.doc(lineup.id).set(lineup.toMap());

    // Grant Badge: Acemi Teknik Direktör
    final userDoc = await firestoreService.users.doc(lineup.userId).get();
    final badges = List<String>.from(userDoc.data()?['badges'] ?? []);
    if (!badges.contains('Acemi Teknik Direktör')) {
      await firestoreService.users.doc(lineup.userId).update({
        'badges': FieldValue.arrayUnion(['Acemi Teknik Direktör']),
        'points': FieldValue.increment(20), // Bonus points for first badge
      });
    }
  }

  Stream<List<LineupModel>> watchUserLineups(String userId) {
    return firestoreService.lineups
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => LineupModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Stream<List<LineupModel>> watchMatchLineups(String matchId) {
    return firestoreService.lineups
        .where('matchId', isEqualTo: matchId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => LineupModel.fromMap(doc.id, doc.data()))
              .toList();

          items.sort((a, b) => b.likes.compareTo(a.likes));
          return items;
        });
  }

  Future<LineupModel?> getLineup(String id) async {
    final doc = await firestoreService.lineups.doc(id).get();
    if (!doc.exists) return null;
    return LineupModel.fromMap(doc.id, doc.data()!);
  }

  Future<bool> likeLineup({
    required String lineupId,
    required String userId, // Current user who likes
  }) async {
    final lineupRef = firestoreService.lineups.doc(lineupId);
    final likeRef = firestoreService.lineupLikes(lineupId).doc(userId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      if (likeDoc.exists) return false;

      final lineupDoc = await transaction.get(lineupRef);
      if (!lineupDoc.exists) return false;

      final lineupData = lineupDoc.data()!;
      final currentLikes = (lineupData['likes'] ?? 0) as int;
      final ownerId = lineupData['userId'] as String;

      // Add like record
      transaction.set(likeRef, {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment likes
      transaction.update(lineupRef, {
        'likes': FieldValue.increment(1),
      });

      // Grant Badge & Notification: Popüler Teknik Direktör (at 10 likes)
      if (currentLikes + 1 == 10 && ownerId.isNotEmpty) {
        final userRef = firestoreService.users.doc(ownerId);
        final notificationRef = firestoreService.notifications.doc();

        transaction.update(userRef, {
          'points': FieldValue.increment(25),
          'badges': FieldValue.arrayUnion(['Popüler Teknik Direktör']),
        });

        transaction.set(notificationRef, {
          'userId': ownerId,
          'title': 'Yeni rozet kazandın!',
          'message':
              'Kadron 10 beğeni aldı. Popüler Teknik Direktör rozeti kazandın.',
          'type': 'lineup',
          'targetRoute': '/lineup-detail/$lineupId',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      return true;
    });
  }

  Stream<List<LineupModel>> watchTopLineups() {
    return firestoreService.lineups
        .orderBy('likes', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LineupModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<LineupModel>> watchAllLineups() {
    return firestoreService.lineups.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => LineupModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<CommentModel>> watchComments(String lineupId) {
    return firestoreService
        .lineupComments(lineupId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addComment({
    required String lineupId,
    required CommentModel comment,
  }) async {
    final lineupRef = firestoreService.lineups.doc(lineupId);
    final commentRef = firestoreService.lineupComments(lineupId).doc(comment.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(lineupRef, {'commentsCount': FieldValue.increment(1)});
    });
  }

  Stream<List<CommentModel>> watchLineupComments(String lineupId) {
    return firestoreService
        .lineupComments(lineupId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addLineupComment({
    required String lineupId,
    required CommentModel comment,
  }) async {
    final lineupRef = firestoreService.lineups.doc(lineupId);
    final commentRef = firestoreService.lineupComments(lineupId).doc(comment.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(lineupRef, {'commentsCount': FieldValue.increment(1)});
    });
  }

  Future<void> selectWeeklyWinner(String lineupId, String userId) async {
    await firestoreService.users.doc(userId).update({
      'points': FieldValue.increment(100),
      'badges': FieldValue.arrayUnion(['Haftanın Hocası']),
    });

    // Mark the lineup as weekly winner (optional metadata)
    await firestoreService.lineups.doc(lineupId).update({
      'isWeeklyWinner': true,
    });
  }
}

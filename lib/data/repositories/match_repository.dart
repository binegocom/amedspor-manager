import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/match_event_model.dart';
import '../services/firebase/firebase_providers.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MatchModel>> watchMatches() {
    // Tüm maçları çekmek yerine performansı korumak için tarih sırasına göre son 30 maçı getiriyoruz.
    return _firestore
        .collection('matches')
        .orderBy('matchDate', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map<MatchModel>((doc) => MatchModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<MatchModel?> watchMatch(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromFirestore(doc) : null);
  }

  Future<MatchModel?> getMatch(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    if (!doc.exists) return null;
    return MatchModel.fromFirestore(doc);
  }

  Future<void> updateMatchLive({
    required String matchId,
    required int homeScore,
    required int awayScore,
    required int minute,
    required String status,
  }) async {
    await _firestore.collection('matches').doc(matchId).update({
      'homeScore': homeScore,
      'awayScore': awayScore,
      'minute': minute,
      'status': status,
    });
  }

  Stream<List<MatchEventModel>> watchMatchEvents(String matchId) {
    return firestoreService
        .matchEvents(matchId)
        .orderBy('minute', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchEventModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addMatchEvent({
    required String matchId,
    required MatchEventModel event,
  }) async {
    await firestoreService.matchEvents(matchId).doc(event.id).set(event.toMap());
  }

  Future<void> toggleMotmVoting(String matchId, bool active) async {
    await _firestore.collection('matches').doc(matchId).update({
      'isMotmVotingActive': active,
    });
  }

  Future<void> updateMotmCandidates(String matchId, List<String> candidates) async {
    await _firestore.collection('matches').doc(matchId).update({
      'motmCandidates': candidates,
      'motmResults': {for (var c in candidates) c: 0},
    });
  }

  Future<bool> voteForMotm({
    required String matchId,
    required String userId,
    required String candidate,
  }) async {
    final matchRef = _firestore.collection('matches').doc(matchId);
    final voteRef = firestoreService.motmVotes(matchId).doc(userId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final voteDoc = await transaction.get(voteRef);
      if (voteDoc.exists) return false;

      final matchDoc = await transaction.get(matchRef);
      if (!matchDoc.exists) return false;

      final results = Map<String, int>.from(matchDoc.data()?['motmResults'] ?? {});
      results[candidate] = (results[candidate] ?? 0) + 1;

      transaction.set(voteRef, {
        'candidate': candidate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(matchRef, {'motmResults': results});
      return true;
    });
  }

  Future<String?> getUserMotmVote(String matchId, String userId) async {
    final doc = await firestoreService.motmVotes(matchId).doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['candidate'];
  }

  Future<void> deleteMatch(String matchId) async {
    await _firestore.collection('matches').doc(matchId).delete();
  }
}
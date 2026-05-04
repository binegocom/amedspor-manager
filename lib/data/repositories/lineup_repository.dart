import '../models/lineup_model.dart';
import '../services/firebase/firebase_providers.dart';

class LineupRepository {
  Future<void> saveLineup(LineupModel lineup) async {
    await firestoreService.lineups.doc(lineup.id).set(lineup.toMap());
  }

  Stream<List<LineupModel>> watchUserLineups(String userId) {
    return firestoreService.lineups
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LineupModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<LineupModel>> watchMatchLineups(String matchId) {
    return firestoreService.lineups
        .where('matchId', isEqualTo: matchId)
        .orderBy('likes', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LineupModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
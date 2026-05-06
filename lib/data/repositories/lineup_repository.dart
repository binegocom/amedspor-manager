import '../models/lineup_model.dart';
import '../services/firebase/firebase_providers.dart';

class LineupRepository {
  Future<void> saveLineup(LineupModel lineup) async {
    await firestoreService.lineups.doc(lineup.id).set(lineup.toMap());
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
}

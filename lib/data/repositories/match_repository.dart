import '../models/match_model.dart';
import '../services/firebase/firebase_providers.dart';

class MatchRepository {
  Stream<List<MatchModel>> watchMatches() {
    return firestoreService.matches
        .orderBy('matchDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MatchModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<MatchModel?> getMatch(String matchId) async {
    final doc = await firestoreService.matches.doc(matchId).get();

    if (!doc.exists || doc.data() == null) return null;

    return MatchModel.fromMap(doc.id, doc.data()!);
  }
}
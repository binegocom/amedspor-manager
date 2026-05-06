import '../models/player_model.dart';
import '../services/firebase/firebase_providers.dart';

class PlayerRepository {
  Stream<List<PlayerModel>> watchActivePlayers() {
    return firestoreService.players
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlayerModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PlayerModel>> watchAllPlayers() {
    return firestoreService.players.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PlayerModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> createPlayer(PlayerModel player) async {
    await firestoreService.players.doc(player.id).set(player.toMap());
  }

  Future<void> updatePlayer(PlayerModel player) async {
    await firestoreService.players.doc(player.id).update(player.toMap());
  }

  Future<void> deletePlayer(String playerId) async {
    await firestoreService.players.doc(playerId).delete();
  }
}

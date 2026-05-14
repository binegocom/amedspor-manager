import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../services/firebase/firebase_providers.dart';

class PlayerRepository {
  Stream<List<PlayerModel>> watchActivePlayers({String? ownerId}) {
    var query = firestoreService.players.where('active', isEqualTo: true);
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => PlayerModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Stream<List<PlayerModel>> watchAllPlayers() {
    return firestoreService.players
        .limit(100)
        .snapshots()
        .map(
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

  Future<void> updatePlayersAfterMatch(List<PlayerModel> playersToUpdate) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final p in playersToUpdate) {
      batch.update(FirebaseFirestore.instance.collection('players').doc(p.id), {
        'injured': p.injured,
        'injuryDays': p.injuryDays,
        'suspended': p.suspended,
        'suspensionMatches': p.suspensionMatches,
        'yellowCards': p.yellowCards,
      });
    }
    await batch.commit();
  }

  Future<PlayerModel?> getPlayer(String id) async {
    final doc = await firestoreService.players.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return PlayerModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}

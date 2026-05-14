import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/youth_player_model.dart';
import '../models/youth_academy_model.dart';
import '../services/firebase/firebase_providers.dart';

class YouthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _academyRef(String clubId) => 
      _firestore.collection('clubs').doc(clubId).collection('academy');

  Future<void> updateAcademy(YouthAcademyModel academy) async {
    await _firestore.collection('clubs').doc(academy.clubId).update({
      'youthAcademy': academy.toMap(),
    });
  }

  Future<void> addYouthPlayer(String clubId, YouthPlayerModel player) async {
    await _academyRef(clubId).doc(player.id).set(player.toMap());
  }

  Stream<List<YouthPlayerModel>> watchYouthPlayers(String clubId) {
    return _academyRef(clubId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => 
          YouthPlayerModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> updateYouthPlayer(String clubId, YouthPlayerModel player) async {
    await _academyRef(clubId).doc(player.id).update(player.toMap());
  }

  Future<void> removeYouthPlayer(String clubId, String playerId) async {
    await _academyRef(clubId).doc(playerId).delete();
  }
}

// Küresel ve önbelleklenmiş akademi oyuncuları sağlayıcısı
final youthPlayersStreamProvider = StreamProvider.autoDispose<List<YouthPlayerModel>>((ref) {
  final user = authService.currentUser;
  if (user == null) return Stream.value([]);
  return YouthRepository().watchYouthPlayers(user.uid);
});

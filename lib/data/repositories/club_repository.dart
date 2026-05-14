import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/club_model.dart';
import '../services/firebase/firebase_providers.dart';
class ClubRepository {
  final CollectionReference _clubsRef = FirebaseFirestore.instance.collection('clubs');

  Future<void> createClub(ClubModel club) async {
    await _clubsRef.doc(club.id).set(club.toMap());
  }

  Future<ClubModel?> getClub(String clubId) async {
    final doc = await _clubsRef.doc(clubId).get();
    if (!doc.exists) return null;
    return ClubModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Stream<ClubModel?> watchClub(String clubId) {
    return _clubsRef.doc(clubId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClubModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> updateClub(ClubModel club) async {
    await _clubsRef.doc(club.id).update(club.toMap());
  }

  Future<void> updateResources(String clubId, {int? tokens, int? cash}) async {
    final Map<String, dynamic> updates = {
      'lastResourceUpdate': FieldValue.serverTimestamp(),
    };
    if (tokens != null) updates['tokens'] = FieldValue.increment(tokens);
    if (cash != null) updates['cash'] = FieldValue.increment(cash);
    
    await _clubsRef.doc(clubId).update(updates);
  }
}

final currentClubStreamProvider = StreamProvider.autoDispose<ClubModel?>((ref) {
  final user = authService.currentUser;
  if (user == null) return Stream.value(null);
  return ClubRepository().watchClub(user.uid);
});

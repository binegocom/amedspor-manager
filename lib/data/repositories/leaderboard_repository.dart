import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _leaderboardRef =>
      _firestore.collection('leaderboard');

  Future<LeaderboardModel?> getLeaderboardEntry(String userId) async {
    try {
      final doc = await _leaderboardRef.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return LeaderboardModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      // Handle error
      return null;
    }
  }

  Future<void> updateMatchResult({
    required String userId,
    required String username,
    required int opponentElo,
    required int goalsFor,
    required int goalsAgainst,
  }) async {
    try {
      final docRef = _leaderboardRef.doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        LeaderboardModel currentEntry;
        if (docSnapshot.exists && docSnapshot.data() != null) {
          currentEntry = LeaderboardModel.fromMap(
              docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
        } else {
          currentEntry = LeaderboardModel(
            userId: userId,
            username: username,
            updatedAt: DateTime.now(),
          );
        }

        double result = 0.5; // Draw
        int winInc = 0;
        int lossInc = 0;
        int drawInc = 0;

        if (goalsFor > goalsAgainst) {
          result = 1.0;
          winInc = 1;
        } else if (goalsFor < goalsAgainst) {
          result = 0.0;
          lossInc = 1;
        } else {
          drawInc = 1;
        }

        final newElo = LeaderboardModel.calculateNewElo(
            currentEntry.eloScore, opponentElo, result);
        
        // Basit bir küme düşme/çıkma mantığı
        int newLeagueLevel = currentEntry.leagueLevel;
        if (newElo >= 1500 && newLeagueLevel > 1) {
          newLeagueLevel = 1; // Süper Lig
        } else if (newElo >= 1200 && newElo < 1500 && newLeagueLevel != 2) {
          newLeagueLevel = 2; // 1. Lig
        } else if (newElo < 1200 && newLeagueLevel != 3) {
          newLeagueLevel = 3; // Akademi Kümesi
        }

        final updatedEntry = LeaderboardModel(
          userId: userId,
          username: username,
          eloScore: newElo,
          leagueLevel: newLeagueLevel,
          wins: currentEntry.wins + winInc,
          losses: currentEntry.losses + lossInc,
          draws: currentEntry.draws + drawInc,
          goalDifference: currentEntry.goalDifference + (goalsFor - goalsAgainst),
          updatedAt: DateTime.now(),
        );

        transaction.set(docRef, updatedEntry.toMap(), SetOptions(merge: true));
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<List<LeaderboardModel>> getTopPlayers({int limit = 100, int? leagueLevel}) async {
    try {
      Query query = _leaderboardRef.orderBy('eloScore', descending: true).limit(limit);
      
      if (leagueLevel != null) {
        query = query.where('leagueLevel', isEqualTo: leagueLevel);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => LeaderboardModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      // Handle error
      return [];
    }
  }

  Stream<List<LeaderboardModel>> watchLeaderboard(int leagueLevel, {int limit = 100}) {
    return _leaderboardRef
        .where('leagueLevel', isEqualTo: leagueLevel)
        .orderBy('eloScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaderboardModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}

// Küresel ve önbelleklenmiş liderlik tablosu akışı (Lig seviyesine göre family provider)
final leaderboardStreamProvider = StreamProvider.family.autoDispose<List<LeaderboardModel>, int>((ref, leagueLevel) {
  return LeaderboardRepository().watchLeaderboard(leagueLevel);
});

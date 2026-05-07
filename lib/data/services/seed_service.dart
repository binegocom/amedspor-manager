import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../repositories/player_repository.dart';

class SeedService {
  final FirebaseFirestore _db;
  final _playerRepo = PlayerRepository();

  SeedService(this._db);

  Future<void> seedInitialData() async {
    try {
      await _seedMatches();
      await _seedChatRooms();
      await _seedPosts();
    } on FirebaseException catch (e) {
      debugPrint('Seed Firestore error: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Seed unknown error: $e');
    }
  }

  Future<void> _seedMatches() async {
    final matches = [
      {
        'id': 'match_001',
        'homeTeam': 'Amedspor',
        'awayTeam': 'Altay',
        'matchDate': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
        'status': 'upcoming',
        'score': '',
      },
      {
        'id': 'match_002',
        'homeTeam': 'Amedspor',
        'awayTeam': 'Sakaryaspor',
        'matchDate': DateTime.now()
            .add(const Duration(days: 10))
            .toIso8601String(),
        'status': 'upcoming',
        'score': '',
      },
    ];

    for (final match in matches) {
      final id = match['id'] as String;
      await _db
          .collection('matches')
          .doc(id)
          .set(match, SetOptions(merge: true));
    }
  }

  Future<void> _seedChatRooms() async {
    final rooms = [
      {
        'id': 'general',
        'name': 'Genel Sohbet',
        'type': 'general',
        'activeUsers': 0,
      },
      {'id': 'matchday', 'name': 'Maç Günü', 'type': 'match', 'activeUsers': 0},
      {
        'id': 'transfer',
        'name': 'Transfer',
        'type': 'transfer',
        'activeUsers': 0,
      },
    ];

    for (final room in rooms) {
      final id = room['id'] as String;
      await _db
          .collection('chatRooms')
          .doc(id)
          .set(room, SetOptions(merge: true));
    }
  }

  Future<void> _seedPosts() async {
    final postRef = _db.collection('posts').doc('post_001');
    final exists = await postRef.get();
    if (exists.exists) return;

    await postRef.set({
      'userId': 'system',
      'username': '@dijitaltribun',
      'title': 'Dijital Tribün Açıldı',
      'content':
          'Amedspor taraftarları artık burada kadro kurabilir, sohbet edebilir ve tahmin yapabilir.',
      'category': 'Tribün',
      'likes': 0,
      'commentsCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> seedAmedspor2026Squad() async {
    final players = [
      // KALECİLER
      const PlayerModel(id: 'p1', name: 'Erce Kardeşler', position: 'GK', number: 1, rating: 79, active: true),
      const PlayerModel(id: 'p2', name: 'Abdulsamed Damlu', position: 'GK', number: 25, rating: 74, active: true),
      const PlayerModel(id: 'p3', name: 'Veysel Sapan', position: 'GK', number: 35, rating: 71, active: true),

      // DEFANS
      const PlayerModel(id: 'p4', name: 'Oleksandr Syrota', position: 'DEF', number: 3, rating: 77, active: true),
      const PlayerModel(id: 'p5', name: 'Tarkan Serbest', position: 'DEF', number: 4, rating: 76, active: true),
      const PlayerModel(id: 'p6', name: 'Hasan Ali Kaldırım', position: 'DEF', number: 33, rating: 75, active: true),
      const PlayerModel(id: 'p7', name: 'Kahraman Demirtaş', position: 'DEF', number: 5, rating: 74, active: true),
      const PlayerModel(id: 'p8', name: 'Mehmet Yeşil', position: 'DEF', number: 22, rating: 73, active: true),
      const PlayerModel(id: 'p9', name: 'Celal Hanalp', position: 'DEF', number: 77, rating: 72, active: true),
      const PlayerModel(id: 'p10', name: 'Alberk Koç', position: 'DEF', number: 15, rating: 72, active: true),
      const PlayerModel(id: 'p11', name: 'Mehmet Murat Uçar', position: 'DEF', number: 2, rating: 74, active: true),

      // ORTA SAHA
      const PlayerModel(id: 'p12', name: 'Cheikhou Kouyaté', position: 'MID', number: 8, rating: 78, active: true),
      const PlayerModel(id: 'p13', name: 'Aytaç Kara', position: 'MID', number: 10, rating: 80, active: true),
      const PlayerModel(id: 'p14', name: 'Andre Biyogo Poko', position: 'MID', number: 18, rating: 77, active: true),
      const PlayerModel(id: 'p15', name: 'Diaa Sabia', position: 'MID', number: 17, rating: 79, active: true),
      const PlayerModel(id: 'p16', name: 'Çekdar Orhan', position: 'MID', number: 21, rating: 76, active: true),
      const PlayerModel(id: 'p17', name: 'Oktay Aydın', position: 'MID', number: 6, rating: 73, active: true),
      const PlayerModel(id: 'p18', name: 'Atakan Müjde', position: 'MID', number: 20, rating: 72, active: true),

      // FORVET
      const PlayerModel(id: 'p19', name: 'Mbaye Diagne', position: 'FWD', number: 9, rating: 82, active: true),
      const PlayerModel(id: 'p20', name: 'Adama Traoré', position: 'FWD', number: 7, rating: 81, active: true),
      const PlayerModel(id: 'p21', name: 'Felix Afena-Gyan', position: 'FWD', number: 11, rating: 78, active: true),
      const PlayerModel(id: 'p22', name: 'Emrah Başsan', position: 'FWD', number: 19, rating: 76, active: true),
      const PlayerModel(id: 'p23', name: 'Florent Hasani', position: 'FWD', number: 27, rating: 75, active: true),
      const PlayerModel(id: 'p24', name: 'Zdravko Dimitrov', position: 'FWD', number: 14, rating: 74, active: true),
      const PlayerModel(id: 'p25', name: 'Daniel Moreno', position: 'FWD', number: 99, rating: 75, active: true),
    ];

    for (final player in players) {
      await _playerRepo.createPlayer(player);
    }
  }
}

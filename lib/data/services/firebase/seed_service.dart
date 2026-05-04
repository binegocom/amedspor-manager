import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeedService {
  SeedService(this._db);

  final FirebaseFirestore _db;

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
        'matchDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'status': 'upcoming',
        'score': '',
      },
      {
        'id': 'match_002',
        'homeTeam': 'Amedspor',
        'awayTeam': 'Sakaryaspor',
        'matchDate': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'status': 'upcoming',
        'score': '',
      },
    ];

    for (final match in matches) {
      final id = match['id'] as String;
      await _db.collection('matches').doc(id).set(
            match,
            SetOptions(merge: true),
          );
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
      {
        'id': 'matchday',
        'name': 'Maç Günü',
        'type': 'match',
        'activeUsers': 0,
      },
      {
        'id': 'transfer',
        'name': 'Transfer',
        'type': 'transfer',
        'activeUsers': 0,
      },
    ];

    for (final room in rooms) {
      final id = room['id'] as String;
      await _db.collection('chatRooms').doc(id).set(
            room,
            SetOptions(merge: true),
          );
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
      'content': 'Amedspor taraftarları artık burada kadro kurabilir, sohbet edebilir ve tahmin yapabilir.',
      'category': 'Tribün',
      'likes': 0,
      'commentsCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
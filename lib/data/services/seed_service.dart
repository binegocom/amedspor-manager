import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../models/badge_model.dart';
import '../models/mission_model.dart';
import '../repositories/player_repository.dart';
import '../../core/gamification/badge_chain.dart';
import '../../core/gamification/mission_engine.dart';

class SeedService {
  final FirebaseFirestore _db;
  final _playerRepo = PlayerRepository();

  SeedService(this._db);

  Future<void> seedInitialData() async {
    try {
      await _seedMatches();
      await _seedChatRooms();
      await _seedPosts();
      await seedBadges();
      await seedMissions();
    } on FirebaseException catch (e) {
      debugPrint('Seed Firestore error: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Seed unknown error: $e');
    }
  }

  Future<void> seedBadges() async {
    // Seviye rozetleri
    final levelBadges = [
      BadgeModel(
        id: 'badge_level_5',
        title: 'Tribün Üyesi',
        description: '5. seviyeye ulaştın!',
        category: 'level',
        icon: '🎫',
        colorValue: 0xFFCD7F32,
        xpReward: 100,
        pointsReward: 50,
        requiredEvent: 'level_reached',
        requiredCount: 5,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BadgeModel(
        id: 'badge_level_10',
        title: 'Sadık Taraftar',
        description: '10. seviyeye ulaştın!',
        category: 'level',
        icon: '❤️',
        colorValue: 0xFFC0C0C0,
        xpReward: 250,
        pointsReward: 125,
        requiredEvent: 'level_reached',
        requiredCount: 10,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BadgeModel(
        id: 'badge_level_20',
        title: 'Tribün Lideri',
        description: '20. seviyeye ulaştın!',
        category: 'level',
        icon: '📢',
        colorValue: 0xFFFFD700,
        xpReward: 500,
        pointsReward: 250,
        requiredEvent: 'level_reached',
        requiredCount: 20,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BadgeModel(
        id: 'badge_level_30',
        title: 'Efsane Taraftar',
        description: '30. seviyeye ulaştın!',
        category: 'level',
        icon: '⭐',
        colorValue: 0xFF00FF00,
        xpReward: 1500,
        pointsReward: 750,
        requiredEvent: 'level_reached',
        requiredCount: 30,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      BadgeModel(
        id: 'badge_level_50',
        title: 'Amedspor Elçisi',
        description: '50. seviyeye ulaştın! Gerçek bir efsane!',
        category: 'level',
        icon: '👑',
        colorValue: 0xFF00BFFF,
        xpReward: 5000,
        pointsReward: 2500,
        requiredEvent: 'level_reached',
        requiredCount: 50,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final badge in levelBadges) {
      await _db
          .collection('badges')
          .doc(badge.id)
          .set(badge.toMap(), SetOptions(merge: true));
    }

    // Chain rozetlerini de Firestore'a kaydet
    for (final chain in BadgeChain.allChains) {
      for (int i = 0; i < chain.tiers.length; i++) {
        final tier = chain.tiers[i];
        final badgeId = 'badge_${chain.chainId}_tier_$i';
        final badge = BadgeModel(
          id: badgeId,
          title: tier.title,
          description: tier.description,
          category: chain.chainId,
          icon: tier.icon,
          colorValue: tier.colorValue,
          xpReward: tier.xpReward,
          pointsReward: tier.pointsReward,
          requiredEvent: chain.chainId,
          requiredCount: tier.requiredCount,
          active: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _db
            .collection('badges')
            .doc(badgeId)
            .set(badge.toMap(), SetOptions(merge: true));
      }
    }

    debugPrint('✅ Rozetler başarıyla seed edildi.');
  }

  Future<void> seedMissions() async {
    // Günlük görev örnekleri
    final dailyMissions = MissionEngine.generateDailyMissions();
    for (final mission in dailyMissions) {
      await _db
          .collection('missions')
          .doc(mission.id)
          .set(mission.toMap(), SetOptions(merge: true));
    }

    // Haftalık görev örnekleri
    final weeklyMissions = MissionEngine.generateWeeklyMissions();
    for (final mission in weeklyMissions) {
      await _db
          .collection('missions')
          .doc(mission.id)
          .set(mission.toMap(), SetOptions(merge: true));
    }

    // Sezonluk görev örnekleri
    final seasonalMissions = MissionEngine.generateSeasonalMissions();
    for (final mission in seasonalMissions) {
      await _db
          .collection('missions')
          .doc(mission.id)
          .set(mission.toMap(), SetOptions(merge: true));
    }

    // Başlangıç seviyesi görevleri (yeni kullanıcılar için)
    final introMissions = [
      MissionModel(
        id: 'intro_complete_profile',
        title: 'Profili Tamamla',
        description: 'Profil bilgilerini doldur',
        type: 'tutorial',
        missionKey: 'profile_completed:1',
        requiredCount: 1,
        xpReward: 50,
        pointsReward: 25,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MissionModel(
        id: 'intro_first_lineup',
        title: 'İlk Kadron',
        description: 'İlk kadronu oluştur',
        type: 'tutorial',
        missionKey: 'lineup_saved:1',
        requiredCount: 1,
        xpReward: 100,
        pointsReward: 50,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MissionModel(
        id: 'intro_first_prediction',
        title: 'İlk Tahmin',
        description: 'İlk maç tahminini yap',
        type: 'tutorial',
        missionKey: 'prediction_count:1',
        requiredCount: 1,
        xpReward: 75,
        pointsReward: 35,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MissionModel(
        id: 'intro_first_post',
        title: 'İlk Paylaşım',
        description: 'İlk gönderini paylaş',
        type: 'tutorial',
        missionKey: 'post_count:1',
        requiredCount: 1,
        xpReward: 100,
        pointsReward: 50,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MissionModel(
        id: 'intro_join_chat',
        title: 'Sohbete Katıl',
        description: 'Genel sohbete 3 mesaj gönder',
        type: 'tutorial',
        missionKey: 'chat_message:3',
        requiredCount: 3,
        xpReward: 50,
        pointsReward: 25,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final mission in introMissions) {
      await _db
          .collection('missions')
          .doc(mission.id)
          .set(mission.toMap(), SetOptions(merge: true));
    }

    debugPrint('✅ Görevler başarıyla seed edildi.');
  }

  Future<void> _seedMatches() async {
    final matches = [
      {
        'id': 'match_001',
        'homeTeam': 'Amedspor',
        'awayTeam': 'Altay',
        'homeLogo': '',
        'awayLogo': '',
        'matchDate': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
        'status': 'upcoming',
        'homeScore': 0,
        'awayScore': 0,
        'minute': 0,
        'motmCandidates': <String>[],
        'isMotmVotingActive': false,
        'motmResults': <String, int>{},
      },
      {
        'id': 'match_002',
        'homeTeam': 'Amedspor',
        'awayTeam': 'Sakaryaspor',
        'homeLogo': '',
        'awayLogo': '',
        'matchDate': DateTime.now()
            .add(const Duration(days: 10))
            .toIso8601String(),
        'status': 'upcoming',
        'homeScore': 0,
        'awayScore': 0,
        'minute': 0,
        'motmCandidates': <String>[],
        'isMotmVotingActive': false,
        'motmResults': <String, int>{},
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
        'createdBy': 'system',
        'createdAt': DateTime.now().toIso8601String(),
        'activeUsers': 0,
      },
      {
        'id': 'matchday',
        'name': 'Maç Günü',
        'type': 'match',
        'createdBy': 'system',
        'createdAt': DateTime.now().toIso8601String(),
        'activeUsers': 0,
      },
      {
        'id': 'transfer',
        'name': 'Transfer',
        'type': 'transfer',
        'createdBy': 'system',
        'createdAt': DateTime.now().toIso8601String(),
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
      const PlayerModel(
        id: 'p1',
        name: 'Erce Kardeşler',
        position: 'GK',
        number: 1,
        rating: 79,
        active: true,
      ),
      const PlayerModel(
        id: 'p2',
        name: 'Abdulsamed Damlu',
        position: 'GK',
        number: 25,
        rating: 74,
        active: true,
      ),
      const PlayerModel(
        id: 'p3',
        name: 'Veysel Sapan',
        position: 'GK',
        number: 35,
        rating: 71,
        active: true,
      ),

      // DEFANS
      const PlayerModel(
        id: 'p4',
        name: 'Oleksandr Syrota',
        position: 'DEF',
        number: 3,
        rating: 77,
        active: true,
      ),
      const PlayerModel(
        id: 'p5',
        name: 'Tarkan Serbest',
        position: 'DEF',
        number: 4,
        rating: 76,
        active: true,
      ),
      const PlayerModel(
        id: 'p6',
        name: 'Hasan Ali Kaldırım',
        position: 'DEF',
        number: 33,
        rating: 75,
        active: true,
      ),
      const PlayerModel(
        id: 'p7',
        name: 'Kahraman Demirtaş',
        position: 'DEF',
        number: 5,
        rating: 74,
        active: true,
      ),
      const PlayerModel(
        id: 'p8',
        name: 'Mehmet Yeşil',
        position: 'DEF',
        number: 22,
        rating: 73,
        active: true,
      ),
      const PlayerModel(
        id: 'p9',
        name: 'Celal Hanalp',
        position: 'DEF',
        number: 77,
        rating: 72,
        active: true,
      ),
      const PlayerModel(
        id: 'p10',
        name: 'Alberk Koç',
        position: 'DEF',
        number: 15,
        rating: 72,
        active: true,
      ),
      const PlayerModel(
        id: 'p11',
        name: 'Mehmet Murat Uçar',
        position: 'DEF',
        number: 2,
        rating: 74,
        active: true,
      ),

      // ORTA SAHA
      const PlayerModel(
        id: 'p12',
        name: 'Cheikhou Kouyaté',
        position: 'MID',
        number: 8,
        rating: 78,
        active: true,
      ),
      const PlayerModel(
        id: 'p13',
        name: 'Aytaç Kara',
        position: 'MID',
        number: 10,
        rating: 80,
        active: true,
      ),
      const PlayerModel(
        id: 'p14',
        name: 'Andre Biyogo Poko',
        position: 'MID',
        number: 18,
        rating: 77,
        active: true,
      ),
      const PlayerModel(
        id: 'p15',
        name: 'Diaa Sabia',
        position: 'MID',
        number: 17,
        rating: 79,
        active: true,
      ),
      const PlayerModel(
        id: 'p16',
        name: 'Çekdar Orhan',
        position: 'MID',
        number: 21,
        rating: 76,
        active: true,
      ),
      const PlayerModel(
        id: 'p17',
        name: 'Oktay Aydın',
        position: 'MID',
        number: 6,
        rating: 73,
        active: true,
      ),
      const PlayerModel(
        id: 'p18',
        name: 'Atakan Müjde',
        position: 'MID',
        number: 20,
        rating: 72,
        active: true,
      ),

      // FORVET
      const PlayerModel(
        id: 'p19',
        name: 'Mbaye Diagne',
        position: 'FWD',
        number: 9,
        rating: 82,
        active: true,
      ),
      const PlayerModel(
        id: 'p20',
        name: 'Adama Traoré',
        position: 'FWD',
        number: 7,
        rating: 81,
        active: true,
      ),
      const PlayerModel(
        id: 'p21',
        name: 'Felix Afena-Gyan',
        position: 'FWD',
        number: 11,
        rating: 78,
        active: true,
      ),
      const PlayerModel(
        id: 'p22',
        name: 'Emrah Başsan',
        position: 'FWD',
        number: 19,
        rating: 76,
        active: true,
      ),
      const PlayerModel(
        id: 'p23',
        name: 'Florent Hasani',
        position: 'FWD',
        number: 27,
        rating: 75,
        active: true,
      ),
      const PlayerModel(
        id: 'p24',
        name: 'Zdravko Dimitrov',
        position: 'FWD',
        number: 14,
        rating: 74,
        active: true,
      ),
      const PlayerModel(
        id: 'p25',
        name: 'Daniel Moreno',
        position: 'FWD',
        number: 99,
        rating: 75,
        active: true,
      ),
    ];

    for (final player in players) {
      await _playerRepo.createPlayer(player);
    }
  }
}

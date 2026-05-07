import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge_model.dart';
import '../models/user_badge_model.dart';
import '../models/mission_model.dart';
import '../models/user_mission_model.dart';
import '../models/xp_event_model.dart';
import '../models/streak_model.dart';
import '../services/firebase/firebase_providers.dart';

class GamificationRepository {
  final _service = firestoreService;

  // Badges
  Stream<List<BadgeModel>> watchActiveBadges() {
    return _service.badges
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BadgeModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<BadgeModel>> watchAllBadges() {
    return _service.badges
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BadgeModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<UserBadgeModel>> watchUserBadges(String userId) {
    return _service.userBadges(userId)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserBadgeModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createBadge(BadgeModel badge) async {
    await _service.badges.doc(badge.id).set(badge.toMap());
  }

  Future<void> updateBadge(BadgeModel badge) async {
    await _service.badges.doc(badge.id).update(badge.toMap());
  }

  Future<void> deleteBadge(String badgeId) async {
    await _service.badges.doc(badgeId).delete();
  }

  Future<void> awardUserBadge(UserBadgeModel userBadge) async {
    await _service.userBadges(userBadge.userId).doc(userBadge.id).set(userBadge.toMap());
  }

  Future<bool> hasUserBadge({
    required String userId,
    required String badgeId,
  }) async {
    final snapshot = await _service.userBadges(userId)
        .where('badgeId', isEqualTo: badgeId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Missions
  Stream<List<MissionModel>> watchActiveMissions() {
    return _service.missions
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<MissionModel>> watchAllMissions() {
    return _service.missions
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MissionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<UserMissionModel>> watchUserMissions(String userId) {
    return _service.userMissions(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserMissionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createMission(MissionModel mission) async {
    await _service.missions.doc(mission.id).set(mission.toMap());
  }

  Future<void> updateMission(MissionModel mission) async {
    await _service.missions.doc(mission.id).update(mission.toMap());
  }

  Future<void> deleteMission(String missionId) async {
    await _service.missions.doc(missionId).delete();
  }

  Future<void> updateUserMissionProgress({
    required String userId,
    required String missionId,
    required int incrementBy,
  }) async {
    final docRef = _service.userMissions(userId).doc(missionId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final currentProgress = snapshot.data()?['progress'] ?? 0;
      final requiredCount = snapshot.data()?['requiredCount'] ?? 1;
      final newProgress = currentProgress + incrementBy;
      
      transaction.update(docRef, {
        'progress': newProgress,
        if (newProgress >= requiredCount) 'completed': true,
        if (newProgress >= requiredCount) 'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> completeMission({
    required String userId,
    required String missionId,
  }) async {
    await _service.userMissions(userId).doc(missionId).update({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> claimMissionReward({
    required String userId,
    required String missionId,
    required int xpReward,
    required int pointsReward,
  }) async {
    final missionRef = _service.userMissions(userId).doc(missionId);
    final userRef = _service.users.doc(userId);
    final xpEventRef = _service.userXpEvents(userId).doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final missionSnap = await transaction.get(missionRef);
      if (!missionSnap.exists) throw Exception('Görev bulunamadı.');
      
      final data = missionSnap.data() as Map<String, dynamic>;
      if (data['claimed'] == true) throw Exception('Ödül zaten alınmış.');
      if (data['completed'] != true) throw Exception('Görev henüz tamamlanmamış.');

      // Mark as claimed
      transaction.update(missionRef, {
        'claimed': true,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      // Update user xp and points
      transaction.update(userRef, {
        'xp': FieldValue.increment(xpReward),
        'points': FieldValue.increment(pointsReward),
      });

      // Log XP event
      final xpEvent = XpEventModel(
        id: xpEventRef.id,
        userId: userId,
        amount: xpReward,
        eventType: 'mission_reward',
        reason: '${data['title']} görevi ödülü',
        sourceType: 'mission',
        sourceId: missionId,
        createdAt: DateTime.now(),
      );
      transaction.set(xpEventRef, xpEvent.toMap());
    });
  }

  // XP Events
  Stream<List<XpEventModel>> watchUserXpEvents(String userId) {
    return _service.userXpEvents(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => XpEventModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createXpEvent(XpEventModel event) async {
    await _service.userXpEvents(event.userId).doc(event.id).set(event.toMap());
  }

  Future<bool> xpEventExists({
    required String userId,
    required String eventType,
    required String sourceId,
  }) async {
    final snapshot = await _service.userXpEvents(userId)
        .where('eventType', isEqualTo: eventType)
        .where('sourceId', isEqualTo: sourceId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Streaks
  Stream<List<StreakModel>> watchUserStreaks(String userId) {
    return _service.userStreaks(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StreakModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateStreak({
    required String userId,
    required String streakType,
    required int currentCount,
    required int bestCount,
  }) async {
    await _service.userStreaks(userId).doc(streakType).set({
      'userId': userId,
      'type': streakType,
      'currentCount': currentCount,
      'bestCount': bestCount,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
      'active': true,
    }, SetOptions(merge: true));
  }
}

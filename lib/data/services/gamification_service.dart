import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/badge_model.dart';
import '../repositories/gamification_repository.dart';
import '../models/user_mission_model.dart';
import './firebase/firebase_providers.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final _repo = GamificationRepository();

  // XP Rules Constants
  static const int xpDailyLogin = 5;
  static const int xpLineupSaved = 10;
  static const int xpLineupShared = 15;
  static const int xpLineupLikedReceived = 3;
  static const int xpLineupTopWeekly = 100;
  static const int xpPredictionCreated = 10;
  static const int xpPredictionCorrect = 50;
  static const int xpPostCreated = 15;
  static const int xpPostLikedReceived = 3;
  static const int xpCommentCreated = 5;
  static const int xpChatMessageMatchday = 2;
  static const int xpLiveMatchOpened = 20;
  static const int xpReportCreated = 2;
  static const int xpProfileCompleted = 20;
  static const int xpTrainingCompleted = 25;
  static const int xpTrainingPerfectScore = 50;

  // Level Logic
  int calculateLevel(int xp) {
    if (xp < 100) return 1;
    return (math.sqrt(xp / 100)).floor() + 1;
  }

  String levelTitleFor(int level) {
    if (level >= 50) return 'Amedspor Elçisi';
    if (level >= 30) return 'Efsane Taraftar';
    if (level >= 20) return 'Tribün Lideri';
    if (level >= 10) return 'Sadık Taraftar';
    if (level >= 5) return 'Tribün Üyesi';
    return 'Yeni Taraftar';
  }

  Future<void> awardXp({
    required String userId,
    required int amount,
    required String reason,
    required String eventType,
    required String sourceType,
    required String sourceId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'awardServerSideXp',
      );
      final response = await callable.call({
        'amount': amount,
        'reason': reason,
        'eventType': eventType,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'metadata': metadata,
      });

      final data = response.data as Map<dynamic, dynamic>?;
      if (data != null && data['status'] == 'success') {
        await checkBadgeProgress(userId: userId, eventType: eventType);
        await updateMissionProgress(userId: userId, missionKey: eventType);
      }
    } catch (e) {
      debugPrint('Secure server-side awardXp callable error: $e');
    }
  }

  Future<void> awardBadge({
    required String userId,
    required BadgeModel badge,
    required String sourceType,
    required String sourceId,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'awardServerSideBadge',
      );
      await callable.call({
        'badgeId': badge.id,
        'sourceType': sourceType,
        'sourceId': sourceId,
      });
    } catch (e) {
      debugPrint('Secure server-side awardBadge callable error: $e');
    }
  }

  Future<void> checkBadgeProgress({
    required String userId,
    required String eventType,
  }) async {
    // 1. Get relevant badges
    final activeBadgesSnapshot = await firestoreService.badges
        .where('active', isEqualTo: true)
        .where('requiredEvent', isEqualTo: eventType)
        .get();

    for (final doc in activeBadgesSnapshot.docs) {
      final badge = BadgeModel.fromMap(doc.id, doc.data());

      // 2. Count user events
      final eventsSnapshot = await firestoreService
          .userXpEvents(userId)
          .where('eventType', isEqualTo: eventType)
          .get();

      if (eventsSnapshot.docs.length >= badge.requiredCount) {
        await awardBadge(
          userId: userId,
          badge: badge,
          sourceType: 'system_check',
          sourceId: eventType,
        );
      }
    }
  }

  Future<void> updateMissionProgress({
    required String userId,
    required String missionKey,
    int incrementBy = 1,
  }) async {
    final activeMissionsSnapshot = await firestoreService
        .userMissions(userId)
        .where('completed', isEqualTo: false)
        .get();

    for (final doc in activeMissionsSnapshot.docs) {
      final userMission = UserMissionModel.fromMap(doc.id, doc.data());
      if (userMission.missionId.isNotEmpty) {
        final masterDoc = await firestoreService.missions
            .doc(userMission.missionId)
            .get();
        if (masterDoc.exists) {
          final masterKey = masterDoc.data()?['missionKey'] as String?;
          if (masterKey == missionKey ||
              masterKey == 'general' ||
              masterKey == null ||
              masterKey.isEmpty) {
            await _repo.updateUserMissionProgress(
              userId: userId,
              missionId: doc.id,
              incrementBy: incrementBy,
            );
          }
        } else {
          await _repo.updateUserMissionProgress(
            userId: userId,
            missionId: doc.id,
            incrementBy: incrementBy,
          );
        }
      } else {
        await _repo.updateUserMissionProgress(
          userId: userId,
          missionId: doc.id,
          incrementBy: incrementBy,
        );
      }
    }
  }

  Future<void> updateDailyLoginStreak(String userId) async {
    final docRef = firestoreService.userStreaks(userId).doc('daily_login');
    final snapshot = await docRef.get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (snapshot.exists) {
      final lastUpdate = (snapshot.data()?['lastUpdatedAt'] as Timestamp)
          .toDate();
      final lastUpdateDay = DateTime(
        lastUpdate.year,
        lastUpdate.month,
        lastUpdate.day,
      );

      if (lastUpdateDay.isAtSameMomentAs(today)) {
        // Already updated today
        return;
      }

      final yesterday = today.subtract(const Duration(days: 1));
      int currentCount = snapshot.data()?['currentCount'] ?? 0;
      int bestCount = snapshot.data()?['bestCount'] ?? 0;

      if (lastUpdateDay.isAtSameMomentAs(yesterday)) {
        currentCount++;
      } else {
        currentCount = 1;
      }

      if (currentCount > bestCount) bestCount = currentCount;

      await _repo.updateStreak(
        userId: userId,
        streakType: 'daily_login',
        currentCount: currentCount,
        bestCount: bestCount,
      );

      // Award daily login XP
      await awardXp(
        userId: userId,
        amount: xpDailyLogin,
        reason: 'Günlük giriş ödülü',
        eventType: 'daily_login',
        sourceType: 'system',
        sourceId: today.toIso8601String(),
      );
    } else {
      // First time
      await _repo.updateStreak(
        userId: userId,
        streakType: 'daily_login',
        currentCount: 1,
        bestCount: 1,
      );

      await awardXp(
        userId: userId,
        amount: xpDailyLogin,
        reason: 'İlk giriş ödülü',
        eventType: 'daily_login',
        sourceType: 'system',
        sourceId: today.toIso8601String(),
      );
    }
  }

  Future<void> awardTrainingXp({
    required String userId,
    required String drillType,
    required bool perfectScore,
  }) async {
    await awardXp(
      userId: userId,
      amount: perfectScore ? xpTrainingPerfectScore : xpTrainingCompleted,
      reason: perfectScore
          ? 'Mükemmel $drillType antrenmanı'
          : '$drillType antrenmanı tamamlandı',
      eventType: perfectScore ? 'training_perfect_score' : 'training_completed',
      sourceType: 'training',
      sourceId: '$drillType-${DateTime.now().millisecondsSinceEpoch}',
      metadata: {'drillType': drillType, 'perfectScore': perfectScore},
    );
  }
}

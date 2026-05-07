import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/app_user_model.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/user_badge_model.dart';
import '../../data/models/xp_event_model.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firebase/firebase_providers.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final _repo = GamificationRepository();
  final _uuid = const Uuid();

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
    // 1. Duplicate Check
    final exists = await _repo.xpEventExists(
      userId: userId,
      eventType: eventType,
      sourceId: sourceId,
    );
    if (exists) return;

    // 2. Get User
    final userDoc = await firestoreService.users.doc(userId).get();
    if (!userDoc.exists) return;
    final user = AppUserModel.fromMap(userId, userDoc.data()!);

    if (!user.gamificationEnabled) return;

    // 3. Create XP Event
    final event = XpEventModel(
      id: _uuid.v4(),
      userId: userId,
      amount: amount,
      reason: reason,
      eventType: eventType,
      sourceType: sourceType,
      sourceId: sourceId,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Update User XP and Points
      final newTotalXp = user.xp + amount;
      final newPoints = user.points + (amount ~/ 2); // Example points logic
      final newLevel = calculateLevel(newTotalXp);
      final newTitle = levelTitleFor(newLevel);

      transaction.update(firestoreService.users.doc(userId), {
        'xp': newTotalXp,
        'points': newPoints,
        'level': newLevel,
        'levelTitle': newTitle,
      });

      // Save XP Event
      transaction.set(firestoreService.userXpEvents(userId).doc(event.id), event.toMap());

      // Level Up Notification
      if (newLevel > user.level) {
        final notifId = _uuid.v4();
        final notification = NotificationModel(
          id: notifId,
          userId: userId,
          title: 'Seviye Atladın! 🚀',
          message: 'Tebrikler! Artık $newLevel. seviyedesin: $newTitle',
          type: 'level',
          targetRoute: '/level-progress',
          read: false,
          createdAt: DateTime.now(),
        );
        transaction.set(firestoreService.notifications.doc(notifId), notification.toMap());
      }
    });

    // 4. Check Badges after XP Award
    await checkBadgeProgress(userId: userId, eventType: eventType);
  }

  Future<void> awardBadge({
    required String userId,
    required BadgeModel badge,
    required String sourceType,
    required String sourceId,
  }) async {
    final hasBadge = await _repo.hasUserBadge(userId: userId, badgeId: badge.id);
    if (hasBadge) return;

    final userBadge = UserBadgeModel(
      id: _uuid.v4(),
      badgeId: badge.id,
      userId: userId,
      title: badge.title,
      description: badge.description,
      category: badge.category,
      icon: badge.icon,
      colorValue: badge.colorValue,
      earnedAt: DateTime.now(),
      sourceType: sourceType,
      sourceId: sourceId,
      xpReward: badge.xpReward,
      pointsReward: badge.pointsReward,
    );

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Award rewards
      if (badge.xpReward > 0 || badge.pointsReward > 0) {
        final userDoc = await transaction.get(firestoreService.users.doc(userId));
        final currentXp = userDoc.data()?['xp'] ?? 0;
        final currentPoints = userDoc.data()?['points'] ?? 0;
        
        transaction.update(firestoreService.users.doc(userId), {
          'xp': currentXp + badge.xpReward,
          'points': currentPoints + badge.pointsReward,
          'badgesCount': FieldValue.increment(1),
        });
      }

      // Save User Badge
      transaction.set(firestoreService.userBadges(userId).doc(userBadge.id), userBadge.toMap());

      // Badge Notification
      final notifId = _uuid.v4();
      final notification = NotificationModel(
        id: notifId,
        userId: userId,
        title: 'Yeni Rozet Kazandın! 🏅',
        message: '"${badge.title}" rozetini kazandın. Tebrikler!',
        type: 'badge',
        targetRoute: '/badges',
        read: false,
        createdAt: DateTime.now(),
      );
      transaction.set(firestoreService.notifications.doc(notifId), notification.toMap());
    });
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
      final eventsSnapshot = await firestoreService.userXpEvents(userId)
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
    final activeMissionsSnapshot = await firestoreService.userMissions(userId)
        .where('completed', isEqualTo: false)
        .get();

    for (final doc in activeMissionsSnapshot.docs) {
      // In a real scenario, we'd link mission to missionKey
      // For now, let's assume missionId or a field in userMissions stores the key
      final missionId = doc.id;
      await _repo.updateUserMissionProgress(
        userId: userId,
        missionId: missionId,
        incrementBy: incrementBy,
      );
    }
  }

  Future<void> updateDailyLoginStreak(String userId) async {
    final docRef = firestoreService.userStreaks(userId).doc('daily_login');
    final snapshot = await docRef.get();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (snapshot.exists) {
      final lastUpdate = (snapshot.data()?['lastUpdatedAt'] as Timestamp).toDate();
      final lastUpdateDay = DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);

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
}

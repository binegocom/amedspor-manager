import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/app_user_model.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/user_badge_model.dart';
import '../../data/models/xp_event_model.dart';
import '../../data/models/mission_model.dart';
import '../../data/models/user_mission_model.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firebase/firebase_providers.dart';
import 'level_calculator.dart';
import 'badge_chain.dart';
import 'mission_engine.dart';

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
  static const int xpTrainingCompleted = 25;
  static const int xpTrainingPerfectScore = 50;
  static const int xpStreakBonus = 10;

  /// XP ödüllendirme (LevelCalculator kullanır)
  Future<LevelUpResult?> awardXp({
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
    if (exists) return null;

    // 2. Get User
    final userDoc = await firestoreService.users.doc(userId).get();
    if (!userDoc.exists) return null;
    final user = AppUserModel.fromMap(userId, userDoc.data()!);

    if (!user.gamificationEnabled) return null;

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

    LevelUpResult? levelUpResult;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Update User XP and Points
      final newTotalXp = user.xp + amount;
      final newPoints = user.points + (amount ~/ 2);
      final oldLevel = user.level;
      final newLevel = LevelCalculator.calculateLevel(newTotalXp);

      // Level up kontrolü
      if (newLevel > oldLevel) {
        final bonusXp = LevelCalculator.levelUpBonusXp(newLevel);
        final finalXp = newTotalXp + bonusXp;
        final finalLevel = LevelCalculator.calculateLevel(finalXp);
        final finalTitle = LevelCalculator.levelTitleFor(finalLevel);

        levelUpResult = LevelUpResult(
          oldLevel: oldLevel,
          newLevel: finalLevel,
          levelsGained: finalLevel - oldLevel,
          titleChanged: LevelCalculator.hasTitleChanged(oldLevel, finalLevel),
          oldTitle: LevelCalculator.levelTitleFor(oldLevel),
          newTitle: finalTitle,
          bonusXp: bonusXp,
        );

        transaction.update(firestoreService.users.doc(userId), {
          'xp': finalXp,
          'points': newPoints,
          'level': finalLevel,
          'levelTitle': finalTitle,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });

        // Level up notification
        final notifId = _uuid.v4();
        final notification = NotificationModel(
          id: notifId,
          userId: userId,
          title: 'Seviye Atladın! 🚀',
          message: levelUpResult!.titleChanged
              ? 'Tebrikler! $finalTitle oldun! 🎉'
              : 'Tebrikler! $finalLevel. seviyeye ulaştın!',
          type: 'level',
          targetRoute: '/profile',
          read: false,
          createdAt: DateTime.now(),
        );
        transaction.set(
          firestoreService.notifications.doc(notifId),
          notification.toMap(),
        );

        // Level badge kontrolü
        _scheduleBadgeCheck(userId: userId, eventType: 'level_reached');
      } else {
        transaction.update(firestoreService.users.doc(userId), {
          'xp': newTotalXp,
          'points': newPoints,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }

      // Save XP Event
      transaction.set(
        firestoreService.userXpEvents(userId).doc(event.id),
        event.toMap(),
      );
    });

    // 4. Check Mission Progress
    await _updateMissionProgressForEvent(userId: userId, eventType: eventType);

    // 5. Check Badge Progress (chain badges)
    await checkBadgeProgress(userId: userId, eventType: eventType);

    return levelUpResult;
  }

  /// Rozet ödüllendirme
  Future<void> awardBadge({
    required String userId,
    required BadgeModel badge,
    required String sourceType,
    required String sourceId,
  }) async {
    final hasBadge = await _repo.hasUserBadge(
      userId: userId,
      badgeId: badge.id,
    );
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
        final userDoc = await transaction.get(
          firestoreService.users.doc(userId),
        );
        final currentXp = userDoc.data()?['xp'] ?? 0;
        final currentPoints = userDoc.data()?['points'] ?? 0;

        transaction.update(firestoreService.users.doc(userId), {
          'xp': currentXp + badge.xpReward,
          'points': currentPoints + badge.pointsReward,
          'badgesCount': FieldValue.increment(1),
        });
      }

      // Save User Badge
      transaction.set(
        firestoreService.userBadges(userId).doc(userBadge.id),
        userBadge.toMap(),
      );

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
      transaction.set(
        firestoreService.notifications.doc(notifId),
        notification.toMap(),
      );
    });
  }

  /// Rozet ilerleme kontrolü (chain badges dahil)
  Future<void> checkBadgeProgress({
    required String userId,
    required String eventType,
  }) async {
    // 1. Normal badge kontrolü (Firestore'dan)
    final activeBadgesSnapshot = await firestoreService.badges
        .where('active', isEqualTo: true)
        .where('requiredEvent', isEqualTo: eventType)
        .get();

    for (final doc in activeBadgesSnapshot.docs) {
      final badge = BadgeModel.fromMap(doc.id, doc.data());

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

    // 2. Chain badge kontrolü
    final chain = BadgeChain.findChain(eventType);
    if (chain != null) {
      // Kullanıcının bu event'ten kaç tane yaptığını say
      final eventsSnapshot = await firestoreService
          .userXpEvents(userId)
          .where('eventType', isEqualTo: eventType)
          .get();
      final eventCount = eventsSnapshot.docs.length;

      // Kullanıcının kazandığı chain badge'leri al
      final earnedBadgesSnapshot = await firestoreService
          .userBadges(userId)
          .where('category', isEqualTo: eventType)
          .get();
      final earnedTierIndices = earnedBadgesSnapshot.docs
          .map((doc) {
            final badge = UserBadgeModel.fromMap(doc.id, doc.data());
            // badge title'ına göre tier index'ini bul
            for (int i = 0; i < chain.tiers.length; i++) {
              if (chain.tiers[i].title == badge.title) return i;
            }
            return -1;
          })
          .where((i) => i >= 0)
          .toList();

      final highestEarnedIndex = earnedTierIndices.isEmpty
          ? -1
          : earnedTierIndices.reduce(math.max);

      // Henüz kazanılmamış tier'ları kontrol et
      for (int i = 0; i < chain.tiers.length; i++) {
        if (i > highestEarnedIndex &&
            eventCount >= chain.tiers[i].requiredCount) {
          final badge = chain.tiers[i].toBadgeModel(eventType, _uuid.v4());
          await awardBadge(
            userId: userId,
            badge: badge,
            sourceType: 'badge_chain',
            sourceId: eventType,
          );
        }
      }
    }
  }

  /// Görev ilerlemesini güncelle
  Future<void> _updateMissionProgressForEvent({
    required String userId,
    required String eventType,
  }) async {
    // Kullanıcının aktif görevlerini al
    final activeMissionsSnapshot = await firestoreService
        .userMissions(userId)
        .where('completed', isEqualTo: false)
        .get();

    // Kullanıcı istatistiklerini al
    final userDoc = await firestoreService.users.doc(userId).get();
    final Map<String, Object?> userStats =
        userDoc.data()?.cast<String, Object?>() ?? <String, Object?>{};

    // Son XP event'lerini al
    final eventsSnapshot = await firestoreService
        .userXpEvents(userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    final recentEvents = eventsSnapshot.docs
        .map((d) => (d.data() as Map<String, dynamic>?) ?? <String, dynamic>{})
        .toList();

    for (final doc in activeMissionsSnapshot.docs) {
      final userMission = UserMissionModel.fromMap(doc.id, doc.data());

      // Mission modelini al
      final missionDoc = await firestoreService.missions
          .doc(userMission.missionId)
          .get();
      if (!missionDoc.exists) continue;
      final mission = MissionModel.fromMap(
        missionDoc.id,
        missionDoc.data() as Map<String, dynamic>,
      );

      // İlerlemeyi hesapla
      final progress = MissionEngine.calculateProgress(
        mission: mission,
        userStats: userStats,
        recentEvents: recentEvents,
      );

      final isCompleted = progress >= mission.requiredCount;

      // Firestore'u güncelle
      await firestoreService.userMissions(userId).doc(doc.id).update({
        'progress': progress,
        if (isCompleted && !userMission.completed) 'completed': true,
        if (isCompleted && !userMission.completed)
          'completedAt': FieldValue.serverTimestamp(),
      });

      // Yeni tamamlandıysa bildirim gönder
      if (isCompleted && !userMission.completed) {
        await _notifyMissionComplete(
          userId: userId,
          title: mission.title,
          xpReward: mission.xpReward,
        );
      }
    }
  }

  /// Görev tamamlama bildirimi
  Future<void> _notifyMissionComplete({
    required String userId,
    required String title,
    required int xpReward,
  }) async {
    final notifId = _uuid.v4();
    final notification = NotificationModel(
      id: notifId,
      userId: userId,
      title: 'Görev Tamamlandı! ✅',
      message: '"$title" görevini tamamladın! $xpReward XP kazandın.',
      type: 'mission',
      targetRoute: '/missions',
      read: false,
      createdAt: DateTime.now(),
    );
    await firestoreService.notifications.doc(notifId).set(notification.toMap());
  }

  /// Görev ödülünü al
  Future<void> claimMissionReward({
    required String userId,
    required String missionId,
  }) async {
    await _repo.claimMissionReward(
      userId: userId,
      missionId: missionId,
      xpReward: 0, // repository'den alınacak
      pointsReward: 0,
    );
  }

  /// Günlük görevleri kullanıcıya ata
  Future<void> assignDailyMissions(String userId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Bugün zaten atanmış mı kontrol et
    final existingSnapshot = await firestoreService
        .userMissions(userId)
        .where('category', isEqualTo: 'daily')
        .where('startedAt', isGreaterThanOrEqualTo: todayStart)
        .get();

    if (existingSnapshot.docs.isNotEmpty) return; // Zaten atanmış

    // Günlük görevleri oluştur
    final dailyMissions = MissionEngine.generateDailyMissions();

    for (final mission in dailyMissions) {
      // Mission'ı Firestore'a kaydet (eğer yoksa)
      final missionDoc = await firestoreService.missions.doc(mission.id).get();
      if (!missionDoc.exists) {
        await firestoreService.missions.doc(mission.id).set(mission.toMap());
      }

      // Kullanıcıya ata
      final userMission = UserMissionModel(
        id: _uuid.v4(),
        missionId: mission.id,
        userId: userId,
        title: mission.title,
        description: mission.description,
        category: 'daily',
        xpReward: mission.xpReward,
        progress: 0,
        requiredCount: mission.requiredCount,
        completed: false,
        claimed: false,
        startedAt: DateTime.now(),
      );
      await firestoreService
          .userMissions(userId)
          .doc(userMission.id)
          .set(userMission.toMap());
    }
  }

  /// Haftalık görevleri kullanıcıya ata
  Future<void> assignWeeklyMissions(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    // Bu hafta zaten atanmış mı kontrol et
    final existingSnapshot = await firestoreService
        .userMissions(userId)
        .where('category', isEqualTo: 'weekly')
        .where('startedAt', isGreaterThanOrEqualTo: weekStartDay)
        .get();

    if (existingSnapshot.docs.isNotEmpty) return;

    final weeklyMissions = MissionEngine.generateWeeklyMissions();

    for (final mission in weeklyMissions) {
      final missionDoc = await firestoreService.missions.doc(mission.id).get();
      if (!missionDoc.exists) {
        await firestoreService.missions.doc(mission.id).set(mission.toMap());
      }

      final userMission = UserMissionModel(
        id: _uuid.v4(),
        missionId: mission.id,
        userId: userId,
        title: mission.title,
        description: mission.description,
        category: 'weekly',
        xpReward: mission.xpReward,
        progress: 0,
        requiredCount: mission.requiredCount,
        completed: false,
        claimed: false,
        startedAt: DateTime.now(),
      );
      await firestoreService
          .userMissions(userId)
          .doc(userMission.id)
          .set(userMission.toMap());
    }
  }

  /// Günlük giriş serisini güncelle
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
        return; // Bugün zaten güncellendi
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

      // Streak bonus XP
      int totalXp = xpDailyLogin;
      if (currentCount > 1) {
        totalXp +=
            xpStreakBonus * (currentCount ~/ 7); // Her 7 günde bir ekstra bonus
      }

      await awardXp(
        userId: userId,
        amount: totalXp,
        reason: currentCount > 1
            ? '$currentCount günlük seri ödülü'
            : 'İlk giriş ödülü',
        eventType: 'daily_login',
        sourceType: 'system',
        sourceId: today.toIso8601String(),
        metadata: {'streakCount': currentCount, 'bestCount': bestCount},
      );

      // Chain badge kontrolü
      await checkBadgeProgress(userId: userId, eventType: 'daily_login');
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

    // Günlük görevleri ata
    await assignDailyMissions(userId);
    await assignWeeklyMissions(userId);
  }

  /// Antrenman tamamlama XP'si
  Future<LevelUpResult?> awardTrainingXp({
    required String userId,
    required String drillType,
    required bool perfectScore,
  }) async {
    final amount = perfectScore ? xpTrainingPerfectScore : xpTrainingCompleted;
    return await awardXp(
      userId: userId,
      amount: amount,
      reason: perfectScore
          ? 'Mükemmel ${_drillDisplayName(drillType)} antrenmanı'
          : '${_drillDisplayName(drillType)} antrenmanı tamamlandı',
      eventType: 'training_completed',
      sourceType: 'training',
      sourceId: _uuid.v4(),
      metadata: {'drillType': drillType, 'perfectScore': perfectScore},
    );
  }

  String _drillDisplayName(String drillType) {
    switch (drillType) {
      case 'shooting':
        return 'Şut';
      case 'passing':
        return 'Pas';
      case 'defending':
        return 'Savunma';
      case 'dribbling':
        return 'Top Sürüşü';
      case 'positioning':
        return 'Pozisyon';
      case 'composure':
        return 'Sakinlik';
      default:
        return drillType;
    }
  }

  /// Rate limiting - aynı eventType için dakikada maksimum XP
  Future<bool> isRateLimited({
    required String userId,
    required String eventType,
    int maxPerMinute = 10,
  }) async {
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    final recentCount = await firestoreService
        .userXpEvents(userId)
        .where('eventType', isEqualTo: eventType)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: oneMinuteAgo.toIso8601String(),
        )
        .count()
        .get();

    return (recentCount.count ?? 0) >= maxPerMinute;
  }

  /// Schedule badge check (async fire-and-forget)
  void _scheduleBadgeCheck({
    required String userId,
    required String eventType,
  }) {
    // Gecikmeli badge kontrolü
    Future.delayed(const Duration(seconds: 2), () {
      checkBadgeProgress(userId: userId, eventType: eventType);
    });
  }
}

/// Seviye atlama sonucu
class LevelUpResult {
  final int oldLevel;
  final int newLevel;
  final int levelsGained;
  final bool titleChanged;
  final String oldTitle;
  final String newTitle;
  final int bonusXp;

  const LevelUpResult({
    required this.oldLevel,
    required this.newLevel,
    required this.levelsGained,
    required this.titleChanged,
    required this.oldTitle,
    required this.newTitle,
    required this.bonusXp,
  });
}

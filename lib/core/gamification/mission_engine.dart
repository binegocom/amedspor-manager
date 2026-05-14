import '../../data/models/mission_model.dart';

/// Görev motoru - missionKey'leri koşul nesnelerine çözümler
/// Strategy Pattern kullanarak her görev tipi için özel kontrol
class MissionEngine {
  /// MissionKey formatı: "condition_type:target:threshold"
  /// Örnek: "login_streak:7", "total_xp:1000", "badge_count:3",
  ///         "prediction_accuracy:80", "training_count:shooting:10"
  ///         "social_total_likes:100"

  /// Bir missionKey'i parse et
  static ParsedMissionKey parseKey(String missionKey) {
    final parts = missionKey.split(':');
    final type = parts.isNotEmpty ? parts[0] : '';
    final target = parts.length > 1 ? parts[1] : '';
    final threshold = parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1;
    return ParsedMissionKey(type: type, target: target, threshold: threshold);
  }

  /// Kullanıcının belirli bir görevdeki ilerlemesini hesapla
  static int calculateProgress({
    required MissionModel mission,
    required Map<String, Object?> userStats,
    required List<Map<String, dynamic>> recentEvents,
  }) {
    final parsed = parseKey(mission.missionKey);

    switch (parsed.type) {
      case 'login_streak':
        return _getIntStat(userStats, 'currentLoginStreak');

      case 'total_xp':
        return _getIntStat(userStats, 'xp');

      case 'total_points':
        return _getIntStat(userStats, 'points');

      case 'level_reached':
        return _getIntStat(userStats, 'level');

      case 'badge_count':
        return _getIntStat(userStats, 'badgesCount');

      case 'missions_completed':
        return _getIntStat(userStats, 'missionsCompleted');

      case 'season_xp':
        return _getIntStat(userStats, 'seasonXp');

      case 'post_count':
        return _countEventsByType(recentEvents, 'post_created');

      case 'comment_count':
        return _countEventsByType(recentEvents, 'comment_created');

      case 'prediction_count':
        return _countEventsByType(recentEvents, 'prediction_created');

      case 'prediction_correct':
        return _countEventsByType(recentEvents, 'prediction_correct');

      case 'like_received':
        return _countEventsByType(recentEvents, 'like_received');

      case 'lineup_saved':
        return _countEventsByType(recentEvents, 'lineup_saved');

      case 'lineup_shared':
        return _countEventsByType(recentEvents, 'lineup_shared');

      case 'chat_message':
        return _countEventsByType(recentEvents, 'chat_message_matchday');

      case 'training_count':
        if (parsed.target.isNotEmpty) {
          // Belli bir drill tipi için filtrele
          return _countTrainingByDrill(recentEvents, parsed.target);
        }
        return _countEventsByType(recentEvents, 'training_completed');

      case 'daily_login_total':
        return _countEventsByType(recentEvents, 'daily_login');

      case 'match_watched':
        return _countEventsByType(recentEvents, 'live_match_opened');

      default:
        return _getIntStat(userStats, parsed.type, 0);
    }
  }

  /// Görevin tamamlanıp tamamlanmadığını kontrol et
  static bool isMissionCompleted({
    required MissionModel mission,
    required Map<String, Object?> userStats,
    required List<Map<String, dynamic>> recentEvents,
  }) {
    final progress = calculateProgress(
      mission: mission,
      userStats: userStats,
      recentEvents: recentEvents,
    );
    return progress >= mission.requiredCount;
  }

  /// Kullanıcı istatistiklerinden integer değer oku
  static int _getIntStat(
    Map<String, Object?> stats,
    String key, [
    int defaultValue = 0,
  ]) {
    final value = stats[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Event listesinden belirli türdeki eventleri say
  static int _countEventsByType(
    List<Map<String, dynamic>> events,
    String eventType,
  ) {
    return events.where((e) => e['eventType'] == eventType).length;
  }

  /// Antrenman drill tipine göre say
  static int _countTrainingByDrill(
    List<Map<String, dynamic>> events,
    String drillType,
  ) {
    return events.where((e) {
      if (e['eventType'] != 'training_completed') return false;
      final metadata = e['metadata'];
      if (metadata is Map) {
        return metadata['drillType'] == drillType;
      }
      return false;
    }).length;
  }

  /// Kullanıcı için uygun görevleri filtrele
  static List<MissionModel> filterAvailableMissions({
    required List<MissionModel> allMissions,
    required int userLevel,
    required List<String> completedMissionIds,
  }) {
    return allMissions.where((m) {
      // Aktif değilse atla
      if (!m.active) return false;

      // Zaman aralığı kontrolü
      final now = DateTime.now();
      if (m.startAt != null && now.isBefore(m.startAt!)) return false;
      if (m.endAt != null && now.isAfter(m.endAt!)) return false;

      // Daha önce tamamlanmış mı?
      if (completedMissionIds.contains(m.id)) return false;

      return true;
    }).toList();
  }

  /// Kullanıcı için günlük görevler oluştur
  static List<MissionModel> generateDailyMissions() {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return [
      MissionModel(
        id: 'daily_login_${now.day}${now.month}${now.year}',
        title: 'Günlük Giriş',
        description: 'Bugün uygulamaya giriş yap',
        type: 'daily',
        missionKey: 'daily_login_total:1',
        requiredCount: 1,
        xpReward: 10,
        pointsReward: 5,
        active: true,
        startAt: dayStart,
        endAt: dayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'daily_post_${now.day}${now.month}${now.year}',
        title: 'Günün Paylaşımı',
        description: 'Bugün bir paylaşım yap',
        type: 'daily',
        missionKey: 'post_count:1',
        requiredCount: 1,
        xpReward: 20,
        pointsReward: 10,
        active: true,
        startAt: dayStart,
        endAt: dayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'daily_prediction_${now.day}${now.month}${now.year}',
        title: 'Tahminini Yap',
        description: 'Bugün bir maç tahmini yap',
        type: 'daily',
        missionKey: 'prediction_count:1',
        requiredCount: 1,
        xpReward: 15,
        pointsReward: 8,
        active: true,
        startAt: dayStart,
        endAt: dayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'daily_like_${now.day}${now.month}${now.year}',
        title: 'Beğeni Yağmuru',
        description: 'Bugün 3 gönderiyi beğen',
        type: 'daily',
        missionKey: 'like_received:3',
        requiredCount: 3,
        xpReward: 10,
        pointsReward: 5,
        active: true,
        startAt: dayStart,
        endAt: dayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'daily_comment_${now.day}${now.month}${now.year}',
        title: 'Yorum Yap',
        description: 'Bugün 2 yorum yap',
        type: 'daily',
        missionKey: 'comment_count:2',
        requiredCount: 2,
        xpReward: 15,
        pointsReward: 8,
        active: true,
        startAt: dayStart,
        endAt: dayEnd,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'daily_chat_${now.day}${now.month}${now.year}',
        title: 'Sohbete Katıl',
        description: 'Bugün sohbette 5 mesaj gönder',
        type: 'daily',
        missionKey: 'chat_message:5',
        requiredCount: 5,
        xpReward: 10,
        pointsReward: 5,
        active: true,
        startAt: dayStart,
        endAt: dayEnd,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Haftalık görevler oluştur
  static List<MissionModel> generateWeeklyMissions() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final weekEndDay = weekStartDay.add(const Duration(days: 7));

    return [
      MissionModel(
        id: 'weekly_xp_${weekStartDay.day}${weekStartDay.month}${weekStartDay.year}',
        title: 'Haftanın Çalışkanı',
        description: 'Bu hafta 500 XP kazan',
        type: 'weekly',
        missionKey: 'total_xp:500',
        requiredCount: 500,
        xpReward: 100,
        pointsReward: 50,
        active: true,
        startAt: weekStartDay,
        endAt: weekEndDay,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'weekly_predictions_${weekStartDay.day}${weekStartDay.month}${weekStartDay.year}',
        title: 'Haftanın Kahini',
        description: 'Bu hafta 5 doğru tahmin yap',
        type: 'weekly',
        missionKey: 'prediction_correct:5',
        requiredCount: 5,
        xpReward: 150,
        pointsReward: 75,
        active: true,
        startAt: weekStartDay,
        endAt: weekEndDay,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'weekly_posts_${weekStartDay.day}${weekStartDay.month}${weekStartDay.year}',
        title: 'Haftanın Gazetecisi',
        description: 'Bu hafta 3 paylaşım yap',
        type: 'weekly',
        missionKey: 'post_count:3',
        requiredCount: 3,
        xpReward: 75,
        pointsReward: 35,
        active: true,
        startAt: weekStartDay,
        endAt: weekEndDay,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'weekly_lineups_${weekStartDay.day}${weekStartDay.month}${weekStartDay.year}',
        title: 'Kadro Kurucusu',
        description: 'Bu hafta 3 kadro kaydet',
        type: 'weekly',
        missionKey: 'lineup_saved:3',
        requiredCount: 3,
        xpReward: 75,
        pointsReward: 35,
        active: true,
        startAt: weekStartDay,
        endAt: weekEndDay,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Sezonluk görevler
  static List<MissionModel> generateSeasonalMissions() {
    final now = DateTime.now();
    final seasonStart = DateTime(now.year, 8, 1); // Sezon Ağustos'ta başlar
    final seasonEnd = DateTime(now.year + 1, 6, 1); // Mayıs'ta biter

    return [
      MissionModel(
        id: 'season_prediction_champion',
        title: 'Sezonun Kahini',
        description: 'Bu sezon 50 doğru tahmin yap',
        type: 'seasonal',
        missionKey: 'prediction_correct:50',
        requiredCount: 50,
        xpReward: 2000,
        pointsReward: 1000,
        badgeRewardId: 'kahin_altin',
        active: true,
        startAt: seasonStart,
        endAt: seasonEnd,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'season_posts',
        title: 'Sezonun Yazarı',
        description: 'Bu sezon 30 paylaşım yap',
        type: 'seasonal',
        missionKey: 'post_count:30',
        requiredCount: 30,
        xpReward: 1000,
        pointsReward: 500,
        badgeRewardId: 'yazar_altin',
        active: true,
        startAt: seasonStart,
        endAt: seasonEnd,
        createdAt: now,
        updatedAt: now,
      ),
      MissionModel(
        id: 'season_xp_master',
        title: 'Sezonun XP Ustası',
        description: 'Bu sezon 10000 XP kazan',
        type: 'seasonal',
        missionKey: 'season_xp:10000',
        requiredCount: 10000,
        xpReward: 3000,
        pointsReward: 1500,
        badgeRewardId: 'xp_ustasi',
        active: true,
        startAt: seasonStart,
        endAt: seasonEnd,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Görev ilerleme metni
  static String progressText(int current, int required) {
    final clamped = current > required ? required : current;
    return '$clamped / $required';
  }

  /// Görev tamamlanma yüzdesi
  static double progressPercentage(int current, int required) {
    if (required <= 0) return 1.0;
    return (current / required).clamp(0.0, 1.0);
  }
}

/// Çözümlenmiş mission key
class ParsedMissionKey {
  final String type;
  final String target;
  final int threshold;

  const ParsedMissionKey({
    required this.type,
    this.target = '',
    this.threshold = 1,
  });
}

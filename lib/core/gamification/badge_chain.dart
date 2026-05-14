import '../../data/models/badge_model.dart';

/// Kademeli rozet zincirleri
/// Örn: Günlük giriş -> 7 gün (Bronz) -> 30 gün (Gümüş) -> 100 gün (Altın) -> 365 gün (Elmas)
class BadgeChain {
  final String chainId;
  final String category;
  final String description;
  final List<BadgeTier> tiers;

  const BadgeChain({
    required this.chainId,
    required this.category,
    required this.description,
    required this.tiers,
  });

  /// Tüm rozet zincirleri
  static const List<BadgeChain> allChains = [
    // Günlük Giriş Zinciri
    BadgeChain(
      chainId: 'daily_login',
      category: 'Sadakat',
      description: 'Günlük giriş yaparak sadakatini göster',
      tiers: [
        BadgeTier(
          requiredCount: 7,
          title: 'Haftalık Sadık',
          description: '7 gün üst üste giriş yaptın!',
          icon: '🔰',
          colorValue: 0xFFCD7F32, // Bronz
          xpReward: 50,
          pointsReward: 25,
        ),
        BadgeTier(
          requiredCount: 30,
          title: 'Ayın Taraftarı',
          description: '30 gün üst üste giriş yaptın!',
          icon: '⭐',
          colorValue: 0xFFC0C0C0, // Gümüş
          xpReward: 150,
          pointsReward: 75,
        ),
        BadgeTier(
          requiredCount: 100,
          title: 'Centurion',
          description: '100 gün üst üste giriş yaptın!',
          icon: '💎',
          colorValue: 0xFFFFD700, // Altın
          xpReward: 500,
          pointsReward: 250,
        ),
        BadgeTier(
          requiredCount: 365,
          title: 'Yılın Taraftarı',
          description: 'Tam 1 yıl boyunca her gün giriş yaptın!',
          icon: '👑',
          colorValue: 0xFF00BFFF, // Elmas
          xpReward: 2000,
          pointsReward: 1000,
        ),
      ],
    ),

    // Tahmin Zinciri
    BadgeChain(
      chainId: 'prediction_correct',
      category: 'Tahmin',
      description: 'Doğru tahminlerle uzmanlığını kanıtla',
      tiers: [
        BadgeTier(
          requiredCount: 5,
          title: 'Tahmin Ustası Çırağı',
          description: '5 doğru tahmin!',
          icon: '🔮',
          colorValue: 0xFFCD7F32,
          xpReward: 75,
          pointsReward: 35,
        ),
        BadgeTier(
          requiredCount: 25,
          title: 'Tahmin Ustası',
          description: '25 doğru tahmin!',
          icon: '🔮',
          colorValue: 0xFFC0C0C0,
          xpReward: 250,
          pointsReward: 125,
        ),
        BadgeTier(
          requiredCount: 100,
          title: 'Kahin',
          description: '100 doğru tahmin!',
          icon: '🔮',
          colorValue: 0xFFFFD700,
          xpReward: 1000,
          pointsReward: 500,
        ),
      ],
    ),

    // Post Paylaşma Zinciri
    BadgeChain(
      chainId: 'post_created',
      category: 'Sosyal',
      description: 'Paylaşımlarınla tribüne ses ver',
      tiers: [
        BadgeTier(
          requiredCount: 10,
          title: 'Aktif Yazar',
          description: '10 paylaşım yaptın!',
          icon: '✍️',
          colorValue: 0xFFCD7F32,
          xpReward: 50,
          pointsReward: 25,
        ),
        BadgeTier(
          requiredCount: 50,
          title: 'Köşe Yazarı',
          description: '50 paylaşım yaptın!',
          icon: '✍️',
          colorValue: 0xFFC0C0C0,
          xpReward: 200,
          pointsReward: 100,
        ),
        BadgeTier(
          requiredCount: 200,
          title: 'Tribün Gazetecisi',
          description: '200 paylaşım yaptın!',
          icon: '📰',
          colorValue: 0xFFFFD700,
          xpReward: 800,
          pointsReward: 400,
        ),
      ],
    ),

    // Yorum Zinciri
    BadgeChain(
      chainId: 'comment_created',
      category: 'Sosyal',
      description: 'Yorumlarınla sohbete renk kat',
      tiers: [
        BadgeTier(
          requiredCount: 25,
          title: 'Sohbete Katılan',
          description: '25 yorum yaptın!',
          icon: '💬',
          colorValue: 0xFFCD7F32,
          xpReward: 50,
          pointsReward: 25,
        ),
        BadgeTier(
          requiredCount: 100,
          title: 'Tribün Konuşmacısı',
          description: '100 yorum yaptın!',
          icon: '💬',
          colorValue: 0xFFC0C0C0,
          xpReward: 200,
          pointsReward: 100,
        ),
        BadgeTier(
          requiredCount: 500,
          title: 'Efsanevi Hatip',
          description: '500 yorum yaptın!',
          icon: '🎙️',
          colorValue: 0xFFFFD700,
          xpReward: 1000,
          pointsReward: 500,
        ),
      ],
    ),

    // Antrenman Zinciri
    BadgeChain(
      chainId: 'training_completed',
      category: 'Antrenman',
      description: 'Antrenman yaparak takımına katkı sağla',
      tiers: [
        BadgeTier(
          requiredCount: 10,
          title: 'Çalışkan Oyuncu',
          description: '10 antrenman tamamladın!',
          icon: '🏋️',
          colorValue: 0xFFCD7F32,
          xpReward: 100,
          pointsReward: 50,
        ),
        BadgeTier(
          requiredCount: 50,
          title: 'Antrenman Canavarı',
          description: '50 antrenman tamamladın!',
          icon: '🏋️',
          colorValue: 0xFFC0C0C0,
          xpReward: 400,
          pointsReward: 200,
        ),
        BadgeTier(
          requiredCount: 200,
          title: 'Profesyonel Atlet',
          description: '200 antrenman tamamladın!',
          icon: '💪',
          colorValue: 0xFFFFD700,
          xpReward: 1500,
          pointsReward: 750,
        ),
      ],
    ),

    // Beğeni Alma Zinciri
    BadgeChain(
      chainId: 'like_received',
      category: 'Sosyal',
      description: 'Paylaşımlarının beğenilmesiyle popülerliğini artır',
      tiers: [
        BadgeTier(
          requiredCount: 50,
          title: 'Beğenilen İsim',
          description: '50 beğeni aldın!',
          icon: '👍',
          colorValue: 0xFFCD7F32,
          xpReward: 75,
          pointsReward: 35,
        ),
        BadgeTier(
          requiredCount: 500,
          title: 'Tribün Favorisi',
          description: '500 beğeni aldın!',
          icon: '🔥',
          colorValue: 0xFFC0C0C0,
          xpReward: 300,
          pointsReward: 150,
        ),
        BadgeTier(
          requiredCount: 2000,
          title: 'Süperstar',
          description: '2000 beğeni aldın!',
          icon: '🌟',
          colorValue: 0xFFFFD700,
          xpReward: 1500,
          pointsReward: 750,
        ),
      ],
    ),

    // Seviye Zinciri
    BadgeChain(
      chainId: 'level_reached',
      category: 'Başarı',
      description: 'Seviye atlayarak gelişimini göster',
      tiers: [
        BadgeTier(
          requiredCount: 10,
          title: 'Seviye 10',
          description: '10. seviyeye ulaştın!',
          icon: '🎯',
          colorValue: 0xFFCD7F32,
          xpReward: 200,
          pointsReward: 100,
        ),
        BadgeTier(
          requiredCount: 20,
          title: 'Seviye 20',
          description: '20. seviyeye ulaştın!',
          icon: '🎯',
          colorValue: 0xFFC0C0C0,
          xpReward: 500,
          pointsReward: 250,
        ),
        BadgeTier(
          requiredCount: 30,
          title: 'Seviye 30',
          description: '30. seviyeye ulaştın!',
          icon: '🏆',
          colorValue: 0xFFFFD700,
          xpReward: 1500,
          pointsReward: 750,
        ),
        BadgeTier(
          requiredCount: 50,
          title: 'Seviye 50 - Efsane',
          description: '50. seviyeye ulaştın! Gerçek bir efsanesin!',
          icon: '👑',
          colorValue: 0xFF00BFFF,
          xpReward: 5000,
          pointsReward: 2500,
        ),
      ],
    ),
  ];

  /// Bir zinciri chainId ile bul
  static BadgeChain? findChain(String chainId) {
    try {
      return allChains.firstWhere((c) => c.chainId == chainId);
    } catch (_) {
      return null;
    }
  }

  /// Belirli bir sayıdaki ilerlemeye göre kazanılacak tier'ları bul
  List<BadgeTier> earnedTiers(int currentCount) {
    return tiers.where((t) => currentCount >= t.requiredCount).toList();
  }

  /// Bir sonraki kazanılmamış tier'ı bul
  BadgeTier? nextUnearnedTier(int currentCount, int highestEarnedIndex) {
    for (int i = 0; i < tiers.length; i++) {
      if (i > highestEarnedIndex && currentCount < tiers[i].requiredCount) {
        return tiers[i];
      }
    }
    return null;
  }
}

/// Rozet tier'ı (Bronz -> Gümüş -> Altın -> Elmas)
class BadgeTier {
  final int requiredCount;
  final String title;
  final String description;
  final String icon;
  final int colorValue;
  final int xpReward;
  final int pointsReward;

  const BadgeTier({
    required this.requiredCount,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorValue,
    required this.xpReward,
    required this.pointsReward,
  });

  /// BadgeModel'e dönüştür (chainId ile)
  BadgeModel toBadgeModel(String chainId, String id) {
    return BadgeModel(
      id: id,
      title: title,
      description: description,
      category: chainId,
      icon: icon,
      colorValue: colorValue,
      xpReward: xpReward,
      pointsReward: pointsReward,
      requiredEvent: chainId,
      requiredCount: requiredCount,
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Tier seviyesini döndür (0 = Bronz, 1 = Gümüş, 2 = Altın, 3 = Elmas)
  int get tierLevel {
    switch (colorValue) {
      case 0xFFCD7F32:
        return 0; // Bronz
      case 0xFFC0C0C0:
        return 1; // Gümüş
      case 0xFFFFD700:
        return 2; // Altın
      case 0xFF00BFFF:
        return 3; // Elmas
      default:
        return 0;
    }
  }

  String get tierName {
    switch (tierLevel) {
      case 0:
        return 'Bronz';
      case 1:
        return 'Gümüş';
      case 2:
        return 'Altın';
      case 3:
        return 'Elmas';
      default:
        return 'Bronz';
    }
  }
}

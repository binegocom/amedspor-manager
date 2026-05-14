/// Çoklu seviye tier sistemi ile XP hesaplama
/// Her tier için farklı XP eğrisi, ünvan ve ödüller
class LevelCalculator {
  const LevelCalculator._();

  /// Tüm seviye tier tanımları
  static const List<LevelTier> tiers = [
    LevelTier(level: 1, xpRequired: 0, title: 'Yeni Taraftar', icon: '🌱'),
    LevelTier(level: 2, xpRequired: 50, title: 'Yeni Taraftar', icon: '🌱'),
    LevelTier(level: 3, xpRequired: 120, title: 'Yeni Taraftar', icon: '🌱'),
    LevelTier(level: 4, xpRequired: 200, title: 'Yeni Taraftar', icon: '🌱'),
    LevelTier(level: 5, xpRequired: 300, title: 'Tribün Üyesi', icon: '🎫'),
    LevelTier(level: 6, xpRequired: 450, title: 'Tribün Üyesi', icon: '🎫'),
    LevelTier(level: 7, xpRequired: 650, title: 'Tribün Üyesi', icon: '🎫'),
    LevelTier(level: 8, xpRequired: 900, title: 'Tribün Üyesi', icon: '🎫'),
    LevelTier(level: 9, xpRequired: 1200, title: 'Tribün Üyesi', icon: '🎫'),
    LevelTier(level: 10, xpRequired: 1600, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 11, xpRequired: 2100, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 12, xpRequired: 2700, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 13, xpRequired: 3400, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 14, xpRequired: 4200, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 15, xpRequired: 5100, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 16, xpRequired: 6100, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 17, xpRequired: 7200, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 18, xpRequired: 8400, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 19, xpRequired: 9800, title: 'Sadık Taraftar', icon: '❤️'),
    LevelTier(level: 20, xpRequired: 11500, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 21, xpRequired: 13500, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 22, xpRequired: 15800, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 23, xpRequired: 18400, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 24, xpRequired: 21300, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 25, xpRequired: 24500, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 26, xpRequired: 28000, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 27, xpRequired: 32000, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 28, xpRequired: 36500, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(level: 29, xpRequired: 41500, title: 'Tribün Lideri', icon: '📢'),
    LevelTier(
      level: 30,
      xpRequired: 47000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 31,
      xpRequired: 53000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 32,
      xpRequired: 60000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 33,
      xpRequired: 68000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 34,
      xpRequired: 77000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 35,
      xpRequired: 87000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 36,
      xpRequired: 98000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 37,
      xpRequired: 110000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 38,
      xpRequired: 123000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 39,
      xpRequired: 137000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 40,
      xpRequired: 152000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 41,
      xpRequired: 168000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 42,
      xpRequired: 185000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 43,
      xpRequired: 203000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 44,
      xpRequired: 222000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 45,
      xpRequired: 242000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 46,
      xpRequired: 263000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 47,
      xpRequired: 285000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 48,
      xpRequired: 308000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 49,
      xpRequired: 332000,
      title: 'Efsane Taraftar',
      icon: '⭐',
    ),
    LevelTier(
      level: 50,
      xpRequired: 360000,
      title: 'Amedspor Elçisi',
      icon: '🏅',
    ),
    // 50+ seviyeleri için: her seviye +20,000 XP
  ];

  /// Maksimum tanımlı seviye
  static int get maxDefinedLevel => tiers.last.level;

  /// Verilen XP'ye göre seviye hesapla
  static int calculateLevel(int xp) {
    int level = 1;
    for (final tier in tiers) {
      if (xp >= tier.xpRequired) {
        level = tier.level;
      } else {
        break;
      }
    }
    return level;
  }

  /// Seviyeye ait ünvanı getir
  static String levelTitleFor(int level) {
    for (final tier in tiers.reversed) {
      if (level >= tier.level) {
        return tier.title;
      }
    }
    return 'Yeni Taraftar';
  }

  /// Seviyeye ait simgeyi getir
  static String levelIconFor(int level) {
    for (final tier in tiers.reversed) {
      if (level >= tier.level) {
        return tier.icon;
      }
    }
    return '🌱';
  }

  /// Bir sonraki seviye için gereken XP'yi hesapla
  static int xpRequiredForNextLevel(int currentLevel) {
    final nextLevel = currentLevel + 1;
    for (final tier in tiers) {
      if (tier.level == nextLevel) {
        return tier.xpRequired;
      }
    }
    // Tanımlı seviyelerin ötesinde: her seviye +20,000 XP
    final baseXp = tiers.last.xpRequired;
    final extraLevels = nextLevel - maxDefinedLevel;
    return baseXp + (extraLevels * 20000);
  }

  /// Mevcut XP'ye göre ilerleme yüzdesi (0.0 - 1.0)
  static double progressPercentage(int currentXp, int currentLevel) {
    final currentTierXp = xpForLevel(currentLevel);
    final nextTierXp = xpRequiredForNextLevel(currentLevel);
    final neededXp = nextTierXp - currentTierXp;
    if (neededXp <= 0) return 1.0;
    final earnedXpInTier = currentXp - currentTierXp;
    return (earnedXpInTier / neededXp).clamp(0.0, 1.0);
  }

  /// Belirli bir seviye için gereken XP (alt sınır)
  static int xpForLevel(int level) {
    for (final tier in tiers) {
      if (tier.level == level) {
        return tier.xpRequired;
      }
    }
    return 0;
  }

  /// Seviye atlama bonus XP'si
  static int levelUpBonusXp(int newLevel) {
    if (newLevel <= 5) return 0;
    if (newLevel <= 10) return 10;
    if (newLevel <= 20) return 25;
    if (newLevel <= 30) return 50;
    if (newLevel <= 50) return 100;
    return 200;
  }

  /// Kaç seviye atlandığını hesapla
  static int levelsGained(int oldXp, int newXp) {
    return calculateLevel(newXp) - calculateLevel(oldXp);
  }

  /// Yeni ünvan kazanıldı mı?
  static bool hasTitleChanged(int oldLevel, int newLevel) {
    return levelTitleFor(oldLevel) != levelTitleFor(newLevel);
  }
}

/// Seviye tier tanımı
class LevelTier {
  final int level;
  final int xpRequired;
  final String title;
  final String icon;

  const LevelTier({
    required this.level,
    required this.xpRequired,
    required this.title,
    required this.icon,
  });
}

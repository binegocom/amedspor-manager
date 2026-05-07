import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final int points;
  final List<String> badges;
  final DateTime createdAt;
  final String city;
  final String supportYear;
  final String role;
  final String? fcmToken;
  final Map<String, bool> notificationPrefs;
  final int followersCount;
  final int followingCount;
  final bool isDisabled;

  // Gamification Fields
  final int xp;
  final int level;
  final String levelTitle;
  final int badgesCount;
  final int missionsCompleted;
  final int currentLoginStreak;
  final int bestLoginStreak;
  final DateTime? lastLoginRewardDate;
  final DateTime? lastActiveAt;
  final int seasonXp;
  final int seasonPoints;
  final bool gamificationEnabled;

  const AppUserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.points,
    required this.badges,
    required this.createdAt,
    required this.city,
    required this.supportYear,
    required this.role,
    this.fcmToken,
    this.isDisabled = false,
    this.notificationPrefs = const {
      'match': true,
      'chat': true,
      'like': true,
    },
    this.followersCount = 0,
    this.followingCount = 0,
    this.xp = 0,
    this.level = 1,
    this.levelTitle = 'Yeni Taraftar',
    this.badgesCount = 0,
    this.missionsCompleted = 0,
    this.currentLoginStreak = 0,
    this.bestLoginStreak = 0,
    this.lastLoginRewardDate,
    this.lastActiveAt,
    this.seasonXp = 0,
    this.seasonPoints = 0,
    this.gamificationEnabled = true,
  });

  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    return AppUserModel(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      points: map['points'] ?? 0,
      badges: (map['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: _parseDate(map['createdAt']),
      city: map['city'] ?? '',
      supportYear: map['supportYear'] ?? '2024',
      role: map['role'] ?? 'user',
      isDisabled: map['disabled'] ?? false,
      fcmToken: map['fcmToken'] as String?,
      notificationPrefs: Map<String, bool>.from(map['notificationPrefs'] ?? {
        'match': true,
        'chat': true,
        'like': true,
      }),
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      levelTitle: map['levelTitle'] ?? 'Yeni Taraftar',
      badgesCount: map['badgesCount'] ?? 0,
      missionsCompleted: map['missionsCompleted'] ?? 0,
      currentLoginStreak: map['currentLoginStreak'] ?? 0,
      bestLoginStreak: map['bestLoginStreak'] ?? 0,
      lastLoginRewardDate: _parseNullableDate(map['lastLoginRewardDate']),
      lastActiveAt: _parseNullableDate(map['lastActiveAt']),
      seasonXp: map['seasonXp'] ?? 0,
      seasonPoints: map['seasonPoints'] ?? 0,
      gamificationEnabled: map['gamificationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'points': points,
      'badges': badges,
      'createdAt': createdAt.toIso8601String(),
      'city': city,
      'supportYear': supportYear,
      'role': role,
      'disabled': isDisabled,
      'notificationPrefs': notificationPrefs,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'xp': xp,
      'level': level,
      'levelTitle': levelTitle,
      'badgesCount': badgesCount,
      'missionsCompleted': missionsCompleted,
      'currentLoginStreak': currentLoginStreak,
      'bestLoginStreak': bestLoginStreak,
      if (lastLoginRewardDate != null) 'lastLoginRewardDate': lastLoginRewardDate?.toIso8601String(),
      if (lastActiveAt != null) 'lastActiveAt': lastActiveAt?.toIso8601String(),
      'seasonXp': seasonXp,
      'seasonPoints': seasonPoints,
      'gamificationEnabled': gamificationEnabled,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  AppUserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    int? points,
    List<String>? badges,
    DateTime? createdAt,
    String? city,
    String? supportYear,
    String? role,
    String? fcmToken,
    Map<String, bool>? notificationPrefs,
    int? followersCount,
    int? followingCount,
    bool? isDisabled,
    int? xp,
    int? level,
    String? levelTitle,
    int? badgesCount,
    int? missionsCompleted,
    int? currentLoginStreak,
    int? bestLoginStreak,
    DateTime? lastLoginRewardDate,
    DateTime? lastActiveAt,
    int? seasonXp,
    int? seasonPoints,
    bool? gamificationEnabled,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      supportYear: supportYear ?? this.supportYear,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isDisabled: isDisabled ?? this.isDisabled,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      badgesCount: badgesCount ?? this.badgesCount,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      currentLoginStreak: currentLoginStreak ?? this.currentLoginStreak,
      bestLoginStreak: bestLoginStreak ?? this.bestLoginStreak,
      lastLoginRewardDate: lastLoginRewardDate ?? this.lastLoginRewardDate,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      seasonXp: seasonXp ?? this.seasonXp,
      seasonPoints: seasonPoints ?? this.seasonPoints,
      gamificationEnabled: gamificationEnabled ?? this.gamificationEnabled,
    );
  }
}

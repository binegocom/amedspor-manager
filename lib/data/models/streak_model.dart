import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class StreakModel extends Equatable {
  final String id;
  final String userId;
  final String type; // daily_login, prediction, lineup, etc.
  final int currentCount;
  final int bestCount;
  final DateTime lastUpdatedAt;
  final bool active;

  const StreakModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.currentCount,
    required this.bestCount,
    required this.lastUpdatedAt,
    this.active = true,
  });

  factory StreakModel.fromMap(String id, Map<String, dynamic> map) {
    return StreakModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'daily_login',
      currentCount: map['currentCount'] ?? 0,
      bestCount: map['bestCount'] ?? 0,
      lastUpdatedAt: _parseDate(map['lastUpdatedAt']),
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'currentCount': currentCount,
      'bestCount': bestCount,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'active': active,
    };
  }

  StreakModel copyWith({
    int? currentCount,
    int? bestCount,
    DateTime? lastUpdatedAt,
    bool? active,
  }) {
    return StreakModel(
      id: id,
      userId: userId,
      type: type,
      currentCount: currentCount ?? this.currentCount,
      bestCount: bestCount ?? this.bestCount,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      active: active ?? this.active,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        currentCount,
        bestCount,
        lastUpdatedAt,
        active,
      ];
}

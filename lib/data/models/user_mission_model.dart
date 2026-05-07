import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserMissionModel extends Equatable {
  final String id;
  final String missionId;
  final String userId;
  final String title;
  final String description;
  final String category; // daily, weekly, season
  final int xpReward;
  final int progress;
  final int requiredCount;
  final bool completed;
  final bool claimed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? claimedAt;

  const UserMissionModel({
    required this.id,
    required this.missionId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.progress,
    required this.requiredCount,
    required this.completed,
    required this.claimed,
    required this.startedAt,
    this.completedAt,
    this.claimedAt,
  });

  factory UserMissionModel.fromMap(String id, Map<String, dynamic> map) {
    return UserMissionModel(
      id: id,
      missionId: map['missionId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'daily',
      xpReward: map['xpReward'] ?? 0,
      progress: map['progress'] ?? 0,
      requiredCount: map['requiredCount'] ?? 1,
      completed: map['completed'] ?? false,
      claimed: map['claimed'] ?? false,
      startedAt: _parseDate(map['startedAt']),
      completedAt: _parseNullableDate(map['completedAt']),
      claimedAt: _parseNullableDate(map['claimedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'xpReward': xpReward,
      'progress': progress,
      'requiredCount': requiredCount,
      'completed': completed,
      'claimed': claimed,
      'startedAt': startedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt?.toIso8601String(),
      if (claimedAt != null) 'claimedAt': claimedAt?.toIso8601String(),
    };
  }

  UserMissionModel copyWith({
    String? title,
    String? description,
    String? category,
    int? xpReward,
    int? progress,
    bool? completed,
    bool? claimed,
    DateTime? completedAt,
    DateTime? claimedAt,
  }) {
    return UserMissionModel(
      id: id,
      missionId: missionId,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      progress: progress ?? this.progress,
      requiredCount: requiredCount,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        missionId,
        userId,
        progress,
        requiredCount,
        completed,
        claimed,
        startedAt,
        completedAt,
        claimedAt,
      ];
}

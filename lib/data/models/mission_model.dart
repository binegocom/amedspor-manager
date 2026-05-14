import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MissionModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type; // daily, weekly, seasonal, special
  final String missionKey;
  final int requiredCount;
  final int xpReward;
  final int pointsReward;
  final String? badgeRewardId;
  final String? nextMissionId; // for chained missions
  final bool isChained;
  final bool active;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.missionKey,
    required this.requiredCount,
    required this.xpReward,
    required this.pointsReward,
    this.badgeRewardId,
    this.nextMissionId,
    this.isChained = false,
    this.active = true,
    this.startAt,
    this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MissionModel.fromMap(String id, Map<String, dynamic> map) {
    return MissionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'daily',
      missionKey: map['missionKey'] ?? '',
      requiredCount: map['requiredCount'] ?? 1,
      xpReward: map['xpReward'] ?? 0,
      pointsReward: map['pointsReward'] ?? 0,
      badgeRewardId: map['badgeRewardId'] as String?,
      nextMissionId: map['nextMissionId'] as String?,
      isChained: map['isChained'] ?? false,
      active: map['active'] ?? true,
      startAt: _parseNullableDate(map['startAt']),
      endAt: _parseNullableDate(map['endAt']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'missionKey': missionKey,
      'requiredCount': requiredCount,
      'xpReward': xpReward,
      'pointsReward': pointsReward,
      if (badgeRewardId != null) 'badgeRewardId': badgeRewardId,
      if (nextMissionId != null) 'nextMissionId': nextMissionId,
      'isChained': isChained,
      'active': active,
      if (startAt != null) 'startAt': startAt?.toIso8601String(),
      if (endAt != null) 'endAt': endAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MissionModel copyWith({
    String? title,
    String? description,
    String? type,
    String? missionKey,
    int? requiredCount,
    int? xpReward,
    int? pointsReward,
    String? badgeRewardId,
    String? nextMissionId,
    bool? isChained,
    bool? active,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? updatedAt,
  }) {
    return MissionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      missionKey: missionKey ?? this.missionKey,
      requiredCount: requiredCount ?? this.requiredCount,
      xpReward: xpReward ?? this.xpReward,
      pointsReward: pointsReward ?? this.pointsReward,
      badgeRewardId: badgeRewardId ?? this.badgeRewardId,
      nextMissionId: nextMissionId ?? this.nextMissionId,
      isChained: isChained ?? this.isChained,
      active: active ?? this.active,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        title,
        description,
        type,
        missionKey,
        requiredCount,
        xpReward,
        pointsReward,
        badgeRewardId,
        nextMissionId,
        isChained,
        active,
        startAt,
        endAt,
        createdAt,
        updatedAt,
      ];
}

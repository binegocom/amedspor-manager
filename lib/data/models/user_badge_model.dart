import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserBadgeModel extends Equatable {
  final String id;
  final String badgeId;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String icon;
  final int colorValue;
  final DateTime earnedAt;
  final String sourceType;
  final String sourceId;
  final int xpReward;
  final int pointsReward;

  const UserBadgeModel({
    required this.id,
    required this.badgeId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.colorValue,
    required this.earnedAt,
    required this.sourceType,
    required this.sourceId,
    required this.xpReward,
    required this.pointsReward,
  });

  factory UserBadgeModel.fromMap(String id, Map<String, dynamic> map) {
    return UserBadgeModel(
      id: id,
      badgeId: map['badgeId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'general',
      icon: map['icon'] ?? '',
      colorValue: map['colorValue'] ?? 0xFFE53935,
      earnedAt: _parseDate(map['earnedAt']),
      sourceType: map['sourceType'] ?? '',
      sourceId: map['sourceId'] ?? '',
      xpReward: map['xpReward'] ?? 0,
      pointsReward: map['pointsReward'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'colorValue': colorValue,
      'earnedAt': earnedAt.toIso8601String(),
      'sourceType': sourceType,
      'sourceId': sourceId,
      'xpReward': xpReward,
      'pointsReward': pointsReward,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props => [
        id,
        badgeId,
        userId,
        title,
        description,
        category,
        icon,
        colorValue,
        earnedAt,
        sourceType,
        sourceId,
        xpReward,
        pointsReward,
      ];
}

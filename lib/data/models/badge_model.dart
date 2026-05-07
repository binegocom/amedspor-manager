import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BadgeModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final int colorValue; // Storing color as int
  final int xpReward;
  final int pointsReward;
  final String requiredEvent;
  final int requiredCount;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.colorValue,
    required this.xpReward,
    required this.pointsReward,
    required this.requiredEvent,
    required this.requiredCount,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BadgeModel.fromMap(String id, Map<String, dynamic> map) {
    return BadgeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'general',
      icon: map['icon'] ?? '',
      colorValue: map['colorValue'] ?? 0xFFE53935,
      xpReward: map['xpReward'] ?? 0,
      pointsReward: map['pointsReward'] ?? 0,
      requiredEvent: map['requiredEvent'] ?? '',
      requiredCount: map['requiredCount'] ?? 0,
      active: map['active'] ?? true,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'colorValue': colorValue,
      'xpReward': xpReward,
      'pointsReward': pointsReward,
      'requiredEvent': requiredEvent,
      'requiredCount': requiredCount,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BadgeModel copyWith({
    String? title,
    String? description,
    String? category,
    String? icon,
    int? colorValue,
    int? xpReward,
    int? pointsReward,
    String? requiredEvent,
    int? requiredCount,
    bool? active,
    DateTime? updatedAt,
  }) {
    return BadgeModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      xpReward: xpReward ?? this.xpReward,
      pointsReward: pointsReward ?? this.pointsReward,
      requiredEvent: requiredEvent ?? this.requiredEvent,
      requiredCount: requiredCount ?? this.requiredCount,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        title,
        description,
        category,
        icon,
        colorValue,
        xpReward,
        pointsReward,
        requiredEvent,
        requiredCount,
        active,
        createdAt,
        updatedAt,
      ];
}

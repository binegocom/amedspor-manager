import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SeasonModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final bool active;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SeasonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.active,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SeasonModel.fromMap(String id, Map<String, dynamic> map) {
    return SeasonModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      active: map['active'] ?? true,
      startAt: _parseDate(map['startAt']),
      endAt: _parseDate(map['endAt']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'active': active,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SeasonModel copyWith({
    String? title,
    String? description,
    bool? active,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? updatedAt,
  }) {
    return SeasonModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
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

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        active,
        startAt,
        endAt,
        createdAt,
        updatedAt,
      ];
}

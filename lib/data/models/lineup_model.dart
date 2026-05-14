import 'package:cloud_firestore/cloud_firestore.dart';

class LineupModel {
  final String id;
  final String userId;
  final String matchId;
  final String formation;
  final String? philosophy; // Taktiksel felsefe (Gegenpressing, Tiki-Taka, Catenaccio vb.)
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> substitutes;
  final int likes;
  final int power;
  final int commentsCount;
  final DateTime createdAt;

  const LineupModel({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.formation,
    this.philosophy,
    required this.players,
    required this.substitutes,
    required this.likes,
    required this.power,
    required this.commentsCount,
    required this.createdAt,
  });

  factory LineupModel.fromMap(String id, Map<String, dynamic> map) {
    return LineupModel(
      id: id,
      userId: map['userId'] ?? '',
      matchId: map['matchId'] ?? '',
      formation: map['formation'] ?? '4-3-3',
      philosophy: map['philosophy'] as String?,
      players: List<Map<String, dynamic>>.from(map['players'] ?? []),
      substitutes: List<Map<String, dynamic>>.from(map['substitutes'] ?? []),
      likes: map['likes'] ?? 0,
      power: map['power'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'matchId': matchId,
      'formation': formation,
      if (philosophy != null) 'philosophy': philosophy,
      'players': players,
      'substitutes': substitutes,
      'likes': likes,
      'power': power,
      'commentsCount': commentsCount,
      'createdAt': createdAt.toIso8601String(),
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
}

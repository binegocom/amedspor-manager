import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SeasonStatModel extends Equatable {
  final String id;
  final String seasonId;
  final String userId;
  final int xp;
  final int points;
  final int lineupsCount;
  final int predictionsCount;
  final int postsCount;
  final int commentsCount;
  final int chatMessagesCount;
  final int badgesEarned;
  final DateTime updatedAt;

  const SeasonStatModel({
    required this.id,
    required this.seasonId,
    required this.userId,
    this.xp = 0,
    this.points = 0,
    this.lineupsCount = 0,
    this.predictionsCount = 0,
    this.postsCount = 0,
    this.commentsCount = 0,
    this.chatMessagesCount = 0,
    this.badgesEarned = 0,
    required this.updatedAt,
  });

  factory SeasonStatModel.fromMap(String id, Map<String, dynamic> map) {
    return SeasonStatModel(
      id: id,
      seasonId: map['seasonId'] ?? '',
      userId: map['userId'] ?? '',
      xp: map['xp'] ?? 0,
      points: map['points'] ?? 0,
      lineupsCount: map['lineupsCount'] ?? 0,
      predictionsCount: map['predictionsCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      chatMessagesCount: map['chatMessagesCount'] ?? 0,
      badgesEarned: map['badgesEarned'] ?? 0,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seasonId': seasonId,
      'userId': userId,
      'xp': xp,
      'points': points,
      'lineupsCount': lineupsCount,
      'predictionsCount': predictionsCount,
      'postsCount': postsCount,
      'commentsCount': commentsCount,
      'chatMessagesCount': chatMessagesCount,
      'badgesEarned': badgesEarned,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SeasonStatModel copyWith({
    int? xp,
    int? points,
    int? lineupsCount,
    int? predictionsCount,
    int? postsCount,
    int? commentsCount,
    int? chatMessagesCount,
    int? badgesEarned,
    DateTime? updatedAt,
  }) {
    return SeasonStatModel(
      id: id,
      seasonId: seasonId,
      userId: userId,
      xp: xp ?? this.xp,
      points: points ?? this.points,
      lineupsCount: lineupsCount ?? this.lineupsCount,
      predictionsCount: predictionsCount ?? this.predictionsCount,
      postsCount: postsCount ?? this.postsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      chatMessagesCount: chatMessagesCount ?? this.chatMessagesCount,
      badgesEarned: badgesEarned ?? this.badgesEarned,
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
        seasonId,
        userId,
        xp,
        points,
        lineupsCount,
        predictionsCount,
        postsCount,
        commentsCount,
        chatMessagesCount,
        badgesEarned,
        updatedAt,
      ];
}

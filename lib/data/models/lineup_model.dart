class LineupModel {
  final String id;
  final String userId;
  final String matchId;
  final String formation;
  final List<Map<String, dynamic>> players;
  final int likes;
  final int power;
  final int commentsCount;
  final DateTime createdAt;

  const LineupModel({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.formation,
    required this.players,
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
      players: List<Map<String, dynamic>>.from(map['players'] ?? []),
      likes: map['likes'] ?? 0,
      power: map['power'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'matchId': matchId,
      'formation': formation,
      'players': players,
      'likes': likes,
      'power': power,
      'commentsCount': commentsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

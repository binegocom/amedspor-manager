class PredictionModel {
  final String id;
  final String userId;
  final String matchId;
  final int homeScore;
  final int awayScore;
  final String firstScorer;
  final int pointsEarned;
  final DateTime createdAt;

  const PredictionModel({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.homeScore,
    required this.awayScore,
    required this.firstScorer,
    required this.pointsEarned,
    required this.createdAt,
  });

  factory PredictionModel.fromMap(String id, Map<String, dynamic> map) {
    return PredictionModel(
      id: id,
      userId: map['userId'] ?? '',
      matchId: map['matchId'] ?? '',
      homeScore: map['homeScore'] ?? 0,
      awayScore: map['awayScore'] ?? 0,
      firstScorer: map['firstScorer'] ?? '',
      pointsEarned: map['pointsEarned'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'matchId': matchId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'firstScorer': firstScorer,
      'pointsEarned': pointsEarned,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
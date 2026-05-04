class MatchModel {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime matchDate;
  final String status;
  final String score;

  const MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchDate,
    required this.status,
    required this.score,
  });

  factory MatchModel.fromMap(String id, Map<String, dynamic> map) {
    return MatchModel(
      id: id,
      homeTeam: map['homeTeam'] ?? '',
      awayTeam: map['awayTeam'] ?? '',
      matchDate: DateTime.tryParse(map['matchDate'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'upcoming',
      score: map['score'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'matchDate': matchDate.toIso8601String(),
      'status': status,
      'score': score,
    };
  }
}
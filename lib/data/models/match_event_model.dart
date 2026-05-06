class MatchEventModel {
  final String id;
  final String type; // goal, yellowCard, redCard, substitution
  final int minute;
  final String team; // home, away
  final String playerName;
  final String? playerNameOut; // For substitutions
  final String description;
  final DateTime createdAt;

  const MatchEventModel({
    required this.id,
    required this.type,
    required this.minute,
    required this.team,
    required this.playerName,
    this.playerNameOut,
    required this.description,
    required this.createdAt,
  });

  factory MatchEventModel.fromMap(String id, Map<String, dynamic> map) {
    return MatchEventModel(
      id: id,
      type: map['type'] ?? 'goal',
      minute: map['minute'] ?? 0,
      team: map['team'] ?? 'home',
      playerName: map['playerName'] ?? '',
      playerNameOut: map['playerNameOut'],
      description: map['description'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'minute': minute,
      'team': team,
      'playerName': playerName,
      'playerNameOut': playerNameOut,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

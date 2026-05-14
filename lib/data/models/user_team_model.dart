class UserTeamModel {
  final String id;
  final String userId;
  final String name;
  final String? logoUrl;
  final int budget; // Current money
  final int weeklyIncome; // From sponsors, tickets
  final int weeklyExpenses; // Salaries, maintenance
  final int attackPower;
  final int defensePower;
  final int midfieldPower;
  final String formation;
  final List<String> playerIds;
  final String? leagueId;
  final int leaguePosition;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int sponsorLevel; // 0-5, affects income

  const UserTeamModel({
    required this.id,
    required this.userId,
    required this.name,
    this.logoUrl,
    this.budget = 1000000,
    this.weeklyIncome = 50000,
    this.weeklyExpenses = 30000,
    this.attackPower = 50,
    this.defensePower = 50,
    this.midfieldPower = 50,
    this.formation = '4-4-2',
    this.playerIds = const [],
    this.leagueId,
    this.leaguePosition = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.sponsorLevel = 1,
  });

  factory UserTeamModel.fromMap(String id, Map<String, dynamic> map) {
    return UserTeamModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'My Team',
      logoUrl: map['logoUrl'],
      budget: map['budget'] ?? 1000000,
      weeklyIncome: map['weeklyIncome'] ?? 50000,
      weeklyExpenses: map['weeklyExpenses'] ?? 30000,
      attackPower: map['attackPower'] ?? 50,
      defensePower: map['defensePower'] ?? 50,
      midfieldPower: map['midfieldPower'] ?? 50,
      formation: map['formation'] ?? '4-4-2',
      playerIds: List<String>.from(map['playerIds'] ?? []),
      leagueId: map['leagueId'],
      leaguePosition: map['leaguePosition'] ?? 0,
      wins: map['wins'] ?? 0,
      draws: map['draws'] ?? 0,
      losses: map['losses'] ?? 0,
      goalsFor: map['goalsFor'] ?? 0,
      goalsAgainst: map['goalsAgainst'] ?? 0,
      sponsorLevel: map['sponsorLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'logoUrl': logoUrl,
      'budget': budget,
      'weeklyIncome': weeklyIncome,
      'weeklyExpenses': weeklyExpenses,
      'attackPower': attackPower,
      'defensePower': defensePower,
      'midfieldPower': midfieldPower,
      'formation': formation,
      'playerIds': playerIds,
      'leagueId': leagueId,
      'leaguePosition': leaguePosition,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'sponsorLevel': sponsorLevel,
    };
  }

  UserTeamModel copyWith({
    String? userId,
    String? name,
    String? logoUrl,
    int? budget,
    int? weeklyIncome,
    int? weeklyExpenses,
    int? attackPower,
    int? defensePower,
    int? midfieldPower,
    String? formation,
    List<String>? playerIds,
    String? leagueId,
    int? leaguePosition,
    int? wins,
    int? draws,
    int? losses,
    int? goalsFor,
    int? goalsAgainst,
    int? sponsorLevel,
  }) {
    return UserTeamModel(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      budget: budget ?? this.budget,
      weeklyIncome: weeklyIncome ?? this.weeklyIncome,
      weeklyExpenses: weeklyExpenses ?? this.weeklyExpenses,
      attackPower: attackPower ?? this.attackPower,
      defensePower: defensePower ?? this.defensePower,
      midfieldPower: midfieldPower ?? this.midfieldPower,
      formation: formation ?? this.formation,
      playerIds: playerIds ?? this.playerIds,
      leagueId: leagueId ?? this.leagueId,
      leaguePosition: leaguePosition ?? this.leaguePosition,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      sponsorLevel: sponsorLevel ?? this.sponsorLevel,
    );
  }

  // Computed properties
  int get played => wins + draws + losses;
  int get points => wins * 3 + draws;
  int get goalDifference => goalsFor - goalsAgainst;
}
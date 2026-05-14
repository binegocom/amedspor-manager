class PlayerModel {
  final String id;
  final String? ownerId;
  final String name;
  final String position;
  final int number;
  final int rating; // Overall Rating
  final bool active;

  // ---- NEW GAMIFICATION ATTRIBUTES ----
  final int fitness; // 0-100
  final int morale; // 0-100

  // Detailed Skills (0-100)
  final int shooting;
  final int passing;
  final int defending;
  final int dribbling;
  final int positioning;
  final int composure;

  // Market & Info
  final int marketValue;
  final String? imageUrl;

  // Progression & Status
  final int level;
  final int experience;
  final int stars;
  final int age;
  final bool injured;
  final int injuryDays;
  final bool suspended;
  final int suspensionMatches;
  final int yellowCards;

  const PlayerModel({
    required this.id,
    this.ownerId,
    required this.name,
    required this.position,
    required this.number,
    required this.rating,
    required this.active,
    this.fitness = 100,
    this.morale = 100,
    this.shooting = 50,
    this.passing = 50,
    this.defending = 50,
    this.dribbling = 50,
    this.positioning = 50,
    this.composure = 50,
    this.marketValue = 100000,
    this.imageUrl,
    this.level = 1,
    this.experience = 0,
    this.stars = 1,
    this.age = 20,
    this.injured = false,
    this.injuryDays = 0,
    this.suspended = false,
    this.suspensionMatches = 0,
    this.yellowCards = 0,
  });

  factory PlayerModel.fromMap(String id, Map<String, dynamic> map) {
    return PlayerModel(
      id: id,
      ownerId: map['ownerId'],
      name: map['name'] ?? '',
      position: map['position'] ?? 'MID',
      number: map['number'] ?? 0,
      rating: map['rating'] ?? 70,
      active: map['active'] ?? true,
      fitness: map['fitness'] ?? 100,
      morale: map['morale'] ?? 100,
      shooting: map['shooting'] ?? 50,
      passing: map['passing'] ?? 50,
      defending: map['defending'] ?? 50,
      dribbling: map['dribbling'] ?? 50,
      positioning: map['positioning'] ?? 50,
      composure: map['composure'] ?? 50,
      marketValue: map['marketValue'] ?? 100000,
      imageUrl: map['imageUrl'],
      level: map['level'] ?? 1,
      experience: map['experience'] ?? 0,
      stars: map['stars'] ?? 1,
      age: map['age'] ?? 20,
      injured: map['injured'] ?? false,
      injuryDays: map['injuryDays'] ?? 0,
      suspended: map['suspended'] ?? false,
      suspensionMatches: map['suspensionMatches'] ?? 0,
      yellowCards: map['yellowCards'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'position': position,
      'number': number,
      'rating': rating,
      'active': active,
      'fitness': fitness,
      'morale': morale,
      'shooting': shooting,
      'passing': passing,
      'defending': defending,
      'dribbling': dribbling,
      'positioning': positioning,
      'composure': composure,
      'marketValue': marketValue,
      'imageUrl': imageUrl,
      'level': level,
      'experience': experience,
      'stars': stars,
      'age': age,
      'injured': injured,
      'injuryDays': injuryDays,
      'suspended': suspended,
      'suspensionMatches': suspensionMatches,
      'yellowCards': yellowCards,
    };
  }

  PlayerModel copyWith({
    String? name,
    String? ownerId,
    String? position,
    int? number,
    int? rating,
    bool? active,
    int? fitness,
    int? morale,
    int? shooting,
    int? passing,
    int? defending,
    int? dribbling,
    int? positioning,
    int? composure,
    int? marketValue,
    String? imageUrl,
    int? level,
    int? experience,
    int? stars,
    int? age,
    bool? injured,
    int? injuryDays,
    bool? suspended,
    int? suspensionMatches,
    int? yellowCards,
  }) {
    return PlayerModel(
      id: id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      position: position ?? this.position,
      number: number ?? this.number,
      rating: rating ?? this.rating,
      active: active ?? this.active,
      fitness: fitness ?? this.fitness,
      morale: morale ?? this.morale,
      shooting: shooting ?? this.shooting,
      passing: passing ?? this.passing,
      defending: defending ?? this.defending,
      dribbling: dribbling ?? this.dribbling,
      positioning: positioning ?? this.positioning,
      composure: composure ?? this.composure,
      marketValue: marketValue ?? this.marketValue,
      imageUrl: imageUrl ?? this.imageUrl,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      stars: stars ?? this.stars,
      age: age ?? this.age,
      injured: injured ?? this.injured,
      injuryDays: injuryDays ?? this.injuryDays,
      suspended: suspended ?? this.suspended,
      suspensionMatches: suspensionMatches ?? this.suspensionMatches,
      yellowCards: yellowCards ?? this.yellowCards,
    );
  }

  /// Calculates overall rating based on core skills
  int calculateRating() {
    return ((shooting +
                passing +
                defending +
                dribbling +
                positioning +
                composure) /
            6)
        .round();
  }

  /// Calculates max experience for current level
  int get maxExperience => level * 100;

  /// Checks if player can level up
  bool canLevelUp() => experience >= maxExperience;
}

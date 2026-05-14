class YouthPlayerModel {
  final String id;
  final String name;
  final int age;
  final String position;
  final int potentialRating;
  final int currentRating;
  final DateTime scoutedAt;
  final bool isReadyForPromotion;
  final String? region;
  final String? flavorText;

  YouthPlayerModel({
    required this.id,
    required this.name,
    required this.age,
    required this.position,
    required this.potentialRating,
    required this.currentRating,
    required this.scoutedAt,
    this.isReadyForPromotion = false,
    this.region,
    this.flavorText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'position': position,
      'potentialRating': potentialRating,
      'currentRating': currentRating,
      'scoutedAt': scoutedAt.toIso8601String(),
      'isReadyForPromotion': isReadyForPromotion,
      if (region != null) 'region': region,
      if (flavorText != null) 'flavorText': flavorText,
    };
  }

  factory YouthPlayerModel.fromMap(String id, Map<String, dynamic> map) {
    return YouthPlayerModel(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 16,
      position: map['position'] ?? 'MID',
      potentialRating: map['potentialRating'] ?? 80,
      currentRating: map['currentRating'] ?? 40,
      scoutedAt: DateTime.parse(map['scoutedAt']),
      isReadyForPromotion: map['isReadyForPromotion'] ?? false,
      region: map['region'],
      flavorText: map['flavorText'],
    );
  }

  YouthPlayerModel copyWith({
    int? currentRating,
    bool? isReadyForPromotion,
    String? region,
    String? flavorText,
  }) {
    return YouthPlayerModel(
      id: id,
      name: name,
      age: age,
      position: position,
      potentialRating: potentialRating,
      currentRating: currentRating ?? this.currentRating,
      scoutedAt: scoutedAt,
      isReadyForPromotion: isReadyForPromotion ?? this.isReadyForPromotion,
      region: region ?? this.region,
      flavorText: flavorText ?? this.flavorText,
    );
  }
}

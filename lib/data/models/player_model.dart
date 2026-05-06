class PlayerModel {
  final String id;
  final String name;
  final String position;
  final int number;
  final int rating;
  final bool active;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.position,
    required this.number,
    required this.rating,
    required this.active,
  });

  factory PlayerModel.fromMap(String id, Map<String, dynamic> map) {
    return PlayerModel(
      id: id,
      name: map['name'] ?? '',
      position: map['position'] ?? 'MID',
      number: map['number'] ?? 0,
      rating: map['rating'] ?? 70,
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'number': number,
      'rating': rating,
      'active': active,
    };
  }
}

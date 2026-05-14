class LegendModel {
  final String id;
  final String name;
  final String role; // e.g., 'Efsane Forvet'
  final int rating;
  final String imageUrl;
  final String story;
  final bool isUnlocked;

  LegendModel({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.imageUrl,
    required this.story,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'rating': rating,
      'imageUrl': imageUrl,
      'story': story,
      'isUnlocked': isUnlocked,
    };
  }

  factory LegendModel.fromMap(String id, Map<String, dynamic> map) {
    return LegendModel(
      id: id,
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      rating: map['rating'] ?? 90,
      imageUrl: map['imageUrl'] ?? '',
      story: map['story'] ?? '',
      isUnlocked: map['isUnlocked'] ?? false,
    );
  }
}

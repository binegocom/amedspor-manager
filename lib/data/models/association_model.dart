class AssociationModel {
  final String id;
  final String name;
  final String leaderId;
  final List<String> memberIds;
  final int level;
  final int totalXp;
  final String description;

  AssociationModel({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.memberIds,
    this.level = 1,
    this.totalXp = 0,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'level': level,
      'totalXp': totalXp,
      'description': description,
    };
  }

  factory AssociationModel.fromMap(String id, Map<String, dynamic> map) {
    return AssociationModel(
      id: id,
      name: map['name'] ?? '',
      leaderId: map['leaderId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      level: map['level'] ?? 1,
      totalXp: map['totalXp'] ?? 0,
      description: map['description'] ?? '',
    );
  }
}

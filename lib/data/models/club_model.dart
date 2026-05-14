import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  final String id;
  final String name;
  final String managerName;
  final int tokens;
  final int cash;
  final int fans;
  final int reputation;
  
  // Facilities
  final int stadiumLevel;
  final int trainingLevel;
  final int medicalLevel;
  final int youthAcademyLevel;
  
  // Construction Fields
  final String? activeConstructionType; // 'stadium', 'training', 'medical'
  final int? activeConstructionTargetLevel;
  final DateTime? constructionEndsAt;

  // Timestamps
  final DateTime createdAt;
  final DateTime lastResourceUpdate;

  const ClubModel({
    required this.id,
    required this.name,
    required this.managerName,
    this.tokens = 5,
    this.cash = 10000,
    this.fans = 100,
    this.reputation = 1,
    this.stadiumLevel = 1,
    this.trainingLevel = 1,
    this.medicalLevel = 1,
    this.youthAcademyLevel = 1,
    this.activeConstructionType,
    this.activeConstructionTargetLevel,
    this.constructionEndsAt,
    required this.createdAt,
    required this.lastResourceUpdate,
  });

  factory ClubModel.fromMap(String id, Map<String, dynamic> map) {
    return ClubModel(
      id: id,
      name: map['name'] ?? 'Amedspor FC',
      managerName: map['managerName'] ?? 'Menajer',
      tokens: map['tokens'] ?? 5,
      cash: map['cash'] ?? 10000,
      fans: map['fans'] ?? 100,
      reputation: map['reputation'] ?? 1,
      stadiumLevel: map['stadiumLevel'] ?? 1,
      trainingLevel: map['trainingLevel'] ?? 1,
      medicalLevel: map['medicalLevel'] ?? 1,
      youthAcademyLevel: map['youthAcademyLevel'] ?? 1,
      activeConstructionType: map['activeConstructionType'] as String?,
      activeConstructionTargetLevel: map['activeConstructionTargetLevel'] as int?,
      constructionEndsAt: (map['constructionEndsAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastResourceUpdate: (map['lastResourceUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'managerName': managerName,
      'tokens': tokens,
      'cash': cash,
      'fans': fans,
      'reputation': reputation,
      'stadiumLevel': stadiumLevel,
      'trainingLevel': trainingLevel,
      'medicalLevel': medicalLevel,
      'youthAcademyLevel': youthAcademyLevel,
      'activeConstructionType': activeConstructionType,
      'activeConstructionTargetLevel': activeConstructionTargetLevel,
      'constructionEndsAt': constructionEndsAt != null ? Timestamp.fromDate(constructionEndsAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastResourceUpdate': Timestamp.fromDate(lastResourceUpdate),
    };
  }

  ClubModel copyWith({
    String? name,
    String? managerName,
    int? tokens,
    int? cash,
    int? fans,
    int? reputation,
    int? stadiumLevel,
    int? trainingLevel,
    int? medicalLevel,
    int? youthAcademyLevel,
    String? activeConstructionType,
    int? activeConstructionTargetLevel,
    DateTime? constructionEndsAt,
    bool clearConstruction = false,
    DateTime? lastResourceUpdate,
  }) {
    return ClubModel(
      id: id,
      name: name ?? this.name,
      managerName: managerName ?? this.managerName,
      tokens: tokens ?? this.tokens,
      cash: cash ?? this.cash,
      fans: fans ?? this.fans,
      reputation: reputation ?? this.reputation,
      stadiumLevel: stadiumLevel ?? this.stadiumLevel,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      medicalLevel: medicalLevel ?? this.medicalLevel,
      youthAcademyLevel: youthAcademyLevel ?? this.youthAcademyLevel,
      activeConstructionType: clearConstruction ? null : (activeConstructionType ?? this.activeConstructionType),
      activeConstructionTargetLevel: clearConstruction ? null : (activeConstructionTargetLevel ?? this.activeConstructionTargetLevel),
      constructionEndsAt: clearConstruction ? null : (constructionEndsAt ?? this.constructionEndsAt),
      createdAt: createdAt,
      lastResourceUpdate: lastResourceUpdate ?? this.lastResourceUpdate,
    );
  }
}

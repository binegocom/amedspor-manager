class YouthAcademyModel {
  final String clubId;
  final int level;
  final int scoutCount;
  final DateTime? lastScoutTime;
  final int academyCapacity;

  YouthAcademyModel({
    required this.clubId,
    this.level = 1,
    this.scoutCount = 1,
    this.lastScoutTime,
    this.academyCapacity = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'level': level,
      'scoutCount': scoutCount,
      'lastScoutTime': lastScoutTime?.toIso8601String(),
      'academyCapacity': academyCapacity,
    };
  }

  factory YouthAcademyModel.fromMap(Map<String, dynamic> map) {
    return YouthAcademyModel(
      clubId: map['clubId'] ?? '',
      level: map['level'] ?? 1,
      scoutCount: map['scoutCount'] ?? 1,
      lastScoutTime: map['lastScoutTime'] != null ? DateTime.parse(map['lastScoutTime']) : null,
      academyCapacity: map['academyCapacity'] ?? 5,
    );
  }

  YouthAcademyModel copyWith({
    int? level,
    int? scoutCount,
    DateTime? lastScoutTime,
    int? academyCapacity,
  }) {
    return YouthAcademyModel(
      clubId: clubId,
      level: level ?? this.level,
      scoutCount: scoutCount ?? this.scoutCount,
      lastScoutTime: lastScoutTime ?? this.lastScoutTime,
      academyCapacity: academyCapacity ?? this.academyCapacity,
    );
  }
}

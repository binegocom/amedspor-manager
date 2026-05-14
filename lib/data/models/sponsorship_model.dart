class SponsorshipModel {
  final String id;
  final String name;
  final String logoUrl;
  final int weeklyPayment;
  final int bonusPerWin;
  final int durationWeeks;
  final DateTime signedAt;

  SponsorshipModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.weeklyPayment,
    required this.bonusPerWin,
    required this.durationWeeks,
    required this.signedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'weeklyPayment': weeklyPayment,
      'bonusPerWin': bonusPerWin,
      'durationWeeks': durationWeeks,
      'signedAt': signedAt.toIso8601String(),
    };
  }

  factory SponsorshipModel.fromMap(String id, Map<String, dynamic> map) {
    return SponsorshipModel(
      id: id,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      weeklyPayment: map['weeklyPayment'] ?? 0,
      bonusPerWin: map['bonusPerWin'] ?? 0,
      durationWeeks: map['durationWeeks'] ?? 1,
      signedAt: DateTime.parse(map['signedAt']),
    );
  }
}

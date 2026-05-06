import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final DateTime matchDate;
  final String status;
  final int homeScore;
  final int awayScore;
  final int minute;
  final List<String> motmCandidates;
  final bool isMotmVotingActive;
  final Map<String, int> motmResults;

  bool get isLive => status == 'live' || status == 'halftime';
  bool get isFinished => status == 'finished';

  const MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.matchDate,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.minute,
    this.motmCandidates = const [],
    this.isMotmVotingActive = false,
    this.motmResults = const {},
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return MatchModel.fromMap(doc.id, map);
  }

  factory MatchModel.fromMap(String id, Map<String, dynamic> map) {
    return MatchModel(
      id: id,
      homeTeam: map['homeTeam'] ?? '',
      awayTeam: map['awayTeam'] ?? '',
      homeLogo: map['homeLogo'] ?? '',
      awayLogo: map['awayLogo'] ?? '',
      matchDate: _parseDate(map['matchDate']),
      status: map['status'] ?? 'upcoming',
      homeScore: map['homeScore'] ?? 0,
      awayScore: map['awayScore'] ?? 0,
      minute: map['minute'] ?? 0,
      motmCandidates: List<String>.from(map['motmCandidates'] ?? []),
      isMotmVotingActive: map['isMotmVotingActive'] ?? false,
      motmResults: Map<String, int>.from(map['motmResults'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeLogo': homeLogo,
      'awayLogo': awayLogo,
      'matchDate': matchDate.toIso8601String(),
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'minute': minute,
      'motmCandidates': motmCandidates,
      'isMotmVotingActive': isMotmVotingActive,
      'motmResults': motmResults,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }
}

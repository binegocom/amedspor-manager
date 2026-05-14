import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardModel {
  final String userId;
  final String username;
  final int eloScore;
  final int leagueLevel; // 1: Süper Lig, 2: 1. Lig, 3: Akademi Kümesi
  final int wins;
  final int losses;
  final int draws;
  final int goalDifference;
  final DateTime updatedAt;

  const LeaderboardModel({
    required this.userId,
    required this.username,
    this.eloScore = 1000,
    this.leagueLevel = 3,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.goalDifference = 0,
    required this.updatedAt,
  });

  factory LeaderboardModel.fromMap(Map<String, dynamic> map, String id) {
    return LeaderboardModel(
      userId: id,
      username: map['username'] ?? 'Menajer',
      eloScore: map['eloScore'] ?? 1000,
      leagueLevel: map['leagueLevel'] ?? 3,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      draws: map['draws'] ?? 0,
      goalDifference: map['goalDifference'] ?? 0,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'eloScore': eloScore,
      'leagueLevel': leagueLevel,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'goalDifference': goalDifference,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  static int calculateNewElo(int currentElo, int opponentElo, double result) {
    const double kFactor = 32.0;
    final double expectedScore = 1.0 / (1.0 + pow(10, (opponentElo - currentElo) / 400.0));
    final double newElo = currentElo + kFactor * (result - expectedScore);
    return newElo.round();
  }

  String get leagueName {
    switch (leagueLevel) {
      case 1:
        return 'Süper Lig';
      case 2:
        return '1. Lig';
      case 3:
      default:
        return 'Akademi Kümesi';
    }
  }
}

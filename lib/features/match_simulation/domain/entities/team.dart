import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../data/models/lineup_model.dart';
import '../enums/player_role.dart';
import '../models/tactical_preset.dart';
import '../enums/boost_type.dart';
import 'player.dart';

/// Bir futbol takımını temsil eder.
///
/// [attackDirection] +1 ise sağa hücum eder, -1 ise sola hücum eder.
class SimTeam {
  final int id;
  final String name;
  final Color color;
  final int attackDirection; // +1: sağa hücum, -1: sola hücum
  final List<SimPlayer> players;
  int score;

  // ---- TAKTİK AYARLARI ----
  String formation; // 4-4-2, 4-3-3, 3-5-2
  TacticalPreset tacticalPreset;
  double attackBalance; // 0.0 (tam defans) - 1.0 (tam hücum)
  double pressIntensity; // 0.0 - 1.0 (pres yoğunluğu)
  double gameWidth; // 0.0 (dar) - 1.0 (geniş)

  // ---- MAÇ İSTATİSTİKLERİ ----
  int totalShots;
  int shotsOnTarget;
  int successfulPasses;
  int failedPasses;
  int foulsCommitted;
  int foulsReceived;
  int yellowCards;
  int redCards;
  int corners;
  int tacklesWon;
  int saves;
  double expectedGoals;

  // Topa sahip olma (yüzde * 100)
  double ballPossession; // 0.0 - 1.0
  double possessionTime; // topa sahip olunan süre (saniye)

  // Koşu mesafesi (km)
  double totalDistanceRun;

  // Oyuncu değişikliği hakkı
  int substitutionsLeft;

  // Yedek oyuncular (henüz kullanılmıyor)
  List<SimPlayer> substitutes;

  // ---- CANLI BOOSTLAR ----
  final Map<BoostType, double> activeBoosts = {};

  SimTeam({
    required this.id,
    required this.name,
    required this.color,
    required this.attackDirection,
    required this.players,
    this.score = 0,
    this.formation = '4-4-2',
    this.tacticalPreset = TacticalPreset.balanced,
    this.attackBalance = 0.5,
    this.pressIntensity = 0.5,
    this.gameWidth = 0.5,
    this.totalShots = 0,
    this.shotsOnTarget = 0,
    this.successfulPasses = 0,
    this.failedPasses = 0,
    this.foulsCommitted = 0,
    this.foulsReceived = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.corners = 0,
    this.tacklesWon = 0,
    this.saves = 0,
    this.expectedGoals = 0.0,
    this.ballPossession = 0.0,
    this.possessionTime = 0.0,
    this.totalDistanceRun = 0.0,
    this.substitutionsLeft = 3,
    this.substitutes = const [],
  });

  /// Rakip kale merkezi X koordinatı.
  double get opponentGoalX => attackDirection == 1 ? 105.0 : 0.0;

  /// Kendi kale merkezi X koordinatı.
  double get ownGoalX => attackDirection == 1 ? 0.0 : 105.0;

  /// Tüm oyuncuları home pozisyonuna resetle.
  void resetAllToHome() {
    for (final p in players) {
      p.resetToHome();
    }
  }

  /// Pas yüzdesi.
  double get passAccuracy {
    final total = successfulPasses + failedPasses;
    if (total == 0) return 0;
    return successfulPasses / total;
  }

  int get passAttempts => successfulPasses + failedPasses;

  void applyTacticalPreset(TacticalPreset preset) {
    tacticalPreset = preset;
    switch (preset) {
      case TacticalPreset.defensive:
        attackBalance = 0.28;
        pressIntensity = 0.40;
        gameWidth = 0.42;
      case TacticalPreset.balanced:
        attackBalance = 0.52;
        pressIntensity = 0.55;
        gameWidth = 0.55;
      case TacticalPreset.attacking:
        attackBalance = 0.78;
        pressIntensity = 0.72;
        gameWidth = 0.68;
    }
  }

  /// Oyuncuları rollerine ve formasyona göre konumlandır.
  /// [formation] örn: "4-4-2", "4-3-3", "3-5-2", "4-2-3-1", "4-1-2-1-2"
  void applyFormation(String formation) {
    this.formation = formation;
    final bool isHome = id == 0;
    double px(double x) => isHome ? x : 105.0 - x;

    // Formasyonu çöz
    final parts = formation.split('-');
    int defCount = 4;
    int midCount = 4;
    int fwdCount = 2;

    if (parts.length == 3) {
      defCount = int.tryParse(parts[0]) ?? 4;
      midCount = int.tryParse(parts[1]) ?? 4;
      fwdCount = int.tryParse(parts[2]) ?? 2;
    } else if (parts.length == 4) {
      // e.g. 4-2-3-1
      defCount = int.tryParse(parts[0]) ?? 4;
      midCount = (int.tryParse(parts[1]) ?? 2) + (int.tryParse(parts[2]) ?? 3);
      fwdCount = int.tryParse(parts[3]) ?? 1;
    } else if (parts.length == 5) {
      // e.g. 4-1-2-1-2
      defCount = int.tryParse(parts[0]) ?? 4;
      midCount = (int.tryParse(parts[1]) ?? 1) +
          (int.tryParse(parts[2]) ?? 2) +
          (int.tryParse(parts[3]) ?? 1);
      fwdCount = int.tryParse(parts[4]) ?? 2;
    }

    int defIdx = 0, midIdx = 0, fwdIdx = 0;
    final defY = _distributeY(defCount);
    final midY = _distributeY(midCount);
    final fwdY = _distributeY(fwdCount);

    for (final p in players) {
      switch (p.role) {
        case PlayerRole.gk:
          p.homeX = px(5.0);
          p.homeY = 34.0;
        case PlayerRole.def:
          if (defIdx < defCount) {
            p.homeX = px(20.0);
            p.homeY = defY[defIdx];
            defIdx++;
          } else {
            p.homeX = px(20.0);
            p.homeY = 34.0;
          }
        case PlayerRole.mid:
          if (midIdx < midCount) {
            p.homeX = px(42.0);
            p.homeY = midY[midIdx];
            midIdx++;
          } else {
            p.homeX = px(42.0);
            p.homeY = 34.0;
          }
        case PlayerRole.fwd:
          if (fwdIdx < fwdCount) {
            p.homeX = px(62.0);
            p.homeY = fwdY[fwdIdx];
            fwdIdx++;
          } else {
            p.homeX = px(62.0);
            p.homeY = 34.0;
          }
      }
    }
  }

  /// Belirtilen sayıda oyuncu için Y pozisyonlarını eşit dağıt.
  List<double> _distributeY(int count) {
    if (count <= 1) return [34.0];
    final step = 50.0 / (count + 1);
    return List.generate(count, (i) => 9.0 + step * (i + 1));
  }

  /// Tüm istatistikleri sıfırla.
  void resetStats() {
    score = 0;
    totalShots = 0;
    shotsOnTarget = 0;
    successfulPasses = 0;
    failedPasses = 0;
    foulsCommitted = 0;
    foulsReceived = 0;
    yellowCards = 0;
    redCards = 0;
    corners = 0;
    tacklesWon = 0;
    saves = 0;
    expectedGoals = 0.0;
    ballPossession = 0.0;
    possessionTime = 0.0;
    totalDistanceRun = 0.0;
    substitutionsLeft = 3;
    resetAllToHome();
  }

  /// 4-4-2 diziliminde varsayılan takım oluşturma factory.
  factory SimTeam.createDefault({
    required int teamId,
    required String name,
    required Color color,
    Random? rng,
  }) {
    final int atkDir = teamId == 0 ? 1 : -1;
    final List<SimPlayer> players = [];

    final bool isHome = teamId == 0;

    double px(double x) => isHome ? x : 105.0 - x;

    // GK
    players.add(
      SimPlayer.createWithRole(
        id: teamId * 100 + 1,
        teamId: teamId,
        name: '$name GK',
        number: 1,
        role: PlayerRole.gk,
        homeX: px(5.0),
        homeY: 34.0,
        rng: rng,
      ),
    );

    // DEF (4)
    const defY = [12.0, 27.0, 41.0, 56.0];
    for (int i = 0; i < 4; i++) {
      players.add(
        SimPlayer.createWithRole(
          id: teamId * 100 + 2 + i,
          teamId: teamId,
          name: '$name DEF${i + 1}',
          number: 2 + i,
          role: PlayerRole.def,
          homeX: px(20.0),
          homeY: defY[i],
          rng: rng,
        ),
      );
    }

    // MID (4)
    const midY = [12.0, 27.0, 41.0, 56.0];
    for (int i = 0; i < 4; i++) {
      players.add(
        SimPlayer.createWithRole(
          id: teamId * 100 + 6 + i,
          teamId: teamId,
          name: '$name MID${i + 1}',
          number: 6 + i,
          role: PlayerRole.mid,
          homeX: px(42.0),
          homeY: midY[i],
          rng: rng,
        ),
      );
    }

    // FWD (2)
    const fwdY = [24.0, 44.0];
    for (int i = 0; i < 2; i++) {
      players.add(
        SimPlayer.createWithRole(
          id: teamId * 100 + 10 + i,
          teamId: teamId,
          name: '$name FWD${i + 1}',
          number: 10 + i,
          role: PlayerRole.fwd,
          homeX: px(62.0),
          homeY: fwdY[i],
          rng: rng,
        ),
      );
    }

    return SimTeam(
      id: teamId,
      name: name,
      color: color,
      attackDirection: atkDir,
      players: players,
    );
  }

  /// Kaydedilmiş LineupModel üzerinden simülasyon takımı oluşturma factory.
  factory SimTeam.createFromLineup({
    required int teamId,
    required LineupModel lineup,
    required String defaultName,
    required Color color,
    Random? rng,
  }) {
    final int atkDir = teamId == 0 ? 1 : -1;
    final List<SimPlayer> players = [];
    final bool isHome = teamId == 0;
    double px(double x) => isHome ? x : 105.0 - x;

    PlayerRole parseRole(String? pos) {
      switch (pos?.toUpperCase()) {
        case 'GK':
          return PlayerRole.gk;
        case 'DEF':
          return PlayerRole.def;
        case 'MID':
          return PlayerRole.mid;
        case 'FWD':
          return PlayerRole.fwd;
        default:
          return PlayerRole.mid;
      }
    }

    final rawPlayers = lineup.players;
    final defaultRoles = [
      PlayerRole.gk,
      PlayerRole.def,
      PlayerRole.def,
      PlayerRole.def,
      PlayerRole.def,
      PlayerRole.mid,
      PlayerRole.mid,
      PlayerRole.mid,
      PlayerRole.mid,
      PlayerRole.fwd,
      PlayerRole.fwd,
    ];

    for (int i = 0; i < 11; i++) {
      Map<String, dynamic>? p;
      if (i < rawPlayers.length) {
        p = rawPlayers[i];
      }
      final role = p != null
          ? parseRole(p['position'] as String?)
          : defaultRoles[i];
      final name = p?['name']?.toString().isNotEmpty == true
          ? p!['name'].toString()
          : '$defaultName Oyuncu ${i + 1}';
      final number = (p?['number'] as int?) ?? (i + 1);

      double homeX = 50.0;
      double homeY = 34.0;
      if (role == PlayerRole.gk) {
        homeX = px(5.0);
      } else if (role == PlayerRole.def) {
        homeX = px(20.0);
      } else if (role == PlayerRole.mid) {
        homeX = px(42.0);
      } else if (role == PlayerRole.fwd) {
        homeX = px(62.0);
      }

      final simPlayer = SimPlayer.createWithRole(
        id: teamId * 100 + i + 1,
        originalPlayerId: p?['id'] as String?,
        teamId: teamId,
        name: name,
        number: number,
        role: role,
        homeX: homeX,
        homeY: homeY,
        rng: rng,
      );

      final customRating = (p?['rating'] as num?)?.toDouble();
      if (customRating != null && customRating > 0) {
        double adjust(double val) =>
            ((val + customRating) / 2.0).clamp(10.0, 99.0);
        simPlayer.shooting = adjust(simPlayer.shooting);
        simPlayer.passing = adjust(simPlayer.passing);
        simPlayer.defending = adjust(simPlayer.defending);
        simPlayer.dribbling = adjust(simPlayer.dribbling);
        simPlayer.vision = adjust(simPlayer.vision);
        simPlayer.positioning = adjust(simPlayer.positioning);
      }

      players.add(simPlayer);
    }

    final List<SimPlayer> parsedSubstitutes = [];
    final rawSubs = lineup.substitutes;
    for (int i = 0; i < rawSubs.length; i++) {
      final p = rawSubs[i];
      final role = parseRole(p['position'] as String?);
      final name = p['name']?.toString().isNotEmpty == true
          ? p['name'].toString()
          : '$defaultName Yedek ${i + 1}';
      final number = (p['number'] as int?) ?? (20 + i);

      final simPlayer = SimPlayer.createWithRole(
        id: teamId * 100 + 20 + i,
        originalPlayerId: p['id'] as String?,
        teamId: teamId,
        name: name,
        number: number,
        role: role,
        homeX: 0,
        homeY: 0,
        rng: rng,
      );

      final customRating = (p['rating'] as num?)?.toDouble();
      if (customRating != null && customRating > 0) {
        double adjust(double val) =>
            ((val + customRating) / 2.0).clamp(10.0, 99.0);
        simPlayer.shooting = adjust(simPlayer.shooting);
        simPlayer.passing = adjust(simPlayer.passing);
        simPlayer.defending = adjust(simPlayer.defending);
        simPlayer.dribbling = adjust(simPlayer.dribbling);
        simPlayer.vision = adjust(simPlayer.vision);
        simPlayer.positioning = adjust(simPlayer.positioning);
      }
      parsedSubstitutes.add(simPlayer);
    }

    final team = SimTeam(
      id: teamId,
      name: defaultName,
      color: color,
      attackDirection: atkDir,
      players: players,
      substitutes: parsedSubstitutes,
    );

    team.applyFormation(lineup.formation);
    return team;
  }
}

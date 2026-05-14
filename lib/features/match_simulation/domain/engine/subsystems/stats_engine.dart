import 'dart:math';
import '../../entities/ball.dart';
import '../../entities/player.dart';
import '../../entities/team.dart';
import '../../enums/boost_type.dart';
import '../../enums/shot_result.dart';
import '../../enums/player_role.dart';
import '../match_state.dart';

class StatsEngine {
  final Random rng;

  StatsEngine({required this.rng});

  double calculateShotXg({
    required SimPlayer shooter,
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required double homeAdvantage,
    required double weatherSpeedMultiplier,
    required double fieldCondition,
    BoostType? activeBoost,
  }) {
    final goalX = shooter.teamId == homeTeam.id
        ? homeTeam.opponentGoalX
        : awayTeam.opponentGoalX;
    final shotDist = ball.distanceTo(goalX, 34.0);
    final targetError = (ball.targetY - 34.0).abs();
    final distanceScore = (1.0 - shotDist / 45.0).clamp(0.0, 1.0);
    final angleScore = (1.0 - targetError / 8.0).clamp(0.0, 1.0);
    final playerScore =
        (shooter.shooting * 0.45 +
            shooter.composure * 0.30 +
            shooter.positioning * 0.25) /
        100.0;

    double xg =
        0.04 +
        distanceScore * 0.38 +
        angleScore * 0.18 +
        playerScore * 0.18 +
        homeAdvantage * (shooter.teamId == homeTeam.id ? 0.5 : 0.0);

    double boostMult = 1.0;
    if (activeBoost != null) {
      switch (activeBoost) {
        case BoostType.mesale:
          boostMult = 1.15;
          break;
        case BoostType.baski:
          boostMult = 1.10;
          break;
        case BoostType.defans:
          boostMult = 1.0;
          break;
      }
    }

    return (xg * weatherSpeedMultiplier * fieldCondition * boostMult).clamp(
      0.03,
      0.95,
    );
  }

  void recordShotOnTarget(SimTeam shootingTeam, SimPlayer shooter) {
    shootingTeam.shotsOnTarget++;
    shooter.shotsOnTarget++;
  }

  ShotResult calculateShotResult({
    required Ball ball,
    required SimPlayer goalkeeper,
    required bool isHomeShot,
    required double weatherSpeedMultiplier,
  }) {
    // Şut mesafesi
    final shotDist = isHomeShot
        ? ball.distanceTo(105.0, ball.y)
        : ball.distanceTo(0.0, ball.y);

    // Şutçüyü bul
    final shooter = ball.shotBy;
    final shootPower = shooter?.shooting ?? 50;

    // Topun kale merkezine yakınlığı
    final yDiffFromCenter = (ball.y - 34.0).abs();

    // Kalecinin topa mesafesi
    final gkDist = goalkeeper.distanceTo(ball.x, ball.y);

    // Kalecinin yeteneği
    final gkAbility = goalkeeper.defending;

    // Temel gol ihtimali
    double goalProb = ball.shotXg > 0 ? ball.shotXg : 0.35;

    // Şut gücüne göre artış
    goalProb += (shootPower / 100.0) * 0.25;

    // Mesafeye göre azalma
    if (shotDist < 10.0) {
      goalProb += 0.20;
    } else if (shotDist < 18.0) {
      goalProb += 0.10;
    } else if (shotDist > 30.0) {
      goalProb -= 0.10;
    }

    // Kaleci uzaktaysa bonus
    if (gkDist > 8.0) goalProb += 0.15;
    if (gkDist > 12.0) goalProb += 0.10;

    // Top tam merkeze yakınsa bonus
    if (yDiffFromCenter < 2.0) goalProb += 0.10;

    // Kaleci yeteneğine göre azaltma
    goalProb -= (gkAbility / 100.0) * 0.20;

    // Kaleci çok yakınsa azalt
    if (gkDist < 4.0) goalProb -= 0.15;

    // Top kale dışına gidiyorsa azalt
    if (ball.y < 30.5 || ball.y > 37.5) goalProb -= 0.20;

    final roll = rng.nextDouble();
    if (roll < goalProb.clamp(0.05, 0.95)) {
      return ShotResult.goal;
    } else if (roll < goalProb + 0.05) {
      return ShotResult.post;
    } else {
      return ShotResult.saved;
    }
  }

  void updateBoostTimers({
    required double dt,
    required Map<int, Map<BoostType, double>> activeBoosts,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
  }) {
    for (var teamId in activeBoosts.keys) {
      final engineBoosts = activeBoosts[teamId]!;
      final team = teamId == 0 ? homeTeam : awayTeam;

      engineBoosts.forEach((type, timer) {
        if (timer > 0) {
          final newTimer = timer - dt;
          engineBoosts[type] = newTimer;
          team.activeBoosts[type] = newTimer;
        }
      });

      engineBoosts.removeWhere((type, timer) => timer <= 0);
      team.activeBoosts.removeWhere((type, timer) => timer <= 0);
    }
  }

  void updatePossession({
    required double realDt,
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required MatchState state,
  }) {
    if (ball.owner != null) {
      if (ball.owner!.teamId == homeTeam.id) {
        state.homePossessionTime += realDt;
        homeTeam.possessionTime += realDt;
      } else {
        state.awayPossessionTime += realDt;
        awayTeam.possessionTime += realDt;
      }
    }
    final total = state.homePossessionTime + state.awayPossessionTime;
    if (total > 0) {
      homeTeam.ballPossession = state.homePossessionTime / total;
      awayTeam.ballPossession = state.awayPossessionTime / total;
    }
  }

  void trackRunningDistances({
    required double dt,
    required List<SimPlayer> allPlayers,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
  }) {
    for (final p in allPlayers) {
      if (p.isAtTarget) continue;
      final dx = p.targetX - p.currentX;
      final dy = p.targetY - p.currentY;
      final dist = sqrt(dx * dx + dy * dy);
      final runAmount = dist * 0.001 * dt;
      p.totalDistanceRun += runAmount;

      // Stamina düşüşü: kaleciler çok daha yavaş yorulur
      final drainMult = p.role == PlayerRole.gk ? 0.01 : 0.08;
      p.stamina = (p.stamina - runAmount * drainMult).clamp(0.05, 1.0);
    }
    homeTeam.totalDistanceRun = homeTeam.players.fold(
      0.0,
      (sum, p) => sum + p.totalDistanceRun,
    );
    awayTeam.totalDistanceRun = awayTeam.players.fold(
      0.0,
      (sum, p) => sum + p.totalDistanceRun,
    );
  }
}

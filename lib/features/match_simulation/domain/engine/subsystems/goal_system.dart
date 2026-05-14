import 'dart:math';
import '../../entities/ball.dart';
import '../../entities/player.dart';
import '../../entities/team.dart';
import '../../enums/shot_result.dart';
import '../../enums/player_role.dart';
import '../../models/match_event.dart';
import '../match_state.dart';
import 'stats_engine.dart';

class GoalSystem {
  final Random rng;

  GoalSystem({required this.rng});

  void checkShotOnGoal({
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required MatchState state,
    required StatsEngine statsEngine,
    required double weatherSpeedMultiplier,
    required Function(SimTeam, SimPlayer, ShotResult) onResult,
  }) {
    if (!ball.isInFlight || !ball.isShot) return;

    // Sol kale
    if (ball.x <= 4.0 && ball.targetX <= 1.0) {
      final goalkeeper = homeTeam.players.firstWhere(
        (p) => p.role == PlayerRole.gk,
        orElse: () => homeTeam.players.first,
      );
      final shooter = ball.shotBy ?? awayTeam.players.first;
      final result = statsEngine.calculateShotResult(
        ball: ball,
        goalkeeper: goalkeeper,
        isHomeShot: false,
        weatherSpeedMultiplier: weatherSpeedMultiplier,
      );
      onResult(awayTeam, shooter, result);
    }
    // Sağ kale
    else if (ball.x >= 101.0 && ball.targetX >= 104.0) {
      final goalkeeper = awayTeam.players.firstWhere(
        (p) => p.role == PlayerRole.gk,
        orElse: () => awayTeam.players.first,
      );
      final shooter = ball.shotBy ?? homeTeam.players.first;
      final result = statsEngine.calculateShotResult(
        ball: ball,
        goalkeeper: goalkeeper,
        isHomeShot: true,
        weatherSpeedMultiplier: weatherSpeedMultiplier,
      );
      onResult(homeTeam, shooter, result);
    }
  }

  void recordNewShotIfNeeded({
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required MatchState state,
    required StatsEngine statsEngine,
    required double homeAdvantage,
    required double weatherSpeedMultiplier,
    required double fieldCondition,
    required int lastRecordedShotSequence,
    required Function(int) setLastRecordedShotSequence,
    required Function(MatchEvent) onAddEvent,
  }) {
    if (!ball.isShot ||
        !ball.isInFlight ||
        ball.shotBy == null ||
        ball.shotSequence == lastRecordedShotSequence) {
      return;
    }

    final shooter = ball.shotBy!;
    final shootingTeam = shooter.teamId == homeTeam.id ? homeTeam : awayTeam;
    final xg = statsEngine.calculateShotXg(
      shooter: shooter,
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeAdvantage: homeAdvantage,
      weatherSpeedMultiplier: weatherSpeedMultiplier,
      fieldCondition: fieldCondition,
      activeBoost: (shooter.teamId == homeTeam.id)
          ? state.homeBoost
          : state.awayBoost,
    );
    ball.shotXg = xg;
    setLastRecordedShotSequence(ball.shotSequence);

    shooter.shots++;
    shooter.expectedGoals += xg;
    shootingTeam.totalShots++;
    shootingTeam.expectedGoals += xg;

    onAddEvent(
      MatchEvent(
        minute: state.displayMinute,
        type: MatchEventType.shot,
        description: '${shooter.name} şut çekti (xG ${xg.toStringAsFixed(2)})',
        teamId: shootingTeam.id,
        playerId: shooter.id,
      ),
    );
  }
}

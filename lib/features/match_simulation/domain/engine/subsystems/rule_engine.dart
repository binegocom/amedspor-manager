import 'dart:math';

import '../../entities/ball.dart';
import '../../entities/player.dart';
import '../../entities/team.dart';
import '../../enums/match_phase.dart';
import '../../enums/player_role.dart';
import '../../models/match_event.dart';
import '../match_state.dart';

class RuleEngine {
  void updatePhase(
    MatchState state,
    Ball ball,
    SimTeam homeTeam,
    SimTeam awayTeam,
  ) {
    // Duran top fazlarını değiştirme
    if (state.phase == MatchPhase.foul ||
        state.phase == MatchPhase.freeKick ||
        state.phase == MatchPhase.corner ||
        state.phase == MatchPhase.throwIn ||
        state.phase == MatchPhase.offside ||
        state.phase == MatchPhase.penalty ||
        state.phase == MatchPhase.halftime ||
        state.phase == MatchPhase.goal) {
      return;
    }

    if (ball.isInFlight && ball.isShot) {
      state.phase = MatchPhase.shot;
      return;
    }

    if (ball.isInFlight) {
      state.phase = MatchPhase.transition;
      return;
    }

    if (ball.owner == null) {
      state.phase = MatchPhase.looseBall;
      return;
    }

    if (ball.owner!.teamId == homeTeam.id) {
      state.phase = MatchPhase.attacking;
    } else {
      state.phase = MatchPhase.defending;
    }
  }

  bool isPenaltyArea(double x, int attackingTeamId, int homeTeamId) {
    return (x < 18.0 && attackingTeamId != homeTeamId) ||
        (x > 87.0 && attackingTeamId == homeTeamId);
  }

  void handleThrowIn({
    required MatchState state,
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required int minute,
    required SimPlayer? Function(SimTeam) findNearest,
    required Function(MatchEvent) onAddEvent,
  }) {
    state.phase = MatchPhase.throwIn;
    state.foulPauseTimer = 1.0;

    final lastTouchTeamId =
        ball.owner?.teamId ?? ball.lastTouchedBy?.teamId ?? -1;
    final receivingTeam = lastTouchTeamId == homeTeam.id ? awayTeam : homeTeam;

    ball.x = ball.x.clamp(2.0, 103.0);
    ball.y = ball.y.clamp(2.0, 66.0);
    ball.isInFlight = false;
    ball.isShot = false;

    final nearest = findNearest(receivingTeam);
    if (nearest != null) ball.giveTo(nearest);

    onAddEvent(
      MatchEvent(
        minute: minute,
        type: MatchEventType.throwIn,
        description: '${receivingTeam.name} taç kullanacak.',
        teamId: receivingTeam.id,
      ),
    );
  }

  void executePenalty({
    required MatchState state,
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required int lastFoulReceivedTeamId,
    required int minute,
    required Random rng,
    required Function(MatchEvent) onAddEvent,
    required Function(int) setScoringTeamId,
  }) {
    final shootingTeam = lastFoulReceivedTeamId == homeTeam.id
        ? homeTeam
        : awayTeam;
    final goalkeepingTeam = lastFoulReceivedTeamId == homeTeam.id
        ? awayTeam
        : homeTeam;

    final shooter = shootingTeam.players.firstWhere(
      (p) => p.role == PlayerRole.fwd,
      orElse: () => shootingTeam.players.first,
    );
    final goalkeeper = goalkeepingTeam.players.firstWhere(
      (p) => p.role == PlayerRole.gk,
    );

    final goalChance =
        0.70 +
        (shooter.shooting / 100.0) * 0.15 -
        (goalkeeper.defending / 100.0) * 0.15;
    final isGoal = rng.nextDouble() < goalChance.clamp(0.2, 0.95);
    const penaltyXg = 0.76;

    shooter.shots++;
    shooter.shotsOnTarget++;
    shooter.expectedGoals += penaltyXg;
    shootingTeam.totalShots++;
    shootingTeam.shotsOnTarget++;
    shootingTeam.expectedGoals += penaltyXg;

    if (isGoal) {
      shootingTeam.score++;
      setScoringTeamId(shootingTeam.id);
      onAddEvent(
        MatchEvent(
          minute: minute,
          type: MatchEventType.goal,
          description: 'PENALTI GOLÜ! ${shooter.name} ağları buldu!',
          teamId: shootingTeam.id,
          playerId: shooter.id,
        ),
      );
    } else {
      goalkeepingTeam.saves++;
      onAddEvent(
        MatchEvent(
          minute: minute,
          type: MatchEventType.save,
          description: 'Penaltı kurtarıldı! ${goalkeeper.name}',
          teamId: goalkeepingTeam.id,
          playerId: goalkeeper.id,
        ),
      );
    }

    ball.resetToCenter();
    ball.giveTo(goalkeeper);
    state.phase = MatchPhase.kickoff;
  }

  void handleCornerOrGoalKick({
    required MatchState state,
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required SimTeam attackingTeam,
    required SimTeam defendingTeam,
    required int minute,
    required Function(MatchEvent) onAddEvent,
    required Function(int) setLastCornerTeamId,
  }) {
    final lastTouchTeamId =
        ball.owner?.teamId ?? ball.lastTouchedBy?.teamId ?? -1;

    if (lastTouchTeamId == defendingTeam.id) {
      attackingTeam.corners++;
      state.phase = MatchPhase.corner;
      state.foulPauseTimer = 1.5;
      setLastCornerTeamId(attackingTeam.id);

      ball.resetToCenter();
      final kicker = attackingTeam.players.firstWhere(
        (p) => p.role == PlayerRole.mid,
        orElse: () => attackingTeam.players.first,
      );
      ball.giveTo(kicker);

      onAddEvent(
        MatchEvent(
          minute: minute,
          type: MatchEventType.corner,
          description: '${attackingTeam.name} korner kullanacak.',
          teamId: attackingTeam.id,
        ),
      );
    } else {
      final gk = defendingTeam.players.firstWhere(
        (p) => p.role == PlayerRole.gk,
      );
      ball.resetToCenter();
      ball.giveTo(gk);

      onAddEvent(
        MatchEvent(
          minute: minute,
          type: MatchEventType.goalKick,
          description: 'Kale vuruşu.',
          teamId: defendingTeam.id,
        ),
      );
    }
  }
}

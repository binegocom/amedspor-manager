import 'dart:math';
import '../../entities/ball.dart';
import '../../entities/player.dart';
import '../../entities/team.dart';
import '../../enums/match_phase.dart';
import '../../enums/player_role.dart';
import '../../enums/boost_type.dart';
import '../../models/match_event.dart';
import '../match_state.dart';

class MatchLogicSystem {
  final Random rng;

  MatchLogicSystem({required this.rng});

  void performKickoff(SimTeam team, Ball ball, MatchState state) {
    ball.resetToCenter();
    final forwards = team.players
        .where((p) => p.role == PlayerRole.fwd)
        .toList();
    if (forwards.isNotEmpty) {
      final kicker = forwards.first;
      kicker.currentX = 52.5;
      kicker.currentY = 34.0;
      kicker.targetX = 52.5;
      kicker.targetY = 34.0;
      ball.giveTo(kicker);
    }
    state.phase = MatchPhase.kickoff;
  }

  SimPlayer? findNearestPlayerOnTeam(SimTeam team, Ball ball) {
    SimPlayer? closest;
    double minDist = 999.0;
    for (final p in team.players) {
      if (p.isInjured || p.redCard > 0) continue;
      final d = p.distanceTo(ball.x, ball.y);
      if (d < minDist) {
        minDist = d;
        closest = p;
      }
    }
    return closest;
  }

  void resetBallToNearestPlayerOnTeam(SimTeam team, Ball ball) {
    ball.x = ball.x.clamp(2.0, 103.0);
    ball.y = ball.y.clamp(2.0, 66.0);
    ball.isInFlight = false;
    ball.isShot = false;

    final nearest = findNearestPlayerOnTeam(team, ball);
    if (nearest != null) {
      ball.giveTo(nearest);
    }
  }

  void resetPositions(SimTeam homeTeam, SimTeam awayTeam) {
    homeTeam.resetAllToHome();
    awayTeam.resetAllToHome();
  }

  void triggerGoalPause({
    required MatchState state,
    required Ball ball,
    required SimTeam scoringTeam,
    required SimPlayer scorer,
    required Function() onPlayGoalSound,
    required Function(MatchEvent) onAddEvent,
  }) {
    state.phase = MatchPhase.goal;
    state.goalPauseTimer = 2.5;
    onPlayGoalSound();
    ball.resetToCenter();

    scorer.performanceRating = (scorer.performanceRating + 0.5).clamp(
      1.0,
      10.0,
    );
    onAddEvent(
      MatchEvent(
        minute: state.displayMinute,
        type: MatchEventType.goal,
        description: 'GOOOOOOL! ${scorer.name} (${scoringTeam.name})',
        teamId: scoringTeam.id,
        playerId: scorer.id,
      ),
    );
  }

  void applyTemporaryBoost({
    required int teamId,
    required BoostType type,
    required Map<int, Map<BoostType, double>> activeBoosts,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required int minute,
    required Function(MatchEvent) onAddEvent,
  }) {
    if (activeBoosts.containsKey(teamId)) {
      activeBoosts[teamId]![type] = 30.0;
    }

    final team = teamId == 0 ? homeTeam : awayTeam;
    team.activeBoosts[type] = 30.0;

    String desc = '';
    switch (type) {
      case BoostType.mesale:
        desc = 'Meşaleler yakıldı! Takım coştu!';
        break;
      case BoostType.baski:
        desc = 'Taraftar baskısı arttı!';
        break;
      case BoostType.defans:
        desc = 'Savunma hattı kuruldu!';
        break;
    }

    onAddEvent(
      MatchEvent(
        minute: minute,
        type: MatchEventType.boost,
        description: desc,
        teamId: teamId,
      ),
    );
  }

  void simulateToEnd({
    required MatchState state,
    required double fixedStepSeconds,
    required Function(double) step,
    required bool Function() isFinalWhistleBlown,
  }) {
    final previousScale = state.timeScale;
    state.timeScale = 20.0;
    var guard = 0;
    while (!state.isFinished && guard < 10000) {
      step(fixedStepSeconds);
      guard++;
    }
    if (state.isFinished && !isFinalWhistleBlown()) {
      step(0);
    }
    state.timeScale = previousScale;
  }

  void restart({
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required MatchState state,
    required Ball ball,
    required List<MatchEvent> matchEvents,
    required Function() onRandomizeWeather,
    required Function(SimTeam) onPerformKickoff,
    required Function(MatchEvent) onAddEvent,
    required Function(bool) setFinalWhistleBlown,
    required Function(double) setFixedAccumulator,
    required Function(int) setLastRecordedShotSequence,
    required Function(int) setLastScoringTeamId,
    required Function(int) setLastFoulReceivedTeamId,
    required Function(int?) setLastCornerTeamId,
  }) {
    homeTeam.resetStats();
    awayTeam.resetStats();
    state.reset();
    matchEvents.clear();
    setFinalWhistleBlown(false);
    setFixedAccumulator(0.0);
    setLastRecordedShotSequence(0);
    setLastScoringTeamId(0);
    setLastFoulReceivedTeamId(0);
    setLastCornerTeamId(null);
    ball.resetToCenter();
    onRandomizeWeather();
    onPerformKickoff(homeTeam);
    onAddEvent(
      MatchEvent(
        minute: 0,
        type: MatchEventType.kickoff,
        description: 'Maç başladı!',
        teamId: 0,
      ),
    );
  }
}

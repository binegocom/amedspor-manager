import 'dart:math';
import '../../entities/ball.dart';
import '../../entities/player.dart';
import '../../entities/team.dart';
import '../../models/match_event.dart';
import '../../enums/player_role.dart';

class MatchEventLogic {
  final Random rng;

  MatchEventLogic({required this.rng});

  void resolvePassPickup({
    required SimPlayer receiver,
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required int minute,
    required Function(MatchEvent) onAddEvent,
  }) {
    final passer = ball.passer;
    if (passer == null) return;

    final passingTeam = passer.teamId == homeTeam.id ? homeTeam : awayTeam;
    final isSuccess = receiver.teamId == passer.teamId;
    if (isSuccess) {
      passer.successfulPasses++;
      passingTeam.successfulPasses++;
      passer.performanceRating = (passer.performanceRating + 0.04).clamp(
        1.0,
        10.0,
      );
    } else {
      passer.failedPasses++;
      passingTeam.failedPasses++;
      receiver.tackles++;
      final receivingTeam = receiver.teamId == homeTeam.id
          ? homeTeam
          : awayTeam;
      receivingTeam.tacklesWon++;
      onAddEvent(
        MatchEvent(
          minute: minute,
          type: MatchEventType.tackle,
          description: '${receiver.name} pas arası yaptı.',
          teamId: receiver.teamId,
          playerId: receiver.id,
        ),
      );
    }
    passer.passAccuracy = passer.calculatedPassAccuracy;
    ball.clearPassContext();
  }

  void executeTackle({
    required SimPlayer tackler,
    required SimPlayer ballHolder,
    required Ball ball,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
  }) {
    final successChance = tackler.defending / 100.0;
    if (rng.nextDouble() < successChance) {
      ball.giveTo(tackler);
      tackler.tackles++;
      final tacklingTeam = tackler.teamId == homeTeam.id ? homeTeam : awayTeam;
      tacklingTeam.tacklesWon++;
      ballHolder.performanceRating = (ballHolder.performanceRating - 0.1).clamp(
        1.0,
        10.0,
      );
      tackler.performanceRating = (tackler.performanceRating + 0.15).clamp(
        1.0,
        10.0,
      );
    }
  }

  void checkOffside({
    required Ball ball,
    required List<SimPlayer> allPlayers,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required Function(SimPlayer) onOffside,
  }) {
    if (!ball.isInFlight || ball.isShot || ball.owner != null) return;

    if (ball.owner == null && ball.isInFlight && !ball.isShot) {
      SimPlayer? closestAttacker;
      double minDist = 999.0;

      for (final p in allPlayers) {
        if (p.isInjured) continue;
        final d = p.distanceTo(ball.targetX, ball.targetY);
        if (d < minDist) {
          minDist = d;
          closestAttacker = p;
        }
      }

      if (closestAttacker == null) return;

      final oppTeam = closestAttacker.teamId == homeTeam.id
          ? awayTeam
          : homeTeam;
      final double lastDefenderX = oppTeam.players
          .where((p) => p.role == PlayerRole.def || p.role == PlayerRole.gk)
          .map((p) => p.currentX)
          .fold(0.0, (max, x) => x > max ? x : max);

      if (closestAttacker.teamId == homeTeam.id) {
        if (closestAttacker.currentX > lastDefenderX &&
            closestAttacker.currentX > 52.5) {
          onOffside(closestAttacker);
        }
      } else {
        if (closestAttacker.currentX < lastDefenderX &&
            closestAttacker.currentX < 52.5) {
          onOffside(closestAttacker);
        }
      }
    }
  }

  void handleBallPickup({
    required Ball ball,
    required List<SimPlayer> allPlayers,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required int minute,
    required Random rng,
    required Function(SimPlayer) onResolvePassPickup,
    required Function(SimPlayer, SimPlayer) onExecuteTackle,
    required Function(SimPlayer, SimPlayer) onCommitFoul,
    required Function(MatchEvent) onAddEvent,
  }) {
    if (ball.isShot && ball.isInFlight) return;

    if (!ball.isInFlight && ball.owner == null) {
      SimPlayer? closest;
      double minDist = 999.0;
      for (final p in allPlayers) {
        if (p.isInjured || p.redCard > 0) continue;
        final d = p.distanceTo(ball.x, ball.y);
        if (d < minDist) {
          minDist = d;
          closest = p;
        }
      }
      if (closest != null && minDist < 2.5) {
        onResolvePassPickup(closest);
        ball.giveTo(closest);
      }
    }

    if (ball.owner != null && !ball.isInFlight) {
      final owner = ball.owner!;
      if (owner.isInjured || owner.redCard > 0) return;
      final oppTeam = owner.teamId == homeTeam.id ? awayTeam : homeTeam;

      for (final opp in oppTeam.players) {
        if (opp.role == PlayerRole.gk || opp.isInjured || opp.redCard > 0) {
          continue;
        }
        final dist = owner.distanceToPlayer(opp);
        if (dist < 2.0) {
          final roll = rng.nextDouble();
          final tackleChance = opp.defending / 200.0;
          final dribbleResist = owner.dribbling / 200.0;

          if (roll < tackleChance - dribbleResist + 0.01) {
            onExecuteTackle(owner, opp);
            break;
          }

          if (roll < 0.025) {
            ball.giveTo(opp);
            opp.tackles++;
            onAddEvent(
              MatchEvent(
                minute: minute,
                type: MatchEventType.tackle,
                description: '${opp.name} topu kaptı!',
                teamId: opp.teamId,
              ),
            );
            break;
          }

          if (roll > 0.97 && roll < 0.995) {
            onCommitFoul(opp, owner);
            break;
          }

          if (roll > 0.998) {
            onCommitFoul(opp, owner);
            owner.isInjured = true;
            onAddEvent(
              MatchEvent(
                minute: minute,
                type: MatchEventType.injury,
                description: '${owner.name} sakatlandı!',
                teamId: owner.teamId,
              ),
            );
            break;
          }
        }
      }
    }
  }

  void commitFoul({
    required SimPlayer fouler,
    required SimPlayer fouled,
    required SimTeam homeTeam,
    required SimTeam awayTeam,
    required int minute,
    required Random rng,
    required Function() onPlayWhistle,
    required Function(MatchEvent) onAddEvent,
    required Function(SimPlayer, bool) onTriggerFreeKick,
  }) {
    onPlayWhistle();
    fouler.fouls++;
    fouled.foulsReceived++;
    final foulingTeam = fouler.teamId == homeTeam.id ? homeTeam : awayTeam;
    final fouledTeam = fouled.teamId == homeTeam.id ? homeTeam : awayTeam;
    foulingTeam.foulsCommitted++;
    fouledTeam.foulsReceived++;
    fouler.performanceRating = (fouler.performanceRating - 0.2).clamp(
      1.0,
      10.0,
    );

    final isYellow = rng.nextDouble() < (fouler.aggression / 100.0 * 0.4);
    final isRed =
        rng.nextDouble() < (fouler.aggression / 100.0 * 0.05) ||
        (isYellow && fouler.yellowCards >= 1);

    if (isRed) {
      fouler.redCard = 1;
      foulingTeam.redCards++;
      onAddEvent(
        MatchEvent(
          minute: minute,
          type: MatchEventType.redCard,
          description: 'KIRMIZI KART! ${fouler.name} oyundan atıldı!',
          teamId: fouler.teamId,
        ),
      );
    } else if (isYellow) {
      fouler.yellowCards++;
      foulingTeam.yellowCards++;
      onAddEvent(
        MatchEvent(
          minute: minute,
          type: MatchEventType.yellowCard,
          description: 'Sarı kart: ${fouler.name}',
          teamId: fouler.teamId,
        ),
      );
    }
    onTriggerFreeKick(fouled, fouler.teamId == homeTeam.id);
  }
}

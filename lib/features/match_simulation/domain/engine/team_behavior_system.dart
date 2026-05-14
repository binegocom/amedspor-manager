import 'dart:math';
import '../entities/player.dart';
import '../entities/team.dart';
import '../entities/ball.dart';
import '../enums/player_role.dart';

/// Takım taktik davranış sistemi.
///
/// Topun durumuna göre (bizde / rakipte / boşta) tüm oyuncuların
/// hedef pozisyonlarını belirler.
class TeamBehaviorSystem {
  final Random _rng;

  TeamBehaviorSystem({Random? rng}) : _rng = rng ?? Random();

  static const double fieldWidth = 105.0;
  static const double fieldHeight = 68.0;

  /// Takım davranışını güncelle.
  ///
  /// [team] güncellenecek takım.
  /// [opponent] rakip takım.
  /// [ball] top.
  /// [dt] zaman ölçeklenmiş deltaTime.
  void update(SimTeam team, SimTeam opponent, Ball ball, double dt) {
    final bool weHaveBall = _teamHasBall(team, ball);
    final bool theyHaveBall = _teamHasBall(opponent, ball);
    final bool ballIsFree = ball.owner == null && !ball.isInFlight;

    if (weHaveBall) {
      _applyAttackingBehavior(team, ball);
    } else if (theyHaveBall) {
      _applyDefendingBehavior(team, opponent, ball);
    } else if (ballIsFree) {
      _applyLooseBallBehavior(team, ball);
    } else {
      // Top havada — pozisyonları koru
      _applyTransitionBehavior(team, ball);
    }
  }

  bool _teamHasBall(SimTeam team, Ball ball) {
    if (ball.owner == null) return false;
    return ball.owner!.teamId == team.id;
  }

  /// Hücum davranışı: takım rakip yarı sahaya doğru yayılır.
  void _applyAttackingBehavior(SimTeam team, Ball ball) {
    final int atkDir = team.attackDirection;

    for (final player in team.players) {
      if (player.hasBall) continue; // Toplu oyuncu kendi kararını verir

      double offsetX = 0;
      double offsetY = (_rng.nextDouble() - 0.5) * 4.0;
      final attackPush = 0.75 + team.attackBalance * 0.65;
      final widthBias =
          (player.homeY - fieldHeight / 2) * team.gameWidth * 0.18;

      switch (player.role) {
        case PlayerRole.gk:
          // Kaleci pozisyonunda kalır, hafif ileri çıkar
          player.targetX = player.homeX + atkDir * 3.0;
          player.targetY = player.homeY + offsetY * 0.3;
          continue;
        case PlayerRole.def:
          // Defans hafif ileri çıkar
          offsetX = atkDir * 10.0 * attackPush;
        case PlayerRole.mid:
          // Orta saha ileri destek verir
          offsetX = atkDir * 15.0 * attackPush;
        case PlayerRole.fwd:
          // Forvet maksimum ileri çıkar
          offsetX = atkDir * 18.0 * attackPush;
      }

      // Topun Y eksenine göre hafif kaydırma (destek hareketi)
      final ballInfluenceY = (ball.y - player.homeY) * 0.15;

      player.targetX = (player.homeX + offsetX).clamp(2.0, fieldWidth - 2.0);
      player.targetY = (player.homeY + offsetY + ballInfluenceY + widthBias)
          .clamp(2.0, fieldHeight - 2.0);
    }
  }

  /// Savunma davranışı: takım kendi yarı sahasına çekilir.
  void _applyDefendingBehavior(SimTeam team, SimTeam opponent, Ball ball) {
    // En yakın oyuncuyu baskıya gönder
    SimPlayer? pressurePlayer;
    double minDist = 999.0;

    for (final player in team.players) {
      if (player.role == PlayerRole.gk) continue;
      final d =
          player.distanceTo(ball.x, ball.y) -
          player.workRate * team.pressIntensity * 0.04;
      if (d < minDist) {
        minDist = d;
        pressurePlayer = player;
      }
    }

    for (final player in team.players) {
      if (player == pressurePlayer) {
        // Bu oyuncu topa baskı yapar
        player.targetX =
            ball.x - team.attackDirection * (1.5 - team.pressIntensity);
        player.targetY = ball.y;
        continue;
      }

      final int atkDir = team.attackDirection;
      double offsetX = 0;

      switch (player.role) {
        case PlayerRole.gk:
          // Kaleci kale önünde
          player.targetX = player.homeX;
          player.targetY = 34.0 + (ball.y - 34.0) * 0.2; // Topa göre hafif kayma
          continue;
        case PlayerRole.def:
          // Defans geri çekilir
          offsetX = -atkDir * (7.0 - team.pressIntensity * 4.0);
        case PlayerRole.mid:
          // Orta saha geri gelir
          offsetX = -atkDir * (10.0 - team.pressIntensity * 5.0);
        case PlayerRole.fwd:
          // Forvet bile biraz geri döner
          offsetX = -atkDir * (13.0 - team.pressIntensity * 6.0);
      }

      // Topun Y'sine göre kompaktlık
      final compactY = (ball.y - player.homeY) * (0.32 - team.gameWidth * 0.12);

      player.targetX = (player.homeX + offsetX).clamp(2.0, fieldWidth - 2.0);
      player.targetY = (player.homeY + compactY).clamp(2.0, fieldHeight - 2.0);
    }
  }

  /// Boş top davranışı: en yakın oyuncu topa koşar, diğerleri destek pozisyonu alır.
  void _applyLooseBallBehavior(SimTeam team, Ball ball) {
    SimPlayer? chaser;
    double minDist = 999.0;

    for (final player in team.players) {
      if (player.role == PlayerRole.gk) continue;
      final d = player.distanceTo(ball.x, ball.y) - player.workRate * 0.025;
      if (d < minDist) {
        minDist = d;
        chaser = player;
      }
    }

    for (final player in team.players) {
      if (player == chaser) {
        player.targetX = ball.x;
        player.targetY = ball.y;
      } else {
        // Diğerleri home pozisyonuna yakın kal
        player.targetX = player.homeX;
        player.targetY = player.homeY;
      }
    }
  }

  /// Geçiş davranışı: oyuncular hafifçe pozisyona döner.
  void _applyTransitionBehavior(SimTeam team, Ball ball) {
    for (final player in team.players) {
      if (player.role == PlayerRole.gk) {
        player.targetX = player.homeX;
        player.targetY = 34.0 + (ball.y - 34.0) * 0.15;
      } else {
        // Home'a doğru hafif drift
        player.targetX = player.homeX + (ball.x - player.homeX) * 0.1;
        player.targetY = player.homeY + (ball.y - player.homeY) * 0.1;
      }
    }
  }
}

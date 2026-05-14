import 'dart:math';
import '../entities/player.dart';
import '../entities/team.dart';
import '../entities/ball.dart';
import '../enums/player_role.dart';
import '../models/weather_condition.dart';

/// Toplu oyuncunun karar verme mekanizması.
///
/// Belirli aralıklarla toplu oyuncu şut, pas, top sürme veya bekleme
/// kararı verir. Karar ağırlıkları pozisyona, baskıya ve takım
/// arkadaşlarının durumuna göre hesaplanır.
class DecisionSystem {
  final Random _rng;

  DecisionSystem({Random? rng}) : _rng = rng ?? Random();

  // Karar verme aralığı (simülasyon saniyesi)
  static const double decisionInterval = 0.8;

  /// Karar sistemini güncelle.
  ///
  /// [ownTeam] toplu oyuncunun takımı.
  /// [oppTeam] rakip takım.
  /// [ball] top.
  /// [dt] zaman ölçeklenmiş deltaTime.
  void update(
    SimTeam ownTeam,
    SimTeam oppTeam,
    Ball ball,
    double dt, {
    WeatherCondition weather = WeatherCondition.clear,
    double matchMinute = 0,
  }) {
    if (ball.isInFlight) return; // Top havadaysa karar verme
    if (ball.owner == null) return; // Top boştaysa karar verme

    final player = ball.owner!;
    if (player.teamId != ownTeam.id) return; // Toplu oyuncu bizim takımda değilse

    // Cooldown kontrolü
    player.decisionCooldown -= dt;
    if (player.decisionCooldown > 0) return;

    // Karar ver
    _makeDecision(player, ownTeam, oppTeam, ball, weather, matchMinute);
    player.decisionCooldown = decisionInterval + _rng.nextDouble() * 0.5;
  }

  void _makeDecision(
    SimPlayer player,
    SimTeam ownTeam,
    SimTeam oppTeam,
    Ball ball,
    WeatherCondition weather,
    double matchMinute,
  ) {
    final double goalX = ownTeam.opponentGoalX;
    final double goalY = 34.0; // Kale merkezi Y
    final double distToGoal = player.distanceTo(goalX, goalY);

    // Rakip baskısı: en yakın rakibin mesafesi
    double nearestOppDist = 999.0;
    for (final opp in oppTeam.players) {
      final d = player.distanceToPlayer(opp);
      if (d < nearestOppDist) nearestOppDist = d;
    }

    // --- Ağırlık Hesaplama ---
    double shootWeight = 0.0;
    double passWeight = 0.0;
    double dribbleWeight = 0.0;
    final scoreDelta = ownTeam.score - oppTeam.score;
    final chasingLate = scoreDelta < 0 && matchMinute > 70;
    final protectingLate = scoreDelta > 0 && matchMinute > 75;

    // ŞUT: Kaleye yakınsa artır — agresif şut ağırlıkları
    if (distToGoal < 40.0) {
      shootWeight = 15.0;
      if (distToGoal < 30.0) shootWeight = 30.0;
      if (distToGoal < 22.0) shootWeight = 55.0;
      if (distToGoal < 15.0) shootWeight = 80.0;
    }
    // Forvetler şut çekmeye daha meyilli
    if (player.role == PlayerRole.fwd) shootWeight *= 1.5;
    if (player.role == PlayerRole.mid) shootWeight *= 1.2;
    // Kaleciler ve defansörler genelde şut atmaz
    if (player.role == PlayerRole.gk) shootWeight *= 0.05;
    if (player.role == PlayerRole.def) shootWeight *= 0.3;
    shootWeight *= 0.7 + ownTeam.attackBalance * 0.8;
    shootWeight *= 0.65 + player.composure / 140.0;
    if (chasingLate) shootWeight *= 1.25;
    if (protectingLate) shootWeight *= 0.75;

    // PAS: Takım arkadaşı boşsa
    final passTarget = _findBestPassTarget(player, ownTeam, oppTeam);
    if (passTarget != null) {
      passWeight = 35.0;
      // Baskı altındaysa pas ağırlığı artar
      if (nearestOppDist < 8.0) passWeight = 55.0;
      if (nearestOppDist < 5.0) passWeight = 70.0;
      passWeight *= 0.8 + player.vision / 120.0;
      if (protectingLate) passWeight *= 1.2;
    }

    // TOP SÜRME: Baskı yoksa ve kaleye doğru alan varsa
    dribbleWeight = 20.0;
    if (nearestOppDist > 12.0) dribbleWeight = 40.0;
    if (nearestOppDist < 5.0) dribbleWeight = 5.0;
    // Kaleciler top sürmez
    if (player.role == PlayerRole.gk) dribbleWeight = 2.0;
    dribbleWeight *= 0.75 + ownTeam.gameWidth * 0.35;
    dribbleWeight *= 0.7 + player.dribbling / 120.0;

    // --- Karar seçimi (ağırlıklı rastgele) ---
    final totalWeight = shootWeight + passWeight + dribbleWeight;
    if (totalWeight <= 0) return;

    final roll = _rng.nextDouble() * totalWeight;

    if (roll < shootWeight) {
      _executeShot(player, ball, goalX, goalY, nearestOppDist);
    } else if (roll < shootWeight + passWeight && passTarget != null) {
      _executePass(player, passTarget, ball, weather, nearestOppDist);
    } else {
      _executeDribble(player, ball, ownTeam);
    }
  }

  /// En iyi pas hedefini bul.
  /// Rakiplerden en uzak olan takım arkadaşını tercih et.
  SimPlayer? _findBestPassTarget(
    SimPlayer passer,
    SimTeam ownTeam,
    SimTeam oppTeam,
  ) {
    SimPlayer? best;
    double bestScore = -999.0;

    for (final mate in ownTeam.players) {
      if (mate.id == passer.id) continue;
      if (mate.role == PlayerRole.gk && passer.role != PlayerRole.gk) continue;

      // Pas mesafesi çok uzun olmasın
      final passDist = passer.distanceToPlayer(mate);
      if (passDist > 45.0 || passDist < 5.0) continue;

      // Rakiplerden uzaklık skoru
      double minOppDist = 999.0;
      for (final opp in oppTeam.players) {
        final d = mate.distanceToPlayer(opp);
        if (d < minOppDist) minOppDist = d;
      }

      // Skor: rakiplerden uzak + kaleye yakın bonus
      final goalDist = mate.distanceTo(ownTeam.opponentGoalX, 34.0);
      final forwardProgress =
          (mate.currentX - passer.currentX) * ownTeam.attackDirection;
      final widthFit = (mate.currentY - 34.0).abs() * ownTeam.gameWidth;
      final score =
          minOppDist * 2.0 -
          goalDist * 0.3 +
          forwardProgress * 0.45 +
          widthFit * 0.12 +
          mate.positioning * 0.08;

      if (score > bestScore) {
        bestScore = score;
        best = mate;
      }
    }

    return best;
  }

  /// Şut çek.
  void _executeShot(
    SimPlayer player,
    Ball ball,
    double goalX,
    double goalY,
    double nearestOppDist,
  ) {
    final pressurePenalty = nearestOppDist < 5.0 ? 1.4 : 1.0;
    final accuracy =
        ((player.shooting + player.composure + player.positioning) / 300.0)
            .clamp(0.0, 1.0);
    final targetSpread = (6.0 - accuracy * 3.5) * pressurePenalty;
    final targetY = goalY + (_rng.nextDouble() - 0.5) * targetSpread;
    final kickSpeed = 48.0 + player.shooting / 100.0 * 14.0;
    ball.shootTowards(goalX, targetY, kickSpeed: kickSpeed, shooter: player);
  }

  /// Pas at.
  void _executePass(
    SimPlayer passer,
    SimPlayer target,
    Ball ball,
    WeatherCondition weather,
    double nearestOppDist,
  ) {
    final passDist = passer.distanceToPlayer(target);
    final pressure = nearestOppDist < 5.0
        ? 0.14
        : nearestOppDist < 8.0
        ? 0.07
        : 0.0;
    final baseAccuracy =
        (passer.passing * 0.55 +
            passer.vision * 0.30 +
            passer.composure * 0.15) /
        100.0;
    final distancePenalty = (passDist / 90.0).clamp(0.0, 0.35);
    final accuracyFactor =
        (baseAccuracy * _weatherPassMultiplier(weather) -
                pressure -
                distancePenalty)
            .clamp(0.20, 0.98);
    final scatterX = (1.0 - accuracyFactor) * 7.0;
    final scatterY = (1.0 - accuracyFactor) * 5.0;
    final tx = target.currentX + (_rng.nextDouble() - 0.5) * scatterX;
    final ty = target.currentY + (_rng.nextDouble() - 0.5) * scatterY;
    ball.kickTowards(
      tx.clamp(1.0, 104.0),
      ty.clamp(1.0, 67.0),
      kickSpeed: 32.0 + accuracyFactor * 12.0,
      passer: passer,
      target: target,
    );
  }

  /// Top sür.
  void _executeDribble(SimPlayer player, Ball ball, SimTeam ownTeam) {
    final dx =
        ownTeam.attackDirection *
        (4.0 + _rng.nextDouble() * (5.0 + ownTeam.attackBalance * 6.0));
    final dy = (_rng.nextDouble() - 0.5) * (4.0 + ownTeam.gameWidth * 5.0);
    final newX = (player.currentX + dx).clamp(1.0, 104.0);
    final newY = (player.currentY + dy).clamp(1.0, 67.0);
    player.targetX = newX;
    player.targetY = newY;
  }

  double _weatherPassMultiplier(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return 1.0;
      case WeatherCondition.cloudy:
        return 0.97;
      case WeatherCondition.rainy:
        return 0.88;
      case WeatherCondition.stormy:
        return 0.76;
      case WeatherCondition.snowy:
        return 0.70;
    }
  }
}

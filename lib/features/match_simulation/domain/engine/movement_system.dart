import 'dart:math';
import '../entities/player.dart';
import '../entities/ball.dart';
import '../enums/player_role.dart';
import '../models/weather_condition.dart';

/// Oyuncuların fiziksel hareketini yöneten sistem.
///
/// Her frame'de [update] çağrılarak oyuncular hedef pozisyonlarına
/// doğru yumuşak biçimde (deltaTime tabanlı) hareket ettirilir.
/// Saha sınırları ve minimum oyuncu mesafesi kontrol edilir.
class MovementSystem {
  double _weatherFactor = 1.0;

  // Saha boyutları (birim)
  static const double fieldWidth = 105.0;
  static const double fieldHeight = 68.0;

  // Oyuncular arası minimum mesafe
  static const double minSeparation = 2.0;

  /// Tüm oyuncuları güncelle.
  ///
  /// [dt] zaman ölçeklenmiş deltaTime (saniye).
  void update(
    List<SimPlayer> allPlayers,
    Ball ball,
    double dt, {
    WeatherCondition weather = WeatherCondition.clear,
  }) {
    _weatherFactor = _weatherSpeedFactor(weather);
    for (final player in allPlayers) {
      _moveTowardsTarget(player, dt);
      _clampToField(player);

      // Toplu oyuncu ise topu pozisyona taşı
      if (player.hasBall && ball.owner == player) {
        ball.x = player.currentX;
        ball.y = player.currentY;
      }
    }

    // Çakışma ayrıştırma (separation)
    _applySeparation(allPlayers);

    // Topu güncelle (havadaysa)
    _updateBallFlight(ball, allPlayers, dt);
  }

  /// Oyuncuyu hedefe doğru deltaTime bazlı hareket ettir.
  void _moveTowardsTarget(SimPlayer player, double dt) {
    final dx = player.targetX - player.currentX;
    final dy = player.targetY - player.currentY;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < 0.3) {
      return; // Zaten hedefteyse hareket etme
    }

    // Yön vektörünü normalize et
    final nx = dx / dist;
    final ny = dy / dist;

    // Stamina etkisi: düşük stamina → düşük hız
    final effectiveSpeed = player.speed * (0.6 + 0.4 * player.stamina);

    final moveAmount = effectiveSpeed * dt * _weatherFactor;

    if (moveAmount >= dist) {
      // Hedefe ulaştı
      player.currentX = player.targetX;
      player.currentY = player.targetY;
    } else {
      player.currentX += nx * moveAmount;
      player.currentY += ny * moveAmount;
    }

    // Stamina azalması (çok yavaş)
    player.stamina = (player.stamina - 0.0005 * dt).clamp(0.1, 1.0);
  }

  /// Oyuncuyu saha sınırları içinde tut.
  void _clampToField(SimPlayer player) {
    player.currentX = player.currentX.clamp(0.5, fieldWidth - 0.5);
    player.currentY = player.currentY.clamp(0.5, fieldHeight - 0.5);

    // Kaleci kısıtlaması: kendi ceza sahası bölgesinde kalsın
    if (player.role == PlayerRole.gk) {
      if (player.homeX < fieldWidth / 2) {
        // Sol kaleci
        player.currentX = player.currentX.clamp(0.5, 18.0);
        player.currentY = player.currentY.clamp(14.0, 54.0);
      } else {
        // Sağ kaleci
        player.currentX = player.currentX.clamp(87.0, fieldWidth - 0.5);
        player.currentY = player.currentY.clamp(14.0, 54.0);
      }
    }
  }

  /// Oyuncular arasında minimum mesafe koru (çakışma engelleme).
  void _applySeparation(List<SimPlayer> allPlayers) {
    for (int i = 0; i < allPlayers.length; i++) {
      for (int j = i + 1; j < allPlayers.length; j++) {
        final a = allPlayers[i];
        final b = allPlayers[j];

        final dx = b.currentX - a.currentX;
        final dy = b.currentY - a.currentY;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < minSeparation && dist > 0.001) {
          final overlap = (minSeparation - dist) / 2.0;
          final nx = dx / dist;
          final ny = dy / dist;

          a.currentX -= nx * overlap;
          a.currentY -= ny * overlap;
          b.currentX += nx * overlap;
          b.currentY += ny * overlap;
        }
      }
    }
  }

  /// Havadaki topu (pas/şut) hedefe doğru hareket ettir.
  void _updateBallFlight(Ball ball, List<SimPlayer> allPlayers, double dt) {
    if (!ball.isInFlight) {
      return;
    }

    final dx = ball.targetX - ball.x;
    final dy = ball.targetY - ball.y;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < 1.5) {
      // Top hedefe ulaştı
      ball.x = ball.targetX;
      ball.y = ball.targetY;
      ball.isInFlight = false;
      return;
    }

    final nx = dx / dist;
    final ny = dy / dist;
    final moveAmount = ball.speed * dt * _weatherFactor;

    if (moveAmount >= dist) {
      ball.x = ball.targetX;
      ball.y = ball.targetY;
      ball.isInFlight = false;
    } else {
      ball.x += nx * moveAmount;
      ball.y += ny * moveAmount;
    }

    // Saha sınırı kontrolü
    ball.x = ball.x.clamp(0.0, fieldWidth);
    ball.y = ball.y.clamp(0.0, fieldHeight);
  }

  double _weatherSpeedFactor(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.rainy:
        return 0.85;
      case WeatherCondition.stormy:
        return 0.70;
      case WeatherCondition.snowy:
        return 0.60;
      case WeatherCondition.clear:
      case WeatherCondition.cloudy:
        return 1.0;
    }
  }
}

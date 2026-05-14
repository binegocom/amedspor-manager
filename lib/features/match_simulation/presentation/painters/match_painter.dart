import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/entities/ball.dart';
import '../../domain/entities/team.dart';
import '../../domain/engine/match_state.dart';
import '../../domain/models/weather_condition.dart';
import '../../domain/enums/boost_type.dart';

/// 2D futbol sahası ve maç görselleştirme çizicisi — DİKEY (Portrait) mod.
///
/// Saha koordinat sistemi: X: 0-105 (uzunluk), Y: 0-68 (genişlik).
/// Ekranda dikey gösterim: fieldX → ekran Y, fieldY → ekran X.
/// Kaleler üstte ve altta.
class MatchPainter extends CustomPainter {
  final SimTeam homeTeam;
  final SimTeam awayTeam;
  final Ball ball;
  final MatchState matchState;
  final WeatherCondition weather;

  // Rastgele damla/kar tanesi konumları (cache)
  static final List<_Particle> _particles = [];
  static bool _particlesInitialized = false;

  // Saha boyutları (birim)
  static const double fieldLength = 105.0; // X ekseni — ekranda dikey
  static const double fieldWidth = 68.0; // Y ekseni — ekranda yatay

  // Çizim için padding
  static const double padding = 10.0;

  MatchPainter({
    required this.homeTeam,
    required this.awayTeam,
    required this.ball,
    required this.matchState,
    this.weather = WeatherCondition.clear,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    final sx = drawW / fieldWidth;
    final sy = drawH / fieldLength;

    canvas.save();
    canvas.translate(padding, padding);

    _drawField(canvas, drawW, drawH, sx, sy);
    _drawAtmosphere(canvas, drawW, drawH); // NEW: Flare smoke
    _drawWeatherEffects(canvas, drawW, drawH);
    _drawPlayers(canvas, homeTeam, sx, sy);
    _drawPlayers(canvas, awayTeam, sx, sy);
    _drawBall(canvas, sx, sy);
    _drawScoreAndTime(canvas, drawW, sx, sy);

    canvas.restore();
  }

  /// Saha koordinatını ekran koordinatına çevir (DİKEY mod).
  Offset _toScreen(double fieldX, double fieldY, double sx, double sy) {
    return Offset(fieldY * sx, fieldX * sy);
  }

  /// Hava durumu efektlerini çiz.
  void _drawWeatherEffects(Canvas canvas, double w, double h) {
    if (weather == WeatherCondition.clear ||
        weather == WeatherCondition.cloudy) {
      return;
    }

    // Partikülleri başlat
    if (!_particlesInitialized) {
      _particles.clear();
      final rng = Random(42);
      final count = weather == WeatherCondition.stormy
          ? 80
          : weather == WeatherCondition.rainy
          ? 50
          : weather == WeatherCondition.snowy
          ? 40
          : 0;
      for (int i = 0; i < count; i++) {
        _particles.add(
          _Particle(
            x: rng.nextDouble() * w,
            y: rng.nextDouble() * h,
            speed: 1.5 + rng.nextDouble() * 2.0,
            size: weather == WeatherCondition.snowy
                ? 2.0 + rng.nextDouble() * 3.0
                : 1.0 + rng.nextDouble(),
            drift: (rng.nextDouble() - 0.5) * 2.0,
          ),
        );
      }
      _particlesInitialized = true;
    }

    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final rng = Random(now.floor());

    // Partikülleri hareket ettir ve çiz
    for (final p in _particles) {
      p.y += p.speed;
      p.x += sin(now * 2 + p.y * 0.1) * p.drift;

      if (p.y > h) {
        p.y = -5;
        p.x = rng.nextDouble() * w;
      }
      if (p.x < 0) {
        p.x = w;
      }
      if (p.x > w) {
        p.x = 0;
      }

      Paint particlePaint;
      if (weather == WeatherCondition.snowy) {
        particlePaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
        canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
      } else if (weather == WeatherCondition.rainy ||
          weather == WeatherCondition.stormy) {
        particlePaint = Paint()
          ..color = Colors.lightBlue.withValues(
            alpha: weather == WeatherCondition.stormy ? 0.5 : 0.3,
          )
          ..strokeWidth = p.size
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(p.x, p.y),
          Offset(p.x + p.drift, p.y + p.speed * 2),
          particlePaint,
        );
      }
    }

    // Fırtına efekti - hafif karartma
    if (weather == WeatherCondition.stormy) {
      final fogPaint = Paint()..color = Colors.black.withValues(alpha: 0.05);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fogPaint);
    }
  }

  void _drawAtmosphere(Canvas canvas, double w, double h) {
    // Meşale efekti (Home team için)
    if (homeTeam.activeBoosts.containsKey(BoostType.mesale)) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final smokePaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.1 + sin(now * 5) * 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      // Alt tribünlerde duman
      canvas.drawCircle(Offset(w / 2, h - 20), 100, smokePaint);
      
      // Rastgele parlamalar
      final glowPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      for (int i = 0; i < 5; i++) {
        final gx = (w * 0.2) + (sin(now + i) * 50) + (w * 0.3);
        final gy = h - 10 - (i * 5);
        canvas.drawCircle(Offset(gx, gy), 15, glowPaint);
      }
    }
  }

  /// Skor ve dakikayı saha üzerinde göster.
  void _drawScoreAndTime(Canvas canvas, double w, double sx, double sy) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${homeTeam.score} - ${awayTeam.score}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(w / 2 - textPainter.width / 2, sy * 2));
  }

  /// Yeşil saha ve beyaz çizgiler — DİKEY.
  void _drawField(Canvas canvas, double w, double h, double sx, double sy) {
    // Zemin (hava durumuna göre renk değişimi)
    Color fieldColor;
    switch (weather) {
      case WeatherCondition.clear:
      case WeatherCondition.cloudy:
        fieldColor = const Color(0xFF2E7D32);
      case WeatherCondition.rainy:
        fieldColor = const Color(0xFF1B5E20);
      case WeatherCondition.stormy:
        fieldColor = const Color(0xFF1A4A1A);
      case WeatherCondition.snowy:
        fieldColor = const Color(0xFF3A6B3A);
    }

    final fieldPaint = Paint()..color = fieldColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(6),
      ),
      fieldPaint,
    );

    // Çim deseni (yatay bantlar)
    final stripeColor = weather == WeatherCondition.snowy
        ? const Color(0xFF4A7B4A)
        : weather == WeatherCondition.rainy
        ? const Color(0xFF256D28)
        : const Color(0xFF388E3C);
    final stripePaint = Paint()..color = stripeColor;
    const stripeCount = 14;
    final stripeH = h / stripeCount;
    for (int i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, w, stripeH), stripePaint);
    }

    // Kar efekti
    if (weather == WeatherCondition.snowy) {
      final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), snowPaint);
    }

    // Çizgi boyası
    final linePaint = Paint()
      ..color = Colors.white.withValues(
        alpha: weather == WeatherCondition.stormy ? 0.6 : 0.85,
      )
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Dış kenar
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);

    // Orta çizgi
    final midY = h / 2;
    canvas.drawLine(Offset(0, midY), Offset(w, midY), linePaint);

    // Orta daire
    final centerX = w / 2;
    final centerY = h / 2;
    canvas.drawCircle(Offset(centerX, centerY), 9.15 * sx, linePaint);

    // Orta nokta
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(centerX, centerY), 2.5, dotPaint);

    // Ceza sahaları
    final penaltyDepth = 16.5 * sy;
    final penaltyW = 40.3 * sx;
    final penaltyLeft = (w - penaltyW) / 2;
    canvas.drawRect(
      Rect.fromLTWH(penaltyLeft, 0, penaltyW, penaltyDepth),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(penaltyLeft, h - penaltyDepth, penaltyW, penaltyDepth),
      linePaint,
    );

    // Kale alanı
    final goalAreaDepth = 5.5 * sy;
    final goalAreaW = 18.3 * sx;
    final goalAreaLeft = (w - goalAreaW) / 2;
    canvas.drawRect(
      Rect.fromLTWH(goalAreaLeft, 0, goalAreaW, goalAreaDepth),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(goalAreaLeft, h - goalAreaDepth, goalAreaW, goalAreaDepth),
      linePaint,
    );

    // Kaleler
    final goalW = 7.32 * sx;
    final goalLeft = (w - goalW) / 2;
    final goalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(goalLeft, -4, goalW, 4), goalPaint);
    canvas.drawRect(Rect.fromLTWH(goalLeft, h, goalW, 4), goalPaint);

    // Penaltı noktaları
    canvas.drawCircle(Offset(centerX, 11.0 * sy), 2, dotPaint);
    canvas.drawCircle(Offset(centerX, h - 11.0 * sy), 2, dotPaint);

    // Ceza sahası yarım daireleri
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, 11.0 * sy), radius: 9.15 * sx),
      0.3,
      pi - 0.6,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(centerX, h - 11.0 * sy),
        radius: 9.15 * sx,
      ),
      pi + 0.3,
      pi - 0.6,
      false,
      arcPaint,
    );

    // Köşe yayları
    const cornerRadius = 3.0;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 0), radius: cornerRadius),
      0,
      pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w, 0), radius: cornerRadius),
      pi / 2,
      pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, h), radius: cornerRadius),
      -pi / 2,
      pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w, h), radius: cornerRadius),
      pi,
      pi / 2,
      false,
      linePaint,
    );

    // Takım isimleri (orta sahada)
    final namePaint = TextPainter(
      text: TextSpan(
        text: '${homeTeam.name} - ${awayTeam.name}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePaint.layout();
    namePaint.paint(canvas, Offset(w / 2 - namePaint.width / 2, midY + 20));
  }

  /// Oyuncuları çiz.
  void _drawPlayers(Canvas canvas, SimTeam team, double sx, double sy) {
    for (final player in team.players) {
      final pos = _toScreen(player.currentX, player.currentY, sx, sy);

      // Performans rengi
      Color perfColor;
      if (player.performanceRating >= 8.0) {
        perfColor = Colors.greenAccent;
      } else if (player.performanceRating >= 6.0) {
        perfColor = Colors.amber;
      } else {
        perfColor = Colors.redAccent;
      }

      // Oyuncu gölgesi
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(pos.dx + 1, pos.dy + 1.5), 8, shadowPaint);

      // Oyuncu dairesi
      final playerRadius = player.hasBall ? 10.0 : 8.0;
      final playerPaint = Paint()..color = team.color;
      canvas.drawCircle(pos, playerRadius, playerPaint);

      // Performans halkası
      if (!player.hasBall) {
        final perfRingPaint = Paint()
          ..color = perfColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(pos, playerRadius + 2, perfRingPaint);
      }

      // Dış kenar
      final borderPaint = Paint()
        ..color = player.hasBall
            ? Colors.yellow
            : Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = player.hasBall ? 2.5 : 1.2;
      canvas.drawCircle(pos, playerRadius, borderPaint);

      // Sakat oyuncu işareti
      if (player.isInjured) {
        final injPaint = Paint()
          ..color = Colors.red.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(pos.dx - 5, pos.dy - 5),
          Offset(pos.dx + 5, pos.dy + 5),
          injPaint,
        );
        canvas.drawLine(
          Offset(pos.dx + 5, pos.dy - 5),
          Offset(pos.dx - 5, pos.dy + 5),
          injPaint,
        );
      }

      // Kırmızı kartlı oyuncu işareti
      if (player.redCard > 0) {
        final rcPaint = Paint()..color = Colors.red.withValues(alpha: 0.8);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(pos.dx, pos.dy - 12),
            width: 8,
            height: 12,
          ),
          rcPaint,
        );
      }

      // Oyuncu numarası
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${player.number}',
          style: TextStyle(
            color: Colors.white,
            fontSize: player.hasBall ? 9 : 7,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );

      // Stamina bar
      if (player.stamina < 0.98) {
        final barW = 12.0;
        const barH = 2.0;
        final barBgPaint = Paint()..color = Colors.black45;
        canvas.drawRect(
          Rect.fromLTWH(
              pos.dx - barW / 2, pos.dy + playerRadius + 3, barW, barH),
          barBgPaint,
        );
        final stamColor = player.stamina > 0.5
            ? Colors.greenAccent
            : player.stamina > 0.25
                ? Colors.orangeAccent
                : Colors.redAccent;
        final barFgPaint = Paint()..color = stamColor;
        canvas.drawRect(
          Rect.fromLTWH(pos.dx - barW / 2, pos.dy + playerRadius + 3,
              barW * player.stamina, barH),
          barFgPaint,
        );
      }
    }
  }

  /// Topu çiz.
  void _drawBall(Canvas canvas, double sx, double sy) {
    final pos = _toScreen(ball.x, ball.y, sx, sy);

    // Hareket efekti (top hızlıysa)
    if (ball.speed > 40 && ball.isInFlight) {
      final trailPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 2;
      final dx = (ball.targetX - ball.x) / 5;
      final dy = (ball.targetY - ball.y) / 5;
      canvas.drawLine(
        Offset(pos.dx - dy * sx * 0.5, pos.dy - dx * sy * 0.5),
        pos,
        trailPaint,
      );
    }

    // Gölge
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(pos.dx + 1, pos.dy + 1.5), 4.5, shadowPaint);

    // Top dış (siyah)
    final outerPaint = Paint()..color = Colors.black;
    canvas.drawCircle(pos, 5.0, outerPaint);

    // Top iç (beyaz)
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pos, 4.0, innerPaint);

    // Üst parlak efekt
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(pos.dx - 1, pos.dy - 1), 1.8, shinePaint);
  }

  @override
  bool shouldRepaint(covariant MatchPainter oldDelegate) => true;
}

/// Partikül (yağmur damlası / kar tanesi) yardımcı sınıfı.
class _Particle {
  double x;
  double y;
  double speed;
  double size;
  double drift;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.drift,
  });
}

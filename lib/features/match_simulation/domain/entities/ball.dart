import 'dart:math';
import 'player.dart';

/// Futbol topu entity'si.
///
/// Top bir oyuncudaysa [owner] set edilir ve topun koordinatları oyuncuyu takip eder.
/// Top havadaysa (pas/şut) [owner] null olur ve top [targetX]/[targetY] hedefine doğru
/// [speed] hızıyla hareket eder.
class Ball {
  double x;
  double y;

  double targetX;
  double targetY;

  double speed; // birim/saniye

  /// Topun sahibi olan oyuncu. null ise top boşta veya havada.
  SimPlayer? owner;
  SimPlayer? lastTouchedBy;
  SimPlayer? passer;
  SimPlayer? intendedReceiver;

  /// Top havada hareket halinde mi (pas veya şut).
  bool isInFlight;

  /// Bu uçuş bir şut mu? (gol kontrolü için)
  bool isShot;
  int shotSequence;
  double shotXg;

  Ball({
    this.x = 52.5,
    this.y = 34.0,
    this.targetX = 52.5,
    this.targetY = 34.0,
    this.speed = 35.0,
    this.owner,
    this.isInFlight = false,
    this.isShot = false,
    this.shotSequence = 0,
    this.shotXg = 0.0,
  });

  /// Topu bir oyuncuya ver.
  void giveTo(SimPlayer player) {
    // Önceki sahibinin topunu al
    owner?.hasBall = false;

    owner = player;
    lastTouchedBy = player;
    player.hasBall = true;
    isInFlight = false;
    isShot = false;
    x = player.currentX;
    y = player.currentY;
  }

  /// Topu boşa bırak (havada veya yerde).
  void release() {
    if (owner != null) {
      lastTouchedBy = owner;
    }
    owner?.hasBall = false;
    owner = null;
  }

  /// Şutu çeken oyuncu (gol/kurtarış hesaplamaları için).
  SimPlayer? shotBy;

  /// Topu bir hedefe fırlat (pas).
  void kickTowards(
    double tx,
    double ty, {
    double kickSpeed = 40.0,
    SimPlayer? passer,
    SimPlayer? target,
  }) {
    final passingPlayer = passer ?? owner;
    release();
    this.passer = passingPlayer;
    intendedReceiver = target;
    targetX = tx;
    targetY = ty;
    speed = kickSpeed;
    isInFlight = true;
    isShot = false;
    shotBy = null;
    shotXg = 0.0;
  }

  /// Kaleye şut çek.
  void shootTowards(
    double tx,
    double ty, {
    double kickSpeed = 55.0,
    SimPlayer? shooter,
  }) {
    release();
    passer = null;
    intendedReceiver = null;
    targetX = tx;
    targetY = ty;
    speed = kickSpeed;
    isInFlight = true;
    isShot = true;
    shotBy = shooter;
    shotSequence++;
    shotXg = 0.0;
  }

  void clearPassContext() {
    passer = null;
    intendedReceiver = null;
  }

  /// İki nokta arasındaki mesafe.
  double distanceTo(double x, double y) {
    final dx = this.x - x;
    final dy = this.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Top hedefe ulaştı mı?
  bool get reachedTarget {
    final dx = x - targetX;
    final dy = y - targetY;
    return (dx * dx + dy * dy) < 2.0 * 2.0;
  }

  /// Topu orta sahaya resetle.
  void resetToCenter() {
    x = 52.5;
    y = 34.0;
    targetX = 52.5;
    targetY = 34.0;
    speed = 35.0;
    isInFlight = false;
    isShot = false;
    shotXg = 0.0;
    clearPassContext();
    release();
  }
}

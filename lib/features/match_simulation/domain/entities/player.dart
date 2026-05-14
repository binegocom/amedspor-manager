import 'dart:math';
import '../enums/player_role.dart';

/// Tekil futbolcu entity'si.
///
/// Pozisyon, hedef, hız ve top durumu bilgilerini taşır.
/// [currentX]/[currentY] anlık konum, [targetX]/[targetY] hedef konum.
/// [homeX]/[homeY] oyuncunun dizilimdeki orijinal pozisyonu.
class SimPlayer {
  final int id;
  final String? originalPlayerId;
  final int teamId;
  final String name;
  final int number;
  final PlayerRole role;

  // Dizilim orijinal pozisyonu (saha birimleri: 0-105 x, 0-68 y)
  double homeX;
  double homeY;

  // Anlık pozisyon
  double currentX;
  double currentY;

  // Hedef pozisyon - oyuncu buraya doğru hareket eder
  double targetX;
  double targetY;

  // Fiziksel özellikler
  double speed; // birim/saniye
  double stamina; // 0.0 - 1.0

  // ---- OYUNCU İSTATİSTİKLERİ (0-100) ----
  double shooting; // Şut gücü ve isabeti
  double passing; // Pas yeteneği
  double defending; // Savunma yeteneği
  double dribbling; // Top sürme
  double aggression; // Agresiflik (faul yapma ihtimali)
  double vision; // Oyun görüşü
  double positioning; // Pozisyon alma
  double composure; // Baskı altında sakinlik
  double workRate; // Topsuz koşu ve pres isteği

  // Top durumu
  bool hasBall;

  // Karar sistemi için cooldown (saniye cinsinden)
  double decisionCooldown;

  // ---- MORAL / PSİKOLOJİ ----
  double morale; // 0.0 - 1.0, gol yedikçe düşer

  // ---- YORGUNLUK ----
  double totalDistanceRun; // Toplam koşu mesafesi
  bool isInjured; // Sakatlık durumu

  // ---- PERFORMANS PUANI ----
  double performanceRating; // 1.0 - 10.0

  // ---- İSTATİSTİK SAYAÇLARI ----
  int shots; // Çekilen şut sayısı
  int shotsOnTarget; // İsabetli şut sayısı
  int successfulPasses; // Başarılı pas
  int failedPasses; // Başarısız pas
  int tackles; // Yapılan müdahale
  int fouls; // Yapılan faul
  int foulsReceived; // Faule maruz kalma
  int yellowCards; // Sarı kart
  int redCard; // Kırmızı kart (0 veya 1)
  double passAccuracy; // Pas yüzdesi (hesaplanır)
  double expectedGoals; // xG toplamı

  SimPlayer({
    required this.id,
    this.originalPlayerId,
    required this.teamId,
    required this.name,
    required this.number,
    required this.role,
    required this.homeX,
    required this.homeY,
    this.speed = 18.0,
    this.stamina = 1.0,
    this.hasBall = false,
    this.decisionCooldown = 0.0,
    this.shooting = 50,
    this.passing = 50,
    this.defending = 50,
    this.dribbling = 50,
    this.aggression = 50,
    this.vision = 50,
    this.positioning = 50,
    this.composure = 50,
    this.workRate = 50,
    this.morale = 1.0,
    this.totalDistanceRun = 0.0,
    this.isInjured = false,
    this.performanceRating = 6.0,
    this.shots = 0,
    this.shotsOnTarget = 0,
    this.successfulPasses = 0,
    this.failedPasses = 0,
    this.tackles = 0,
    this.fouls = 0,
    this.foulsReceived = 0,
    this.yellowCards = 0,
    this.redCard = 0,
    this.passAccuracy = 0.0,
    this.expectedGoals = 0.0,
  }) : currentX = homeX,
       currentY = homeY,
       targetX = homeX,
       targetY = homeY;

  /// Rollere göre varsayılan istatistik ata.
  static SimPlayer createWithRole({
    required int id,
    String? originalPlayerId,
    required int teamId,
    required String name,
    required int number,
    required PlayerRole role,
    required double homeX,
    required double homeY,
    double speed = 18.0,
    Random? rng,
  }) {
    double shooting;
    double passing;
    double defending;
    double dribbling;
    double aggression;
    double vision;
    double positioning;
    double composure;
    double workRate;

    switch (role) {
      case PlayerRole.gk:
        shooting = 15;
        passing = 40;
        defending = 60;
        dribbling = 20;
        aggression = 30;
        vision = 45;
        positioning = 75;
        composure = 65;
        workRate = 35;
        speed = 14.0;
      case PlayerRole.def:
        shooting = 25;
        passing = 45;
        defending = 75;
        dribbling = 35;
        aggression = 60;
        vision = 45;
        positioning = 70;
        composure = 55;
        workRate = 65;
        speed = 16.0;
      case PlayerRole.mid:
        shooting = 45;
        passing = 70;
        defending = 45;
        dribbling = 60;
        aggression = 45;
        vision = 72;
        positioning = 65;
        composure = 65;
        workRate = 75;
        speed = 18.0;
      case PlayerRole.fwd:
        shooting = 75;
        passing = 50;
        defending = 20;
        dribbling = 70;
        aggression = 35;
        vision = 55;
        positioning = 78;
        composure = 72;
        workRate = 65;
        speed = 20.0;
    }

    // Her oyuncuya +/-15 rastgele sapma ekle
    final random = rng ?? Random();
    double vary(double value) {
      return (value + (random.nextDouble() - 0.5) * 30).clamp(10, 99);
    }

    shooting = vary(shooting);
    passing = vary(passing);
    defending = vary(defending);
    dribbling = vary(dribbling);
    aggression = vary(aggression);
    vision = vary(vision);
    positioning = vary(positioning);
    composure = vary(composure);
    workRate = vary(workRate);

    return SimPlayer(
      id: id,
      originalPlayerId: originalPlayerId,
      teamId: teamId,
      name: name,
      number: number,
      role: role,
      homeX: homeX,
      homeY: homeY,
      speed: speed,
      shooting: shooting,
      passing: passing,
      defending: defending,
      dribbling: dribbling,
      aggression: aggression,
      vision: vision,
      positioning: positioning,
      composure: composure,
      workRate: workRate,
    );
  }

  /// İki nokta arasındaki Öklidyen mesafe.
  double distanceTo(double x, double y) {
    final dx = currentX - x;
    final dy = currentY - y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Başka bir oyuncuya olan mesafe.
  double distanceToPlayer(SimPlayer other) {
    return distanceTo(other.currentX, other.currentY);
  }

  /// Oyuncunun hedef pozisyona ulaşıp ulaşmadığını kontrol eder.
  bool get isAtTarget {
    return distanceTo(targetX, targetY) < 0.5;
  }

  /// Oyuncuyu home pozisyonuna resetle.
  void resetToHome() {
    currentX = homeX;
    currentY = homeY;
    targetX = homeX;
    targetY = homeY;
    hasBall = false;
    decisionCooldown = 0.0;
    morale = 1.0;
    stamina = 1.0;
    totalDistanceRun = 0.0;
    isInjured = false;
    performanceRating = 6.0;
    shots = 0;
    shotsOnTarget = 0;
    successfulPasses = 0;
    failedPasses = 0;
    tackles = 0;
    fouls = 0;
    foulsReceived = 0;
    yellowCards = 0;
    redCard = 0;
    passAccuracy = 0.0;
    expectedGoals = 0.0;
  }

  /// Pas yüzdesini hesapla.
  double get calculatedPassAccuracy {
    final total = successfulPasses + failedPasses;
    if (total == 0) return 0;
    return successfulPasses / total;
  }

  /// Oyuncunun toplam istatistik puanı (ortalama).
  double get overallRating {
    return (shooting +
            passing +
            defending +
            dribbling +
            vision +
            positioning +
            composure +
            workRate) /
        8.0;
  }
}

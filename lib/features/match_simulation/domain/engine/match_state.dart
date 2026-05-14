import '../enums/match_phase.dart';
import '../enums/boost_type.dart';
import '../entities/player.dart';

/// Maçın anlık durumunu tutan veri sınıfı.
///
/// [elapsedRealSeconds] gerçek geçen süre (saniye).
/// [matchMinute] simülasyon içi dakika (0-90 veya 0-120 uzatma).
/// [timeScale] 1.0 = normal, 2.0 = hızlı.
class MatchState {
  /// Gerçek zamanda geçen toplam saniye.
  double elapsedRealSeconds;

  /// Simülasyondaki maç dakikası (0.0 - maxMinute).
  double matchMinute;

  /// Mevcut maç fazı.
  MatchPhase phase;

  /// Zaman ölçekleme faktörü. 1.0 = normal (60sn = 90dk), 2.0 = hızlı (30sn = 90dk).
  double timeScale;

  /// Maçın toplam gerçek süresi (saniye). Varsayılan 60.
  final double totalRealDuration;
  final bool enableExtraTime;

  /// Gol sonrası kısa duraklama sayacı.
  double goalPauseTimer;

  // ---- DEVRE & UZATMA ----
  bool isFirstHalfDone; // İlk yarı bitti mi?
  bool isSecondHalfDone; // İkinci yarı bitti mi?
  int
  currentHalf; // 1 = ilk yarı, 2 = ikinci yarı, 3 = 1. uzatma, 4 = 2. uzatma
  double halftimePauseTimer; // Devre arası sayacı
  bool isExtraTime; // Uzatma var mı?
  bool isPenaltyShootout; // Penaltı atışları aşaması

  // ---- DURAN TOP VE OLAY SAYAÇLARI ----
  double setPieceTimer; // Duran top bekleme sayacı
  MatchPhase pendingSetPiece; // Bekleyen duran top türü
  double foulPauseTimer; // Faul duraklama sayacı
  SimPlayer? foulCommittedBy; // Faulü yapan oyuncu
  SimPlayer? foulReceivedBy; // Faulü yiyen oyuncu
  bool penaltyAwarded; // Penaltı verildi mi?

  // ---- UYARI ----
  bool isWarningShown; // Maç içi uyarı gösteriliyor mu?
  String warningMessage; // Uyarı mesajı

  // ---- BOOST SİSTEMİ ----
  BoostType? homeBoost;
  BoostType? awayBoost;
  double homeBoostTimer;
  double awayBoostTimer;

  // ---- İSTATİSTİK SAYAÇLARI (geçici) ----
  double homePossessionTime;
  double awayPossessionTime;

  MatchState({
    this.elapsedRealSeconds = 0.0,
    this.matchMinute = 0.0,
    this.phase = MatchPhase.kickoff,
    this.timeScale = 1.0,
    this.totalRealDuration = 60.0,
    this.enableExtraTime = false,
    this.goalPauseTimer = 0.0,
    this.isFirstHalfDone = false,
    this.isSecondHalfDone = false,
    this.currentHalf = 1,
    this.halftimePauseTimer = 0.0,
    this.isExtraTime = false,
    this.isPenaltyShootout = false,
    this.setPieceTimer = 0.0,
    this.pendingSetPiece = MatchPhase.kickoff,
    this.foulPauseTimer = 0.0,
    this.penaltyAwarded = false,
    this.isWarningShown = false,
    this.warningMessage = '',
    this.homeBoost,
    this.awayBoost,
    this.homeBoostTimer = 0.0,
    this.awayBoostTimer = 0.0,
    this.homePossessionTime = 0.0,
    this.awayPossessionTime = 0.0,
  });

  /// Maç bitti mi?
  bool get isFinished => phase == MatchPhase.finished;

  /// Gösterim için dakikayı tam sayı olarak döndür.
  int get displayMinute => matchMinute.floor().clamp(0, maxMinute);

  /// Maksimum dakika (uzatma varsa 120, yoksa 90).
  int get maxMinute => isExtraTime ? 120 : 90;

  /// Gerçek süreyi ve maç dakikasını güncelle.
  ///
  /// [realDt] gerçek deltaTime (saniye). timeScale burada uygulanır.
  void advanceTime(double realDt) {
    final scaledDt = realDt * timeScale;
    elapsedRealSeconds += scaledDt;

    // matchMinute = geçen ölçeklenmiş süre * (maxMinute / toplam süre)
    final totalMatchMinutes = isExtraTime ? 120.0 : 90.0;
    matchMinute = (elapsedRealSeconds / totalRealDuration) * totalMatchMinutes;

    if (matchMinute >= totalMatchMinutes) {
      matchMinute = totalMatchMinutes;

      if (enableExtraTime && !isExtraTime && phase != MatchPhase.finished) {
        // Normal süre bitti, uzatmaya geç
        isExtraTime = true;
        elapsedRealSeconds = 0.0;
        matchMinute = 90.0;
        phase = MatchPhase.kickoff;
        currentHalf = 3;
      } else {
        phase = MatchPhase.finished;
      }
    }

    // Devre arası kontrolü (45. dakika)
    if (!isFirstHalfDone &&
        matchMinute >= 45.0 &&
        phase != MatchPhase.halftime) {
      isFirstHalfDone = true;
      phase = MatchPhase.halftime;
      halftimePauseTimer = 3.0;
      currentHalf = 2;
    }
  }

  /// Maçı tamamen sıfırla.
  void reset() {
    elapsedRealSeconds = 0.0;
    matchMinute = 0.0;
    phase = MatchPhase.kickoff;
    timeScale = 1.0;
    goalPauseTimer = 0.0;
    isFirstHalfDone = false;
    isSecondHalfDone = false;
    currentHalf = 1;
    halftimePauseTimer = 0.0;
    isExtraTime = false;
    isPenaltyShootout = false;
    setPieceTimer = 0.0;
    pendingSetPiece = MatchPhase.kickoff;
    foulPauseTimer = 0.0;
    foulCommittedBy = null;
    foulReceivedBy = null;
    penaltyAwarded = false;
    isWarningShown = false;
    warningMessage = '';
    homeBoost = null;
    awayBoost = null;
    homeBoostTimer = 0.0;
    awayBoostTimer = 0.0;
    homePossessionTime = 0.0;
    awayPossessionTime = 0.0;
  }
}

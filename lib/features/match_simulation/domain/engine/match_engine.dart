import 'dart:math';
import 'package:flutter/material.dart';

import '../entities/ball.dart';
import '../entities/player.dart';
import '../entities/team.dart';
import '../enums/match_phase.dart';
import '../enums/player_role.dart';
import '../enums/shot_result.dart';
import 'match_state.dart';
import 'movement_system.dart';
import 'decision_system.dart';
import 'team_behavior_system.dart';
import '../services/match_sound_service.dart';
import '../models/weather_condition.dart';
import '../models/match_event.dart';
import '../models/match_simulation_config.dart';
import '../models/tactical_preset.dart';
import '../enums/boost_type.dart';
import 'subsystems/event_manager.dart';
import 'subsystems/physics_engine.dart';
import 'subsystems/rule_engine.dart';
import 'subsystems/stats_engine.dart';
import 'subsystems/match_logic_system.dart';
import 'subsystems/match_event_logic.dart';
import 'subsystems/goal_system.dart';

/// Ana maç motoru.
///
/// Tüm alt sistemleri orkestre eder: zamanlama, takım davranışı,
/// karar verme, hareket ve top fiziği. Her frame'de [update] çağrılır.
class MatchEngine {
  late final SimTeam homeTeam;
  late final SimTeam awayTeam;
  late final Ball ball;
  late final MatchState state;
  final MatchSimulationConfig config;

  late final MovementSystem _movementSystem;
  late final DecisionSystem _decisionSystem;
  late final TeamBehaviorSystem _behaviorSystem;

  late final EventManager _eventManager;
  late final PhysicsEngine _physicsEngine;
  late final RuleEngine _ruleEngine;
  late final StatsEngine _statsEngine;
  late final MatchLogicSystem _logicSystem;
  late final MatchEventLogic _eventLogic;
  late final GoalSystem _goalSystem;

  final MatchSoundService _soundService = MatchSoundService();

  late final Random _rng;

  bool _finalWhistleBlown = false;
  double _fixedAccumulator = 0.0;
  int _lastRecordedShotSequence = 0;

  // ---- CANLI OLAY KRONOLOJİSİ ----
  List<MatchEvent> get matchEvents => _eventManager.matchEvents;
  void addEvent(MatchEvent event) => _eventManager.addEvent(event);

  // ---- HAVA DURUMU ----
  WeatherCondition weather;

  // ---- SAHA DURUMU ----
  double fieldCondition; // 0.0 (kötü) - 1.0 (mükemmel)

  // ---- EV SAHİBİ AVANTAJI ----
  double homeAdvantage; // 0.0 - 0.2

  // ---- BOOSTS ----
  final Map<int, Map<BoostType, double>> _activeBoosts = {
    0: {}, // Home
    1: {}, // Away
  };

  /// Tüm oyuncuların düz listesi (22 oyuncu).
  List<SimPlayer> get allPlayers => [...homeTeam.players, ...awayTeam.players];

  /// Maç bitti mi?
  bool get isFinished => state.isFinished;

  /// Maç motorunu başlat.
  MatchEngine({
    MatchSimulationConfig? config,
    this.weather = WeatherCondition.clear,
    this.fieldCondition = 1.0,
    this.homeAdvantage = 0.1,
    SimTeam? customHomeTeam,
    SimTeam? customAwayTeam,
  }) : config = config ?? const MatchSimulationConfig() {
    _rng = Random(this.config.seed);
    _movementSystem = MovementSystem();
    _decisionSystem = DecisionSystem(rng: _rng);
    _behaviorSystem = TeamBehaviorSystem(rng: _rng);

    _eventManager = EventManager();
    _physicsEngine = PhysicsEngine();
    _ruleEngine = RuleEngine();
    _statsEngine = StatsEngine(rng: _rng);
    _logicSystem = MatchLogicSystem(rng: _rng);
    _eventLogic = MatchEventLogic(rng: _rng);
    _goalSystem = GoalSystem(rng: _rng);

    homeTeam = customHomeTeam ??
        SimTeam.createDefault(
          teamId: 0,
          name: 'Amedspor',
          color: const Color(0xFF4CAF50), // Yeşil
          rng: _rng,
        );

    awayTeam = customAwayTeam ??
        SimTeam.createDefault(
          teamId: 1,
          name: 'Rakip',
          color: const Color(0xFF2196F3), // Mavi
          rng: _rng,
        );

    ball = Ball();
    state = MatchState(
      totalRealDuration: this.config.totalRealDuration,
      enableExtraTime: this.config.enableExtraTime,
    );

    // Rastgele hava durumu (ama genelde açık)
    _randomizeWeather();

    // Santradan başla
    _performKickoff(homeTeam);
    _addEvent(
      MatchEvent(
        minute: 0,
        type: MatchEventType.kickoff,
        description: 'Maç başladı!',
        teamId: 0,
      ),
    );
  }

  void _randomizeWeather() {
    final roll = _rng.nextDouble();
    if (roll < 0.5) {
      weather = WeatherCondition.clear;
    } else if (roll < 0.75) {
      weather = WeatherCondition.cloudy;
    } else if (roll < 0.88) {
      weather = WeatherCondition.rainy;
    } else if (roll < 0.95) {
      weather = WeatherCondition.stormy;
    } else {
      weather = WeatherCondition.snowy;
    }
  }

  /// Hava durumuna göre top hızı çarpanı.
  double get _weatherSpeedMultiplier =>
      _physicsEngine.getWeatherMultiplier(weather);

  /// Her frame çağrılır. [realDt] gerçek deltaTime (saniye).
  void update(double realDt) {
    final safeDt = realDt.clamp(0.0, config.maxFrameDeltaSeconds);
    if (!config.useFixedTimestep) {
      _step(safeDt);
      return;
    }

    _fixedAccumulator += safeDt;
    var steps = 0;
    while (_fixedAccumulator >= config.fixedStepSeconds &&
        steps < config.maxStepsPerUpdate) {
      _step(config.fixedStepSeconds);
      _fixedAccumulator -= config.fixedStepSeconds;
      steps++;
    }

    if (steps == config.maxStepsPerUpdate) {
      _fixedAccumulator = 0.0;
    }
  }

  void _step(double realDt) {
    if (state.isFinished) {
      if (!_finalWhistleBlown) {
        _soundService.playFinalWhistle();
        _finalWhistleBlown = true;
        _addEvent(
          MatchEvent(
            minute: state.displayMinute,
            type: MatchEventType.fulltime,
            description: 'Maç bitti! ${homeTeam.score} - ${awayTeam.score}',
            teamId: -1,
          ),
        );
      }
      return;
    }

    // Devre arası molası
    if (state.phase == MatchPhase.halftime) {
      state.halftimePauseTimer -= realDt;
      if (state.halftimePauseTimer <= 0) {
        _startSecondHalf();
      }
      return;
    }

    // Gol duraklama kontrolü
    if (state.phase == MatchPhase.goal) {
      state.goalPauseTimer -= realDt;
      if (state.goalPauseTimer <= 0) {
        final scoringTeamId = _lastScoringTeamId;
        final kickoffTeam = scoringTeamId == homeTeam.id ? awayTeam : homeTeam;
        _resetPositions();
        _performKickoff(kickoffTeam);
      }
      state.advanceTime(realDt);
      return;
    }

    // Faul duraklama kontrolü
    if (state.phase == MatchPhase.foul ||
        state.phase == MatchPhase.freeKick ||
        state.phase == MatchPhase.penalty ||
        state.phase == MatchPhase.corner ||
        state.phase == MatchPhase.throwIn ||
        state.phase == MatchPhase.offside) {
      state.foulPauseTimer -= realDt;
      if (state.foulPauseTimer <= 0) {
        _executeSetPiece();
      }
      state.advanceTime(realDt);
      return;
    }

    // timeScale uygulanmış delta
    final double dt = realDt * state.timeScale;

    // 1. Zamanı ilerlet
    state.advanceTime(realDt);
    if (state.isFinished) return;

    // 2. Topa sahip olma istatistiği
    _updatePossession(realDt);

    // 3. Maç fazını belirle
    _updatePhase();

    // 4. Takım davranışlarını güncelle
    _behaviorSystem.update(homeTeam, awayTeam, ball, dt);
    _behaviorSystem.update(awayTeam, homeTeam, ball, dt);

    // 5. Karar sistemini güncelle (sadece toplu takım)
    if (ball.owner != null && !ball.isInFlight) {
      final ownTeam = ball.owner!.teamId == homeTeam.id ? homeTeam : awayTeam;
      final oppTeam = ball.owner!.teamId == homeTeam.id ? awayTeam : homeTeam;
      _decisionSystem.update(
        ownTeam,
        oppTeam,
        ball,
        dt,
        weather: weather,
        matchMinute: state.matchMinute,
      );
      _recordNewShotIfNeeded();
    }

    // 6. Hareket sistemini güncelle
    _movementSystem.update(allPlayers, ball, dt, weather: weather);

    // 7. Koşu mesafesi takibi
    _trackRunningDistances(dt);

    // 8. ÖNCELİKLİ: Şut varsa gol kontrolü yap
    _checkShotOnGoal();

    // 9. Top teslimi kontrolü + FAUL/KART kontrolü
    _handleBallPickup();

    // 10. Ofsayt kontrolü
    _checkOffside();

    // 11. Saha dışı kontrolü (korner/taç)
    _checkOutOfBounds();

    // 12. Boost sürelerini azalt
    _updateBoostTimers(dt);
  }

  void _updateBoostTimers(double dt) {
    _statsEngine.updateBoostTimers(
      dt: dt,
      activeBoosts: _activeBoosts,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
  }

  void _updatePossession(double realDt) {
    _statsEngine.updatePossession(
      realDt: realDt,
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      state: state,
    );
  }

  void _trackRunningDistances(double dt) {
    _statsEngine.trackRunningDistances(
      dt: dt,
      allPlayers: allPlayers,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
  }

  /// İkinci yarıyı başlat.
  void _startSecondHalf() {
    state.phase = MatchPhase.kickoff;
    _resetPositions();
    _performKickoff(awayTeam);
    _addEvent(
      MatchEvent(
        minute: 45,
        type: MatchEventType.kickoff,
        description: 'İkinci yarı başladı!',
        teamId: 1,
      ),
    );
  }

  /// Maç fazını güncelle.
  void _updatePhase() {
    _ruleEngine.updatePhase(state, ball, homeTeam, awayTeam);
  }

  void _checkShotOnGoal() {
    _goalSystem.checkShotOnGoal(
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      state: state,
      statsEngine: _statsEngine,
      weatherSpeedMultiplier: _weatherSpeedMultiplier,
      onResult: (shootingTeam, shooter, result) {
        final isHomeShot = shootingTeam.id == homeTeam.id;
        final defendingTeam = isHomeShot ? awayTeam : homeTeam;
        final goalkeeper = defendingTeam.players.firstWhere(
          (p) => p.role == PlayerRole.gk,
        );

        if (result == ShotResult.goal && ball.y >= 28.0 && ball.y <= 40.0) {
          _recordShotOnTarget(shootingTeam, shooter);
          shootingTeam.score++;
          for (final p in defendingTeam.players) {
            p.morale = (p.morale - 0.1).clamp(0.2, 1.0);
          }
          _lastScoringTeamId = shootingTeam.id;
          _triggerGoalPause(shootingTeam, shooter);
        } else if (result == ShotResult.post) {
          ball.isInFlight = false;
          ball.isShot = false;
          ball.x = isHomeShot ? 102.0 : 3.0;
          ball.y = ball.y + (_rng.nextDouble() - 0.5) * 4.0;
          _addEvent(
            MatchEvent(
              minute: state.displayMinute,
              type: MatchEventType.shot,
              description: 'Direkten döndü!',
              teamId: shootingTeam.id,
            ),
          );
        } else {
          ball.isInFlight = false;
          ball.isShot = false;
          ball.x = isHomeShot ? 100.0 : 5.0;
          ball.y = ball.y.clamp(20.0, 48.0);
          ball.giveTo(goalkeeper);
          _recordShotOnTarget(shootingTeam, shooter);
          defendingTeam.saves++;
          goalkeeper.performanceRating = (goalkeeper.performanceRating + 0.1)
              .clamp(1.0, 10.0);
          _addEvent(
            MatchEvent(
              minute: state.displayMinute,
              type: MatchEventType.save,
              description: 'Kaleci kurtardı! (${goalkeeper.name})',
              teamId: defendingTeam.id,
            ),
          );
        }
      },
    );
  }

  void _recordNewShotIfNeeded() {
    _goalSystem.recordNewShotIfNeeded(
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      state: state,
      statsEngine: _statsEngine,
      homeAdvantage: homeAdvantage,
      weatherSpeedMultiplier: _weatherSpeedMultiplier,
      fieldCondition: fieldCondition,
      lastRecordedShotSequence: _lastRecordedShotSequence,
      setLastRecordedShotSequence: (val) => _lastRecordedShotSequence = val,
      onAddEvent: _addEvent,
    );
  }

  void _recordShotOnTarget(SimTeam shootingTeam, SimPlayer shooter) {
    _statsEngine.recordShotOnTarget(shootingTeam, shooter);
  }

  void _handleBallPickup() {
    _eventLogic.handleBallPickup(
      ball: ball,
      allPlayers: allPlayers,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      minute: state.displayMinute,
      rng: _rng,
      onResolvePassPickup: _resolvePassPickup,
      onExecuteTackle: _executeTackle,
      onCommitFoul: _commitFoul,
      onAddEvent: _addEvent,
    );
  }

  void _resolvePassPickup(SimPlayer receiver) {
    _eventLogic.resolvePassPickup(
      receiver: receiver,
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      minute: state.displayMinute,
      onAddEvent: _addEvent,
    );
  }

  void _executeTackle(SimPlayer tackler, SimPlayer ballHolder) {
    _eventLogic.executeTackle(
      tackler: tackler,
      ballHolder: ballHolder,
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
  }

  void _commitFoul(SimPlayer fouler, SimPlayer fouled) {
    _eventLogic.commitFoul(
      fouler: fouler,
      fouled: fouled,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      minute: state.displayMinute,
      rng: _rng,
      onPlayWhistle: _soundService.playWhistle,
      onAddEvent: _addEvent,
      onTriggerFreeKick: _triggerFreeKick,
    );
  }

  void _checkOffside() {
    _eventLogic.checkOffside(
      ball: ball,
      allPlayers: allPlayers,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      onOffside: _callOffside,
    );
  }

  /// Ofsayt kararı.
  void _callOffside(SimPlayer player) {
    _soundService.playWhistle();
    state.phase = MatchPhase.offside;
    state.pendingSetPiece = MatchPhase.freeKick;
    state.foulPauseTimer = 1.0;

    // Topu rakibe ver
    ball.isInFlight = false;
    ball.isShot = false;
    final oppTeam = player.teamId == homeTeam.id ? awayTeam : homeTeam;
    final gk = oppTeam.players.firstWhere((p) => p.role == PlayerRole.gk);
    ball.resetToCenter();
    ball.giveTo(gk);

    _addEvent(
      MatchEvent(
        minute: state.displayMinute,
        type: MatchEventType.offside,
        description: 'Ofsayt! ${player.name}',
        teamId: player.teamId,
      ),
    );
  }

  /// Serbest vuruş başlat.
  void _triggerFreeKick(
    SimPlayer fouled,
    bool isHomeFoul, {
    FoulType foulType = FoulType.regular,
  }) {
    final foulingTeam = isHomeFoul ? homeTeam : awayTeam;
    final foulingTeamId = foulingTeam.id;

    // Penaltı kontrolü (ceza sahasında faul)
    final inPenaltyArea = _ruleEngine.isPenaltyArea(
      fouled.currentX,
      foulingTeamId,
      homeTeam.id,
    );

    if (inPenaltyArea && foulType == FoulType.regular) {
      // PENALTI!
      state.phase = MatchPhase.penalty;
      state.penaltyAwarded = true;
      state.foulPauseTimer = 2.0;
      _lastFoulReceivedTeamId = fouled.teamId;

      _addEvent(
        MatchEvent(
          minute: state.displayMinute,
          type: MatchEventType.penalty,
          description: 'PENALTI!',
          teamId: fouled.teamId,
        ),
      );
      return;
    }

    // Normal serbest vuruş
    state.phase = MatchPhase.freeKick;
    state.pendingSetPiece = MatchPhase.freeKick;
    state.foulPauseTimer = 1.5;
    _lastFoulReceivedTeamId = fouled.teamId;

    _addEvent(
      MatchEvent(
        minute: state.displayMinute,
        type: MatchEventType.freeKick,
        description: 'Serbest vuruş kazanıldı.',
        teamId: fouled.teamId,
      ),
    );
  }

  /// Duran topu kullan.
  void _executeSetPiece() {
    final phase = state.phase;

    if (phase == MatchPhase.penalty) {
      _executePenalty();
      return;
    }

    // Topu en yakın oyuncuya ver
    final ballTargetTeam = state.phase == MatchPhase.freeKick
        ? (_lastFoulReceivedTeamId == homeTeam.id ? homeTeam : awayTeam)
        : (_lastCornerTeamId == awayTeam.id ? awayTeam : homeTeam);

    _resetBallToNearestPlayerOnTeam(ballTargetTeam);
    state.phase = MatchPhase.kickoff;
  }

  void _executePenalty() {
    _ruleEngine.executePenalty(
      state: state,
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      lastFoulReceivedTeamId: _lastFoulReceivedTeamId,
      minute: state.displayMinute,
      rng: _rng,
      onAddEvent: _addEvent,
      setScoringTeamId: (id) => _lastScoringTeamId = id,
    );
  }

  void _checkOutOfBounds() {
    if (ball.isShot) return;

    if (_physicsEngine.checkOutOfBounds(ball)) {
      // Korner mi? Taç mı?
      if (_physicsEngine.isXAxisExit(ball)) {
        // X ekseninde dışarı (korner veya kale vuruşu)
        if (ball.x < 0.5) {
          // Sol taraftan çıktı
          _handleCornerOrGoalKick(awayTeam, homeTeam);
        } else {
          // Sağ taraftan çıktı
          _handleCornerOrGoalKick(homeTeam, awayTeam);
        }
      } else {
        // Y ekseninde dışarı (taç)
        _handleThrowIn();
      }
    }
  }

  void _handleCornerOrGoalKick(SimTeam attackingTeam, SimTeam defendingTeam) {
    _ruleEngine.handleCornerOrGoalKick(
      state: state,
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      attackingTeam: attackingTeam,
      defendingTeam: defendingTeam,
      minute: state.displayMinute,
      onAddEvent: _addEvent,
      setLastCornerTeamId: (id) => _lastCornerTeamId = id,
    );
  }

  void _handleThrowIn() {
    _ruleEngine.handleThrowIn(
      state: state,
      ball: ball,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      minute: state.displayMinute,
      findNearest: _findNearestPlayerOnTeam,
      onAddEvent: _addEvent,
    );
  }

  int _lastScoringTeamId = 0;
  int _lastFoulReceivedTeamId = 0;
  int? _lastCornerTeamId;

  void _triggerGoalPause(SimTeam scoringTeam, SimPlayer scorer) {
    _logicSystem.triggerGoalPause(
      state: state,
      ball: ball,
      scoringTeam: scoringTeam,
      scorer: scorer,
      onPlayGoalSound: _soundService.playGoal,
      onAddEvent: _addEvent,
    );
  }

  void _resetPositions() {
    _logicSystem.resetPositions(homeTeam, awayTeam);
  }

  void _performKickoff(SimTeam team) {
    _logicSystem.performKickoff(team, ball, state);
  }

  SimPlayer? _findNearestPlayerOnTeam(SimTeam team) {
    return _logicSystem.findNearestPlayerOnTeam(team, ball);
  }

  void applyTemporaryBoost(int teamId, BoostType type) {
    _logicSystem.applyTemporaryBoost(
      teamId: teamId,
      type: type,
      activeBoosts: _activeBoosts,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      minute: state.displayMinute,
      onAddEvent: _addEvent,
    );
  }

  void _resetBallToNearestPlayerOnTeam(SimTeam team) {
    _logicSystem.resetBallToNearestPlayerOnTeam(team, ball);
  }

  /// timeScale'i değiştir.
  void setTimeScale(double scale) {
    state.timeScale = scale.clamp(0.5, 20.0);
  }

  void setTeamTactic(int teamId, TacticalPreset preset) {
    final team = teamId == homeTeam.id ? homeTeam : awayTeam;
    team.applyTacticalPreset(preset);
    _addEvent(
      MatchEvent(
        minute: state.displayMinute,
        type: MatchEventType.substitution,
        description: '${team.name} taktiği ${preset.label} oldu.',
        teamId: team.id,
      ),
    );
  }

  void simulateToEnd() {
    _logicSystem.simulateToEnd(
      state: state,
      fixedStepSeconds: config.fixedStepSeconds,
      step: _step,
      isFinalWhistleBlown: () => _finalWhistleBlown,
    );
  }

  String get resultSummary {
    if (homeTeam.score > awayTeam.score) {
      return '${homeTeam.name} kazandı';
    }
    if (awayTeam.score > homeTeam.score) {
      return '${awayTeam.name} kazandı';
    }
    return 'Berabere';
  }

  void restart() {
    _logicSystem.restart(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      state: state,
      ball: ball,
      matchEvents: matchEvents,
      onRandomizeWeather: _randomizeWeather,
      onPerformKickoff: _performKickoff,
      onAddEvent: _addEvent,
      setFinalWhistleBlown: (val) => _finalWhistleBlown = val,
      setFixedAccumulator: (val) => _fixedAccumulator = val,
      setLastRecordedShotSequence: (val) => _lastRecordedShotSequence = val,
      setLastScoringTeamId: (val) => _lastScoringTeamId = val,
      setLastFoulReceivedTeamId: (val) => _lastFoulReceivedTeamId = val,
      setLastCornerTeamId: (val) => _lastCornerTeamId = val,
    );
  }

  /// Topa sahip olma yüzdesini hesapla.
  double get homePossessionPercent {
    final total = state.homePossessionTime + state.awayPossessionTime;
    if (total == 0) return 50;
    return (state.homePossessionTime / total * 100).clamp(0, 100);
  }

  double get awayPossessionPercent {
    return 100 - homePossessionPercent;
  }

  /// Olay ekle.
  void _addEvent(MatchEvent event) {
    _eventManager.addEvent(event);
  }
}

/// Faul türü.
enum FoulType { regular, tactical, violent }

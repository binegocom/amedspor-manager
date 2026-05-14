import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/navigation_helpers.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/repositories/leaderboard_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lineup_model.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../domain/entities/team.dart';
import '../../domain/engine/match_engine.dart';
import '../../domain/enums/match_phase.dart';
import '../../domain/models/match_simulation_config.dart';
import '../../domain/models/tactical_preset.dart';
import '../../domain/models/weather_condition.dart';
import '../../domain/enums/boost_type.dart';
import '../../domain/models/match_event.dart';
import '../painters/match_painter.dart';
import '../widgets/match_event_tile.dart';

/// 2D Canlı Maç Simülasyonu ekranı.
///
/// [Ticker] ile game loop çalıştırır, [MatchEngine] ile simülasyonu
/// günceller ve [MatchPainter] ile 2D sahayı çizer.
class MatchSimulationScreen extends ConsumerStatefulWidget {
  final String? homeLineupId;
  final String? awayLineupId;

  const MatchSimulationScreen({
    super.key,
    this.homeLineupId,
    this.awayLineupId,
  });

  @override
  ConsumerState<MatchSimulationScreen> createState() =>
      _MatchSimulationScreenState();
}

class _MatchSimulationScreenState extends ConsumerState<MatchSimulationScreen>
    with SingleTickerProviderStateMixin {
  late MatchEngine _engine;
  late final Ticker _ticker;

  Duration _previousTime = Duration.zero;
  bool _isStarted = false;
  bool _isPaused = false;
  bool _showStats = false; // İstatistik paneli toggle
  late int _matchSeed;

  LineupModel? _homeLineupModel;
  LineupModel? _awayLineupModel;
  bool _isLoadingLineups = false;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    if (widget.awayLineupId != null || widget.homeLineupId != null) {
      _loadCustomLineups();
    } else {
      _initEngine();
      _ticker.start();
    }
  }

  void _initEngine() {
    _matchSeed = DateTime.now().millisecondsSinceEpoch;
    final rng = Random(_matchSeed);

    SimTeam? homeTeam;
    SimTeam? awayTeam;

    if (_homeLineupModel != null) {
      homeTeam = SimTeam.createFromLineup(
        teamId: 0,
        lineup: _homeLineupModel!,
        defaultName: 'Benim 11',
        color: const Color(0xFF4CAF50),
        rng: rng,
      );
    }

    if (_awayLineupModel != null) {
      awayTeam = SimTeam.createFromLineup(
        teamId: 1,
        lineup: _awayLineupModel!,
        defaultName: 'Rakip 11',
        color: const Color(0xFFE53935),
        rng: rng,
      );
    }

    _engine = MatchEngine(
      config: MatchSimulationConfig(seed: _matchSeed),
      customHomeTeam: homeTeam,
      customAwayTeam: awayTeam,
    );
  }

  Future<void> _loadCustomLineups() async {
    setState(() {
      _isLoadingLineups = true;
      _loadingError = null;
    });

    try {
      final lineupRepo = LineupRepository();

      if (widget.awayLineupId != null) {
        _awayLineupModel = await lineupRepo.getLineup(widget.awayLineupId!);
      }

      if (widget.homeLineupId != null) {
        _homeLineupModel = await lineupRepo.getLineup(widget.homeLineupId!);
      } else {
        final user = authService.currentUser;
        if (user != null) {
          final list = await lineupRepo
              .watchUserLineups(user.uid, limit: 1)
              .first;
          if (list.isNotEmpty) {
            _homeLineupModel = list.first;
          }
        }
      }

      _initEngine();

      setState(() {
        _isLoadingLineups = false;
      });

      _ticker.start();
    } catch (e) {
      setState(() {
        _isLoadingLineups = false;
        _loadingError = 'Kadrolar yüklenemedi: $e';
      });
    }
  }

  void _onTick(Duration elapsed) {
    if (!_isStarted) {
      _previousTime = elapsed;
      _isStarted = true;
      return;
    }

    final dt = (elapsed - _previousTime).inMicroseconds / 1000000.0;
    _previousTime = elapsed;

    if (_isPaused) {
      return;
    }

    // DeltaTime güvenliği (çok büyük atlamaları engelle)
    final safeDt = dt.clamp(0.0, 0.1);

    _engine.update(safeDt);
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.popOrGo('/home'),
        ),
        title: const Text(
          'Canlı Maç',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingLineups
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryRed),
                    SizedBox(height: 16),
                    Text(
                      'Taraftar Kadroları Sahaya Çıkıyor...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              )
            : _loadingError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.primaryRed,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        onPressed: _loadCustomLineups,
                        child: const Text(
                          'Tekrar Dene',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // --- Skor Panosu ---
                  _buildScoreboard(isDark),

                  const SizedBox(height: 8),

                  // --- Saha ---
                  Expanded(
                    child: Row(
                      children: [
                        // Olay kronolojisi (sol)
                        if (!_showStats) _buildEventTimeline(isDark),
                        // Saha
                        Expanded(child: _buildField()),
                        // İstatistikler (sağ)
                        if (_showStats) _buildStatsPanel(isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --- Kontrol Paneli ---
                  _buildControls(isDark),

                  const SizedBox(height: 4),

                  _buildTacticalBar(isDark),

                  const SizedBox(height: 4),

                  // --- İstatistik toggle butonu ---
                  _buildToggleBar(isDark),

                  const SizedBox(height: 12),

                  // --- Menajer Müdahaleleri (Boosts) ---
                  if (!_engine.isFinished) _buildBoostControls(isDark),

                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _buildBoostControls(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _BoostButton(
              label: 'MEŞALE YAK',
              icon: Icons.local_fire_department_rounded,
              color: Colors.orange,
              onTap: () => _useBoost(BoostType.mesale, 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BoostButton(
              label: 'BASKI KUR',
              icon: Icons.volume_up_rounded,
              color: AppColors.primaryRed,
              onTap: () => _useBoost(BoostType.baski, 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BoostButton(
              label: 'SURLARI KUR',
              icon: Icons.shield_rounded,
              color: AppColors.primaryGreen,
              onTap: () => _useBoost(BoostType.defans, 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BoostButton(
              label: 'DEĞİŞTİR',
              icon: Icons.change_circle_rounded,
              color: AppColors.gold,
              onTap: _openLineupSubstitutionsSheet,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useBoost(BoostType type, int tokenCost) async {
    final user = authService.currentUser;
    if (user == null) return;

    final clubRepo = ClubRepository();
    final club = await clubRepo.getClub(user.uid);

    if (club != null && club.tokens >= tokenCost) {
      await clubRepo.updateResources(user.uid, tokens: -tokenCost);
      _engine.applyTemporaryBoost(0, type);
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Yetersiz Token!')));
      }
    }
  }

  /// Skor panosu widget'ı.
  Widget _buildScoreboard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hava durumu
          _buildWeatherIcon(),
          const SizedBox(width: 8),

          // Ev sahibi
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _engine.homeTeam.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _engine.homeTeam.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Skor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_engine.homeTeam.score}  -  ${_engine.awayTeam.score}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          // Deplasman
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _engine.awayTeam.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _engine.awayTeam.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hava durumu ikonu.
  Widget _buildWeatherIcon() {
    IconData icon;
    Color color;
    switch (_engine.weather) {
      case WeatherCondition.clear:
        icon = Icons.sunny;
        color = Colors.orange;
      case WeatherCondition.cloudy:
        icon = Icons.cloud;
        color = Colors.grey;
      case WeatherCondition.rainy:
        icon = Icons.water_drop;
        color = Colors.blue;
      case WeatherCondition.stormy:
        icon = Icons.thunderstorm;
        color = Colors.deepPurple;
      case WeatherCondition.snowy:
        icon = Icons.ac_unit;
        color = Colors.lightBlue;
    }
    return Icon(icon, color: color, size: 20);
  }

  /// Olay kronolojisi paneli (sol).
  Widget _buildEventTimeline(bool isDark) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              'Olaylar',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _engine.matchEvents.isEmpty
                ? Center(
                    child: Text(
                      'Olay bekleniyor...',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _engine.matchEvents.length,
                    itemBuilder: (ctx, i) {
                      return MatchEventTile(
                        event: _engine.matchEvents[i],
                        isDark: isDark,
                        compact: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// İstatistik paneli (sağ).
  Widget _buildStatsPanel(bool isDark) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const Divider(height: 8),
          _statRow(
            'Top %',
            '${_engine.homePossessionPercent.toStringAsFixed(0)}%',
            '${_engine.awayPossessionPercent.toStringAsFixed(0)}%',
            isDark,
          ),
          _statRow(
            'Şut',
            _engine.homeTeam.totalShots.toString(),
            _engine.awayTeam.totalShots.toString(),
            isDark,
          ),
          _statRow(
            'İs. Şut',
            _engine.homeTeam.shotsOnTarget.toString(),
            _engine.awayTeam.shotsOnTarget.toString(),
            isDark,
          ),
          _statRow(
            'xG',
            _engine.homeTeam.expectedGoals.toStringAsFixed(2),
            _engine.awayTeam.expectedGoals.toStringAsFixed(2),
            isDark,
          ),
          _statRow(
            'Pas %',
            '${(_engine.homeTeam.passAccuracy * 100).toStringAsFixed(0)}%',
            '${(_engine.awayTeam.passAccuracy * 100).toStringAsFixed(0)}%',
            isDark,
          ),
          _statRow(
            'Korner',
            _engine.homeTeam.corners.toString(),
            _engine.awayTeam.corners.toString(),
            isDark,
          ),
          _statRow(
            'Top Kap.',
            _engine.homeTeam.tacklesWon.toString(),
            _engine.awayTeam.tacklesWon.toString(),
            isDark,
          ),
          _statRow(
            'Kurt.',
            _engine.homeTeam.saves.toString(),
            _engine.awayTeam.saves.toString(),
            isDark,
          ),
          _statRow(
            'Sarı K.',
            '${_engine.homeTeam.yellowCards}',
            '${_engine.awayTeam.yellowCards}',
            isDark,
          ),
          _statRow(
            'Koşu',
            _engine.homeTeam.totalDistanceRun.toStringAsFixed(1),
            _engine.awayTeam.totalDistanceRun.toStringAsFixed(1),
            isDark,
          ),
          const SizedBox(height: 4),
          Text(
            'Seed: $_matchSeed',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String homeVal, String awayVal, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              homeVal,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _engine.homeTeam.color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            child: Text(
              awayVal,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _engine.awayTeam.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Saha görselleştirmesi.
  Widget _buildField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: MatchPainter(
            homeTeam: _engine.homeTeam,
            awayTeam: _engine.awayTeam,
            ball: _engine.ball,
            matchState: _engine.state,
            weather: _engine.weather,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  /// Kontrol paneli (dakika, faz, hız butonu).
  Widget _buildControls(bool isDark) {
    final isFinished = _engine.isFinished;
    final timeScale = _engine.state.timeScale;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dakika göstergesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isFinished ? Colors.red.shade700 : const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isFinished)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  isFinished ? 'MS' : "${_engine.state.displayMinute}'",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Devre bilgisi
          if (_engine.state.currentHalf > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _engine.state.isExtraTime
                    ? 'UZ'
                    : '${_engine.state.currentHalf}.Y',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Faz bilgisi
          Expanded(
            child: Text(
              _getPhaseText(_engine.state.phase) +
                  (_engine.state.isExtraTime ? ' (Uzatma)' : ''),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (!isFinished) ...[
            IconButton(
              tooltip: _isPaused ? 'Devam et' : 'Duraklat',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _isPaused = !_isPaused),
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            ),
            for (final scale in const [1.0, 2.0, 5.0, 10.0])
              _speedChip(scale, timeScale),
            IconButton(
              tooltip: 'Sonuca git',
              visualDensity: VisualDensity.compact,
              onPressed: _finishMatch,
              icon: const Icon(Icons.fast_forward),
            ),
          ],

          // Maç bitti ise restart butonu
          if (isFinished) ...[
            IconButton(
              tooltip: 'Rapor',
              visualDensity: VisualDensity.compact,
              onPressed: _showMatchReport,
              icon: const Icon(Icons.analytics_outlined),
            ),
            IconButton(
              tooltip: 'Tekrar',
              visualDensity: VisualDensity.compact,
              onPressed: _restartMatch,
              icon: const Icon(Icons.replay),
            ),
          ],
        ],
      ),
    );
  }

  Widget _speedChip(double scale, double currentScale) {
    final selected = currentScale == scale;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _engine.setTimeScale(scale)),
        child: Container(
          width: 34,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.orange.shade700 : const Color(0xFF37474F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${scale.toStringAsFixed(0)}x',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _tacticSelector(
              teamId: _engine.homeTeam.id,
              teamName: _engine.homeTeam.name,
              preset: _engine.homeTeam.tacticalPreset,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tacticSelector(
              teamId: _engine.awayTeam.id,
              teamName: _engine.awayTeam.name,
              preset: _engine.awayTeam.tacticalPreset,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tacticSelector({
    required int teamId,
    required String teamName,
    required TacticalPreset preset,
    required bool isDark,
  }) {
    return PopupMenuButton<TacticalPreset>(
      tooltip: '$teamName taktiği',
      onSelected: (value) {
        setState(() => _engine.setTeamTactic(teamId, value));
      },
      itemBuilder: (context) => TacticalPreset.values
          .map((value) => PopupMenuItem(value: value, child: Text(value.label)))
          .toList(),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$teamName: ${preset.label}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle bar (olay kronolojisi / istatistik).
  Widget _buildToggleBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showStats = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: !_showStats
                    ? (isDark ? const Color(0xFF37474F) : Colors.grey.shade300)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📋 Olaylar',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showStats = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _showStats
                    ? (isDark ? const Color(0xFF37474F) : Colors.grey.shade300)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📊 İstatistik',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Maçı yeniden başlat.
  void _restartMatch() {
    setState(() {
      _initEngine();
      _isPaused = false;
    });
  }

  void _finishMatch() {
    setState(() {
      _engine.simulateToEnd();
      _isPaused = false;
      _showStats = true;
    });
    _checkRewards();
  }

  Future<void> _checkRewards() async {
    final user = authService.currentUser;
    if (user == null) return;

    final clubRepo = ClubRepository();
    final leaderboardRepo = LeaderboardRepository();
    final isWin = _engine.homeTeam.score > _engine.awayTeam.score;
    final isDraw = _engine.homeTeam.score == _engine.awayTeam.score;

    if (isWin) {
      final rewardCash = 1000 + (Random().nextInt(500));
      await clubRepo.updateResources(user.uid, cash: rewardCash, tokens: 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tebrikler! Galibiyet primi: $rewardCash ₺'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    // Elo Güncellemesi
    try {
      await leaderboardRepo.updateMatchResult(
        userId: user.uid,
        username: user.displayName ?? 'Menajer',
        opponentElo: 1000,
        goalsFor: _engine.homeTeam.score,
        goalsAgainst: _engine.awayTeam.score,
      );

      if (mounted) {
        final resultText = isWin
            ? 'Elo Puanınız Arttı! 📈'
            : (isDraw
                  ? 'Maç Berabere, Elo Puanınız Korundu ➖'
                  : 'Elo Puanınız Düştü 📉');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultText),
            backgroundColor: isWin
                ? Colors.blue
                : (isDraw ? Colors.orange : Colors.red),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Handle Elo update error
    }

    await _updatePlayerStatuses();
  }

  Future<void> _updatePlayerStatuses() async {
    final user = authService.currentUser;
    if (user == null) return;

    final playerRepo = PlayerRepository();
    final List<PlayerModel> playersToUpdate = [];

    // Tüm oyuncularını çek
    final allDbPlayers = await playerRepo
        .watchActivePlayers(ownerId: user.uid)
        .first;

    final homePlayers = [
      ..._engine.homeTeam.players,
      ..._engine.homeTeam.substitutes,
    ];

    // Maçta oynayanların (sahada veya yedekte olanların) id'lerini toplayalım
    final simPlayerMap = {
      for (var p in homePlayers)
        if (p.originalPlayerId != null) p.originalPlayerId!: p,
    };

    for (final dbPlayer in allDbPlayers) {
      bool needsUpdate = false;
      PlayerModel updatedPlayer = dbPlayer;

      final simPlayer = simPlayerMap[dbPlayer.id];

      // Eğer oyuncu bu maçta oynadıysa (simPlayer null değilse)
      if (simPlayer != null) {
        // Sakatlık Kontrolü (Maçta sakatlandıysa)
        if (simPlayer.isInjured) {
          updatedPlayer = updatedPlayer.copyWith(
            injured: true,
            injuryDays: 1 + Random().nextInt(3), // 1 ile 3 maç arası sakatlık
          );
          needsUpdate = true;
        }

        // Kırmızı Kart Kontrolü
        if (simPlayer.redCard > 0) {
          updatedPlayer = updatedPlayer.copyWith(
            suspended: true,
            suspensionMatches: 1, // Kırmızı kart direkt 1 maç ceza
          );
          needsUpdate = true;
        }

        // Sarı Kart Kontrolü
        if (simPlayer.yellowCards > 0 && simPlayer.redCard == 0) {
          final newYellows = dbPlayer.yellowCards + simPlayer.yellowCards;
          if (newYellows >= 4) {
            // 4 sarı kart cezası
            updatedPlayer = updatedPlayer.copyWith(
              yellowCards: 0,
              suspended: true,
              suspensionMatches: 1,
            );
          } else {
            updatedPlayer = updatedPlayer.copyWith(yellowCards: newYellows);
          }
          needsUpdate = true;
        }
      }

      // Her maç sonrası tüm sakat/cezalı oyuncuların sürelerini 1 düşür (yeni sakatlananlar/ceza alanlar hariç)
      // Ancak yeni ceza alanlar zaten yukarida guncellendi, o yüzden needsUpdate false ise düşürebiliriz
      if (!needsUpdate) {
        if (dbPlayer.injured && dbPlayer.injuryDays > 0) {
          final newInjuryDays = dbPlayer.injuryDays - 1;
          updatedPlayer = updatedPlayer.copyWith(
            injuryDays: newInjuryDays,
            injured: newInjuryDays > 0,
          );
          needsUpdate = true;
        }
        if (dbPlayer.suspended && dbPlayer.suspensionMatches > 0) {
          final newSuspensionMatches = dbPlayer.suspensionMatches - 1;
          updatedPlayer = updatedPlayer.copyWith(
            suspensionMatches: newSuspensionMatches,
            suspended: newSuspensionMatches > 0,
          );
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        playersToUpdate.add(updatedPlayer);
      }
    }

    if (playersToUpdate.isNotEmpty) {
      await playerRepo.updatePlayersAfterMatch(playersToUpdate);
    }
  }

  void _showMatchReport() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${_engine.homeTeam.score} - ${_engine.awayTeam.score}  ${_engine.resultSummary}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _reportRow(
                'xG',
                _engine.homeTeam.expectedGoals.toStringAsFixed(2),
                _engine.awayTeam.expectedGoals.toStringAsFixed(2),
              ),
              _reportRow(
                'Şut',
                '${_engine.homeTeam.totalShots}/${_engine.homeTeam.shotsOnTarget}',
                '${_engine.awayTeam.totalShots}/${_engine.awayTeam.shotsOnTarget}',
              ),
              _reportRow(
                'Pas',
                '${(_engine.homeTeam.passAccuracy * 100).toStringAsFixed(0)}%',
                '${(_engine.awayTeam.passAccuracy * 100).toStringAsFixed(0)}%',
              ),
              _reportRow(
                'Korner',
                _engine.homeTeam.corners.toString(),
                _engine.awayTeam.corners.toString(),
              ),
              _reportRow(
                'Faul',
                _engine.homeTeam.foulsCommitted.toString(),
                _engine.awayTeam.foulsCommitted.toString(),
              ),
              _reportRow(
                'Top kapma',
                _engine.homeTeam.tacklesWon.toString(),
                _engine.awayTeam.tacklesWon.toString(),
              ),
              _reportRow(
                'Koşu km',
                _engine.homeTeam.totalDistanceRun.toStringAsFixed(1),
                _engine.awayTeam.totalDistanceRun.toStringAsFixed(1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.popOrGo('/home'),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _reportRow(String label, String home, String away) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              home,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(label, textAlign: TextAlign.center)),
          SizedBox(
            width: 54,
            child: Text(
              away,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseText(MatchPhase phase) {
    switch (phase) {
      case MatchPhase.kickoff:
        return '⚽ Santra';
      case MatchPhase.attacking:
        return '🔥 Hücum';
      case MatchPhase.defending:
        return '🛡️ Savunma';
      case MatchPhase.transition:
        return '🔄 Geçiş';
      case MatchPhase.looseBall:
        return '⚡ Top Boşta';
      case MatchPhase.shot:
        return '🎯 Şut!';
      case MatchPhase.goal:
        return '🎉 GOOOL!';
      case MatchPhase.corner:
        return '🚩 Korner';
      case MatchPhase.throwIn:
        return '📤 Taç';
      case MatchPhase.freeKick:
        return '🆓 Serbest Vuruş';
      case MatchPhase.penalty:
        return '⚡ PENALTI!';
      case MatchPhase.offside:
        return '🚩 Ofsayt';
      case MatchPhase.foul:
        return '🟨 Faul';
      case MatchPhase.halftime:
        return '⏸️ Devre Arası';
      case MatchPhase.extraTime:
        return '⏱ Uzatma';
      case MatchPhase.penaltyShootout:
        return '🎯 Penaltı Atışları';
      case MatchPhase.finished:
        return '🏁 Maç Bitti';
    }
  }

  void _performSubstitution(int subIndex, int mainIndex) {
    final team = _engine.homeTeam;
    if (team.substitutionsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm oyuncu değişikliği haklarınızı kullandınız!'),
        ),
      );
      return;
    }

    setState(() {
      team.substitutionsLeft--;
      final subPlayer = team.substitutes[subIndex];
      final mainPlayer = team.players[mainIndex];

      // Değişim koordinatları
      subPlayer.homeX = mainPlayer.homeX;
      subPlayer.homeY = mainPlayer.homeY;
      subPlayer.currentX = mainPlayer.currentX;
      subPlayer.currentY = mainPlayer.currentY;
      subPlayer.targetX = mainPlayer.targetX;
      subPlayer.targetY = mainPlayer.targetY;
      subPlayer.stamina = 1.0; // Fresh legs

      team.players[mainIndex] = subPlayer;
      team.substitutes[subIndex] = mainPlayer;

      _engine.addEvent(
        MatchEvent(
          minute: _engine.state.displayMinute,
          type: MatchEventType.substitution,
          description:
              '🔁 DEĞİŞİKLİK: ${subPlayer.name} GİRDİ, ${mainPlayer.name} ÇIKTI.',
          teamId: 0,
        ),
      );
    });

    Navigator.pop(context); // Sheet/Dialog kapat
  }

  void _showBenchSelectionDialog(int mainPlayerIndex) {
    final team = _engine.homeTeam;
    if (team.substitutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yedek kulübenizde oyuncu bulunmuyor!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kalan Değişiklik Hakkı: ${team.substitutionsLeft}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Oyuna Girecek Yedeği Seçin:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: team.substitutes.length,
                  itemBuilder: (context, idx) {
                    final sub = team.substitutes[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryRed,
                        child: Text(
                          '${sub.number}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        sub.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Rol: ${sub.role.name.toUpperCase()} • OVR: ${sub.overallRating.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.gold,
                      ),
                      onTap: () => _performSubstitution(idx, mainPlayerIndex),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLineupSubstitutionsSheet() {
    final team = _engine.homeTeam;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Sahadaki Oyuncular (Değiştirmek İçin Tıklayın)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Değişiklik Hakkı: ${team.substitutionsLeft}/3',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: team.players.length,
                  itemBuilder: (context, idx) {
                    final p = team.players[idx];
                    final stamPct = (p.stamina * 100).toStringAsFixed(0);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryGreen,
                        child: Text(
                          '${p.number}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            'Rol: ${p.role.name.toUpperCase()} • Stamina: ',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '%$stamPct',
                            style: TextStyle(
                              color: p.stamina > 0.5
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.refresh,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showBenchSelectionDialog(idx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BoostButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

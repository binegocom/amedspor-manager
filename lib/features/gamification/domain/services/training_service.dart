import '../../../../data/services/gamification_service.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/player_repository.dart';
import '../models/training_drill.dart';

/// Antrenman sonucu
class TrainingResult {
  final PlayerModel updatedPlayer;
  final Object? levelUpResult;

  const TrainingResult({required this.updatedPlayer, this.levelUpResult});
}

class TrainingService {
  final PlayerRepository _playerRepository = PlayerRepository();
  final GamificationService _gamificationService = GamificationService();

  /// Antrenman yaptır ve XP kazandır
  Future<TrainingResult?> trainPlayer({
    required String userId,
    required PlayerModel player,
    required TrainingDrill drill,
  }) async {
    // 1. Fitness kontrolü (yeterli değilse antrenman yapamaz)
    if (player.fitness < 10) return null;

    // 2. İstatistik artışını hesapla
    final updatedPlayer = _applyDrillGains(player, drill);

    // 3. Firestore'a kaydet
    await _playerRepository.updatePlayer(updatedPlayer);

    // 4. XP kazandır (mükemmel puan kontrolü ile)
    final isPerfectScore = _checkPerfectScore(updatedPlayer, drill);
    await _gamificationService.awardTrainingXp(
      userId: userId,
      drillType: drill.skillName,
      perfectScore: isPerfectScore,
    );

    return TrainingResult(updatedPlayer: updatedPlayer, levelUpResult: null);
  }

  /// Mükemmel puan kontrolü (oyuncu istatistiği 95+ ise)
  bool _checkPerfectScore(PlayerModel player, TrainingDrill drill) {
    switch (drill) {
      case TrainingDrill.shooting:
        return player.shooting >= 95;
      case TrainingDrill.passing:
        return player.passing >= 95;
      case TrainingDrill.defending:
        return player.defending >= 95;
      case TrainingDrill.dribbling:
        return player.dribbling >= 95;
      case TrainingDrill.positioning:
        return player.positioning >= 95;
      case TrainingDrill.composure:
        return player.composure >= 95;
    }
  }

  /// Drill tipine göre istatistik artışı uygula
  PlayerModel _applyDrillGains(PlayerModel player, TrainingDrill drill) {
    final fitnessCost = _drillFitnessCost(drill);
    final statGain = _calculateStatGain(_drillStatValue(player, drill));

    final newFitness = (player.fitness - fitnessCost).clamp(0, 100);
    final newStatValue = (_drillStatValue(player, drill) + statGain).clamp(
      0,
      99,
    );

    final updated = _buildUpdatedPlayer(
      player,
      drill,
      newStatValue,
      newFitness,
    );
    return updated;
  }

  /// Drill tipine göre fitness maliyeti
  int _drillFitnessCost(TrainingDrill drill) {
    switch (drill) {
      case TrainingDrill.shooting:
        return 5;
      case TrainingDrill.passing:
        return 3;
      case TrainingDrill.defending:
        return 4;
      case TrainingDrill.dribbling:
        return 3;
      case TrainingDrill.positioning:
        return 2;
      case TrainingDrill.composure:
        return 2;
    }
  }

  /// Drill tipine göre ilgili istatistik değerini al
  int _drillStatValue(PlayerModel player, TrainingDrill drill) {
    switch (drill) {
      case TrainingDrill.shooting:
        return player.shooting;
      case TrainingDrill.passing:
        return player.passing;
      case TrainingDrill.defending:
        return player.defending;
      case TrainingDrill.dribbling:
        return player.dribbling;
      case TrainingDrill.positioning:
        return player.positioning;
      case TrainingDrill.composure:
        return player.composure;
    }
  }

  /// Güncellenmiş oyuncu modelini oluştur
  PlayerModel _buildUpdatedPlayer(
    PlayerModel player,
    TrainingDrill drill,
    int newStatValue,
    int newFitness,
  ) {
    switch (drill) {
      case TrainingDrill.shooting:
        return player.copyWith(
          shooting: newStatValue,
          fitness: newFitness,
          rating: player.calculateRating(),
        );
      case TrainingDrill.passing:
        return player.copyWith(
          passing: newStatValue,
          fitness: newFitness,
          rating: player.calculateRating(),
        );
      case TrainingDrill.defending:
        return player.copyWith(
          defending: newStatValue,
          fitness: newFitness,
          rating: player.calculateRating(),
        );
      case TrainingDrill.dribbling:
        return player.copyWith(
          dribbling: newStatValue,
          fitness: newFitness,
          rating: player.calculateRating(),
        );
      case TrainingDrill.positioning:
        return player.copyWith(
          positioning: newStatValue,
          fitness: newFitness,
          rating: player.calculateRating(),
        );
      case TrainingDrill.composure:
        return player.copyWith(
          composure: newStatValue,
          fitness: newFitness,
          rating: player.calculateRating(),
        );
    }
  }

  /// İstatistik artış miktarını hesapla (yüksek istatistik = daha az artış)
  int _calculateStatGain(int currentStat) {
    if (currentStat < 50) return 3;
    if (currentStat < 70) return 2;
    if (currentStat < 85) return 1;
    return 0; // 85+ istatistikler artık artmaz
  }

  /// Toplu antrenman (birden fazla drill)
  Future<List<TrainingResult?>> trainMultiple({
    required String userId,
    required PlayerModel player,
    required List<TrainingDrill> drills,
  }) async {
    final results = <TrainingResult?>[];
    var currentPlayer = player;

    for (final drill in drills) {
      final result = await trainPlayer(
        userId: userId,
        player: currentPlayer,
        drill: drill,
      );
      results.add(result);
      if (result != null) {
        currentPlayer = result.updatedPlayer;
      } else {
        break; // Fitness yetersiz
      }
    }

    return results;
  }
}

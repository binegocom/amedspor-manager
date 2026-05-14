import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/player_repository.dart';
import '../models/training_drill.dart';

class TrainingService {
  final PlayerRepository _playerRepository = PlayerRepository();

  /// Executes a training session for a player.
  /// Consumes energy and improves specific stats based on the drill.
  Future<void> trainPlayer({
    required String userId,
    required PlayerModel player,
    required TrainingDrill drill,
  }) async {
    // 1. Check Energy (Mock check for now, should use UserRepo)
    // const int energyCost = 10;

    // 2. Calculate Stat Gains
    final updatedPlayer = _applyDrillGains(player, drill);

    // 3. Update Firestore
    await _playerRepository.updatePlayer(updatedPlayer);

    // 4. Update Club XP/Level if needed
    // await _clubRepository.addXp(userId, 50);
  }

  PlayerModel _applyDrillGains(PlayerModel player, TrainingDrill drill) {
    PlayerModel updated;
    switch (drill) {
      case TrainingDrill.shooting:
        updated = player.copyWith(
          shooting: (player.shooting + 2).clamp(0, 99),
          fitness: (player.fitness - 5).clamp(0, 100),
        );
        break;
      case TrainingDrill.passing:
        updated = player.copyWith(
          passing: (player.passing + 2).clamp(0, 99),
          fitness: (player.fitness - 3).clamp(0, 100),
        );
        break;
      case TrainingDrill.defending:
        updated = player.copyWith(
          defending: (player.defending + 2).clamp(0, 99),
          fitness: (player.fitness - 4).clamp(0, 100),
        );
        break;
      case TrainingDrill.dribbling:
        updated = player.copyWith(
          dribbling: (player.dribbling + 2).clamp(0, 99),
          fitness: (player.fitness - 3).clamp(0, 100),
        );
        break;
      case TrainingDrill.positioning:
        updated = player.copyWith(
          positioning: (player.positioning + 2).clamp(0, 99),
          fitness: (player.fitness - 2).clamp(0, 100),
        );
        break;
      case TrainingDrill.composure:
        updated = player.copyWith(
          composure: (player.composure + 2).clamp(0, 99),
          fitness: (player.fitness - 2).clamp(0, 100),
        );
        break;
    }

    return updated.copyWith(rating: updated.calculateRating());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/premium_card.dart';
import '../../domain/services/training_service.dart';
import '../../domain/models/training_drill.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerRepository = PlayerRepository();
    final trainingService = TrainingService();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('ANTRENMAN SAHASI', style: AppTextStyles.h3),
      ),
      body: StreamBuilder<List<PlayerModel>>(
        stream: playerRepository.watchActivePlayers(
          ownerId: authService.currentUser?.uid,
        ),
        builder: (context, snapshot) {
          final players = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return _PlayerTrainingCard(
                player: player,
                onTrain: (drill) => trainingService.trainPlayer(
                  userId: authService.currentUser?.uid ?? '',
                  player: player,
                  drill: drill,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlayerTrainingCard extends StatelessWidget {
  final PlayerModel player;
  final Function(TrainingDrill) onTrain;

  const _PlayerTrainingCard({required this.player, required this.onTrain});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              _PositionBadge(position: player.position),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name, style: AppTextStyles.h3),
                    Text(
                      'Güç: ${player.rating} | Kondisyon: %${player.fitness}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatCircle(value: player.rating),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DrillButton(
                  label: 'ŞUT',
                  icon: Icons.sports_soccer_rounded,
                  onTap: () => onTrain(TrainingDrill.shooting),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DrillButton(
                  label: 'PAS',
                  icon: Icons.swap_horiz_rounded,
                  onTap: () => onTrain(TrainingDrill.passing),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DrillButton(
                  label: 'SAVUNMA',
                  icon: Icons.shield_rounded,
                  onTap: () => onTrain(TrainingDrill.defending),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DrillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final String position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Text(
        position,
        style: const TextStyle(
          color: AppColors.primaryRed,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final int value;

  const _StatCircle({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

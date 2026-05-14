import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/player_model.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../domain/models/training_drill.dart';
import '../controllers/training_controller.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  @override
  Widget build(BuildContext context) {
    final trainingState = ref.watch(trainingControllerProvider);
    final notifier = ref.read(trainingControllerProvider.notifier);

    // Hata dinleyicisi
    ref.listen<TrainingState>(trainingControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryRed,
            content: Text(next.error!),
          ),
        );
        notifier.clearError();
      }
    });

    final pendingCount = trainingState.pendingUpdates.length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Ekrandan çıkılırken eğer eşitleme yapılmamış mutasyon varsa topluca Firebase'e yaz (Delta-Sync)
        if (pendingCount > 0) {
          notifier.syncBatchToFirestore();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.darkBackground,
          title: const Text('ANTRENMAN SAHASI', style: AppTextStyles.h3),
          actions: [
            // Eşitleme Durumu / Kaydet Butonu
            if (pendingCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: trainingState.isLoading ? null : () {
                    notifier.syncBatchToFirestore();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primaryGreen,
                        content: Text('✨ Gelişim verileri topluca Firebase\'e kaydedildi!'),
                      ),
                    );
                  },
                  icon: trainingState.isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: Text(
                    'KAYDET ($pendingCount)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryGreen.withValues(alpha: 0.6), size: 14),
                      const SizedBox(width: 4),
                      Text('Senkronize', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.6), fontSize: 10)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0.05),
                AppColors.darkBackground,
              ],
            ),
          ),
          child: trainingState.isLoading && trainingState.players.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : trainingState.players.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sports_kabaddi_rounded,
                              size: 72,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Antrenman sahası boş.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'A Takım kadronuzda henüz idmana çıkacak aktif oyuncu bulunmuyor. Transfer pazarından kulübünüze yeni efsaneler imzalayarak hemen antrenmanlara başlayabilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'YENİLE',
                              type: AppButtonType.secondary,
                              height: 36,
                              onTap: () => notifier.loadPlayers(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: trainingState.players.length,
                      itemBuilder: (context, index) {
                        final player = trainingState.players[index];
                        final isPending = trainingState.pendingUpdates.containsKey(player.id);

                        return _PlayerTrainingCard(
                          player: player,
                          isPending: isPending,
                          onTrain: (drill) {
                            notifier.trainPlayer(player, drill);
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _PlayerTrainingCard extends StatelessWidget {
  final PlayerModel player;
  final bool isPending;
  final Function(TrainingDrill) onTrain;

  const _PlayerTrainingCard({
    required this.player,
    required this.isPending,
    required this.onTrain,
  });

  @override
  Widget build(BuildContext context) {
    // Glassmorphism kurumsal kimlik tasarımı
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      backgroundColor: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending ? AppColors.gold.withValues(alpha: 0.5) : Colors.white10,
            width: isPending ? 1.5 : 1.0,
          ),
          gradient: isPending
              ? LinearGradient(
                  colors: [AppColors.gold.withValues(alpha: 0.05), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          Text(player.name, style: AppTextStyles.h3),
                          if (isPending) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Kondisyon: ',
                            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.8), fontSize: 11),
                          ),
                          Text(
                            '%${player.fitness}',
                            style: TextStyle(
                              color: player.fitness > 50 
                                  ? AppColors.primaryGreen 
                                  : (player.fitness > 20 ? Colors.orangeAccent : AppColors.primaryRed),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatCircle(value: player.rating, isPending: isPending),
              ],
            ),
            const SizedBox(height: 16),
            
            // Skill breakdown rows
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniSkillVal(label: 'Şut', val: player.shooting),
                  _MiniSkillVal(label: 'Pas', val: player.passing),
                  _MiniSkillVal(label: 'Savunma', val: player.defending),
                  _MiniSkillVal(label: 'Dribling', val: player.dribbling),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Drill Butonları
            Row(
              children: [
                Expanded(
                  child: _DrillButton(
                    label: 'ŞUT ÇALIŞ',
                    icon: Icons.sports_soccer_rounded,
                    color: AppColors.primaryRed,
                    disabled: player.fitness <= 10,
                    onTap: () => onTrain(TrainingDrill.shooting),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _DrillButton(
                    label: 'PAS DRİLİ',
                    icon: Icons.swap_horiz_rounded,
                    color: Colors.blue.shade400,
                    disabled: player.fitness <= 10,
                    onTap: () => onTrain(TrainingDrill.passing),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _DrillButton(
                    label: 'SAVUNMA',
                    icon: Icons.shield_rounded,
                    color: AppColors.primaryGreen,
                    disabled: player.fitness <= 10,
                    onTap: () => onTrain(TrainingDrill.defending),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSkillVal extends StatelessWidget {
  final String label;
  final int val;

  const _MiniSkillVal({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.muted.withValues(alpha: 0.7), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          '$val',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DrillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _DrillButton({
    required this.label,
    required this.icon,
    required this.color,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: disabled ? AppColors.card.withValues(alpha: 0.3) : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: disabled ? Colors.transparent : color.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: disabled ? AppColors.muted : color),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9, 
                  fontWeight: FontWeight.w900,
                  color: disabled ? AppColors.muted : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final String position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final isGk = position == 'GK';
    final color = isGk ? AppColors.gold : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        position,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final int value;
  final bool isPending;

  const _StatCircle({required this.value, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPending ? AppColors.gold.withValues(alpha: 0.15) : AppColors.darkBackground,
        border: Border.all(
          color: isPending ? AppColors.gold : AppColors.gold.withValues(alpha: 0.5), 
          width: isPending ? 2.5 : 1.5,
        ),
        boxShadow: isPending
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.2), blurRadius: 8)]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: isPending ? Colors.white : AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'OVR',
              style: TextStyle(
                color: isPending ? AppColors.gold : AppColors.muted,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

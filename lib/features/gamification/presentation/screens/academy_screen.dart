import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/models/youth_player_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/repositories/youth_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_card.dart';

class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = authService.currentUser;
    if (user == null) return const SizedBox.shrink();

    final clubAsync = ref.watch(currentClubStreamProvider);
    final youthPlayersAsync = ref.watch(youthPlayersStreamProvider);

    final club = clubAsync.value;
    final academyLevel = club?.youthAcademyLevel ?? 1;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text(
          "SUR'UN ÇOCUKLARI AKADEMİSİ",
          style: AppTextStyles.h3,
        ),
      ),
      body: youthPlayersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (err, stack) => Center(
          child: Text('Akademi yüklenemedi: $err',
              style: const TextStyle(color: AppColors.primaryRed)),
        ),
        data: (players) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _ScoutControlCard(
                    academyLevel: academyLevel,
                    onScout: () => _handleScouting(context, user.uid, academyLevel),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('GENÇ YETENEKLER', style: AppTextStyles.h3),
                ),
              ),
              if (players.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Akademide henüz genç yetenek yok.\nGözlemci göndererek keşfe başlayın.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final player = players[index];
                      return _YouthPlayerCard(
                        player: player,
                        onPromote: () => _promotePlayer(context, user.uid, player),
                      );
                    }, childCount: players.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleScouting(BuildContext context, String clubId, int academyLevel) async {
    final youthRepo = YouthRepository();
    final names = ['Baran', 'Azad', 'Rojhat', 'Mirza', 'Beritan', 'Diren', 'Şiyar', 'Zana'];
    final positions = ['FWD', 'MID', 'DEF', 'GK'];

    // Seviyeye göre reyting artışı
    final currentBase = 40 + (academyLevel * 3);
    final potentialBase = 75 + (academyLevel * 2);

    final newPlayer = YouthPlayerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: names[Random().nextInt(names.length)],
      age: 15 + Random().nextInt(3),
      position: positions[Random().nextInt(positions.length)],
      potentialRating: min(99, potentialBase + Random().nextInt(15)),
      currentRating: min(80, currentBase + Random().nextInt(12)),
      scoutedAt: DateTime.now(),
      isReadyForPromotion: Random().nextBool(), // Mock ready state
    );

    await youthRepo.addYouthPlayer(clubId, newPlayer);
  }

  Future<void> _promotePlayer(
    BuildContext context,
    String clubId,
    YouthPlayerModel youth,
  ) async {
    final playerRepo = PlayerRepository();
    final youthRepo = YouthRepository();

    // Create senior player from youth data
    final seniorPlayer = PlayerModel(
      id: youth.id,
      ownerId: clubId,
      name: youth.name,
      position: youth.position,
      number: 10 + Random().nextInt(89), // Random number
      rating: youth.currentRating,
      active: true,
      age: youth.age,
      shooting: youth.position == 'FWD'
          ? youth.currentRating + 10
          : youth.currentRating,
      defending: youth.position == 'DEF'
          ? youth.currentRating + 10
          : youth.currentRating,
      passing: youth.position == 'MID'
          ? youth.currentRating + 10
          : youth.currentRating,
    );

    // Save to senior squad
    await playerRepo.createPlayer(seniorPlayer);

    // Remove from academy
    await youthRepo.removeYouthPlayer(clubId, youth.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text('${youth.name} artık A takımda!'),
        ),
      );
    }
  }
}

class _ScoutControlCard extends StatelessWidget {
  final int academyLevel;
  final VoidCallback onScout;

  const _ScoutControlCard({required this.academyLevel, required this.onScout});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.card,
      child: Column(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.primaryGreen,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text('GÖZLEMCİ GÖNDER', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Altyapı Akademisi: Seviye $academyLevel',
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diyarbakır sokaklarında yeni yetenekler keşfet.\nAkademi seviyesi sayesinde +%${academyLevel * 5} Reyting Bonusu aktif!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 20),
          AppButton(text: 'GÖZLEMCİ BAŞLAT (500 ₺)', onTap: onScout),
        ],
      ),
    );
  }
}

class _YouthPlayerCard extends StatelessWidget {
  final YouthPlayerModel player;
  final VoidCallback onPromote;

  const _YouthPlayerCard({required this.player, required this.onPromote});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${player.currentRating}',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${player.position} | Potansiyel: ${player.potentialRating}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (player.isReadyForPromotion)
            SizedBox(
              width: 100,
              child: AppButton(text: 'A TAKIM', onTap: onPromote),
            )
          else
            const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.muted,
              size: 20,
            ),
        ],
      ),
    );
  }
}

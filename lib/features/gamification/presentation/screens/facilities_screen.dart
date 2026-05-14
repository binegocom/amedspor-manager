import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class FacilitiesScreen extends ConsumerWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = authService.currentUser;
    final clubRepository = ClubRepository();

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('KULÜP TESİSLERİ', style: AppTextStyles.h3),
      ),
      body: StreamBuilder<ClubModel?>(
        stream: clubRepository.watchClub(user.uid),
        builder: (context, snapshot) {
          final club = snapshot.data;
          if (club == null) return const Center(child: CircularProgressIndicator());

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _FacilityCard(
                title: 'Stadyum',
                description: 'Daha fazla bilet geliri ve taraftar desteği sağlar.',
                level: club.stadiumLevel,
                icon: Icons.stadium_rounded,
                upgradeCost: 5000 * club.stadiumLevel,
                onUpgrade: () => _upgradeFacility(club, 'stadium'),
              ),
              const SizedBox(height: 16),
              _FacilityCard(
                title: 'Antrenman Merkezi',
                description: 'Antrenmanlarda daha fazla gelişim puanı kazandırır.',
                level: club.trainingLevel,
                icon: Icons.fitness_center_rounded,
                upgradeCost: 3000 * club.trainingLevel,
                onUpgrade: () => _upgradeFacility(club, 'training'),
              ),
              const SizedBox(height: 16),
              _FacilityCard(
                title: 'Sağlık Merkezi',
                description: 'Oyuncuların kondisyonu daha hızlı toparlanır.',
                level: club.medicalLevel,
                icon: Icons.medical_services_rounded,
                upgradeCost: 4000 * club.medicalLevel,
                onUpgrade: () => _upgradeFacility(club, 'medical'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _upgradeFacility(ClubModel club, String type) async {
    final clubRepository = ClubRepository();
    int cost = 0;
    ClubModel updatedClub;

    switch (type) {
      case 'stadium':
        cost = 5000 * club.stadiumLevel;
        updatedClub = club.copyWith(stadiumLevel: club.stadiumLevel + 1);
      case 'training':
        cost = 3000 * club.trainingLevel;
        updatedClub = club.copyWith(trainingLevel: club.trainingLevel + 1);
      case 'medical':
        cost = 4000 * club.medicalLevel;
        updatedClub = club.copyWith(medicalLevel: club.medicalLevel + 1);
      default:
        return;
    }

    if (club.cash >= cost) {
      await clubRepository.updateClub(updatedClub.copyWith(cash: club.cash - cost));
    }
  }
}

class _FacilityCard extends StatelessWidget {
  final String title;
  final String description;
  final int level;
  final IconData icon;
  final int upgradeCost;
  final VoidCallback onUpgrade;

  const _FacilityCard({
    required this.title,
    required this.description,
    required this.level,
    required this.icon,
    required this.upgradeCost,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3),
                    Text('Seviye $level', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$upgradeCost ₺', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              SizedBox(
                width: 120,
                child: AppButton(
                  text: 'YÜKSELT',
                  onTap: onUpgrade,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

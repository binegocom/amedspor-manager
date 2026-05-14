import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class ScenarioScreen extends StatelessWidget {
  const ScenarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('DİRENİŞ GÖREVLERİ', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ScenarioCard(
            title: 'Geri Dönüş (Comeback)',
            description: 'Maçın 75. dakikası, 2-0 geridesin. Maçı en az beraberliğe taşı!',
            reward: '2000 ₺ + 10 Token',
            difficulty: 'ZOR',
            isCompleted: false,
          ),
          const SizedBox(height: 16),
          _ScenarioCard(
            title: '10 Kişiyle Direniş',
            description: 'Kırmızı kart gördün, skor 1-1. Son 20 dakikada kaleni koru!',
            reward: '1500 ₺ + 5 Token',
            difficulty: 'ORTA',
            isCompleted: true,
          ),
          const SizedBox(height: 16),
          _ScenarioCard(
            title: 'Derbi Zaferi',
            description: 'Ezeli rakibine karşı 0-0 giden maçta son dakikada golü bul!',
            reward: '5000 ₺ + 20 Token',
            difficulty: 'EFSANEVİ',
            isCompleted: false,
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final String title;
  final String description;
  final String reward;
  final String difficulty;
  final bool isCompleted;

  const _ScenarioCard({
    required this.title,
    required this.description,
    required this.reward,
    required this.difficulty,
    required this.isCompleted,
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
              _DifficultyBadge(label: difficulty),
              const Spacer(),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ÖDÜL', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(reward, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              SizedBox(
                width: 120,
                child: AppButton(
                  text: isCompleted ? 'TEKRAR OYNA' : 'MEYDAN OKU',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String label;
  const _DifficultyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    if (label == 'ORTA') color = Colors.orange;
    if (label == 'ZOR') color = AppColors.primaryRed;
    if (label == 'EFSANEVİ') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

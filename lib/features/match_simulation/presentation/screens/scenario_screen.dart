import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({super.key});

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  final Set<String> _completedTitles = {
    '10 Kişiyle Direniş',
  }; // Varsayılan tamamlanan
  bool _isProcessing = false;
  String? _activeScenario;

  Future<void> _playScenario(
    BuildContext context,
    ClubModel club,
    String title,
    int cashReward,
    int tokenReward,
    String difficulty,
  ) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _activeScenario = title;
    });

    // Simülasyon hissi için 1.5 saniye bekle
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Dinamik Kadro/Kulüp Gücü Hesaplama
      // Antrenman düzeyi, İtibar ve Stadyum kalitesi doğrudan gücü etkiler
      int teamPower =
          50 +
          (club.trainingLevel * 4) +
          (club.reputation * 2) +
          (club.stadiumLevel * 2);

      int reqPower = 55;
      if (difficulty == 'ORTA') reqPower = 55;
      if (difficulty == 'ZOR') reqPower = 65;
      if (difficulty == 'EFSANEVİ') reqPower = 75;

      bool isVictory = false;

      if (teamPower >= reqPower) {
        // Kadro üstünlüğü var: %85 İhtimalle Zafer
        isVictory = Random().nextDouble() < 0.85;
      } else {
        // Kadro zayıf (Underdog): Sürpriz yapma şansı %30
        isVictory = Random().nextDouble() < 0.30;
      }

      if (!context.mounted) return;

      if (isVictory) {
        final clubRepo = ClubRepository();
        // Ödülleri kasaya ekle
        await clubRepo.updateClub(
          club.copyWith(
            cash: club.cash + cashReward,
            tokens: club.tokens + tokenReward,
          ),
        );

        if (!context.mounted) return;

        setState(() {
          _completedTitles.add(title);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Text(
              '✨ DİRENİŞ KIRILMADI! $title senaryosu başarıyla geçildi. (Gücünüz: $teamPower) +$cashReward ₺ ve +$tokenReward Token kazandınız!',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Senaryo Başarısız
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryRed,
            content: Text(
              '❌ Senaryo Başarısız! Takım gücünüz ($teamPower), rakibin direncini kırmaya yetmedi (Gereken: $reqPower). Tesisleri yükseltip tekrar deneyin!',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Senaryo hatası: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _activeScenario = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final clubRepo = ClubRepository();

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          title: const Text('DİRENİŞ GÖREVLERİ', style: AppTextStyles.h3),
        ),
        body: const Center(
          child: Text(
            'Giriş yapılması gerekiyor',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('DİRENİŞ GÖREVLERİ', style: AppTextStyles.h3),
      ),
      body: StreamBuilder<ClubModel?>(
        stream: clubRepo.watchClub(user.uid),
        builder: (context, snapshot) {
          final club = snapshot.data;
          if (club == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Anlık Güç Göstergesi
          int currentPower =
              50 +
              (club.trainingLevel * 4) +
              (club.reputation * 2) +
              (club.stadiumLevel * 2);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Kulüp Bakiye ve Güç Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'KASANIZ:',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${club.cash} ₺',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TAHMİNİ KADRO GÜCÜ:',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$currentPower OVR',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildScenarioCard(
                context,
                club,
                title: 'Geri Dönüş (Comeback)',
                description:
                    'Maçın 75. dakikası, 2-0 geridesin. Maçı en az beraberliğe taşı!',
                rewardText: '2000 ₺ + 10 Token',
                cashReward: 2000,
                tokenReward: 10,
                difficulty: 'ZOR',
              ),
              const SizedBox(height: 16),
              _buildScenarioCard(
                context,
                club,
                title: '10 Kişiyle Direniş',
                description:
                    'Kırmızı kart gördün, skor 1-1. Son 20 dakikada kaleni koru!',
                rewardText: '1500 ₺ + 5 Token',
                cashReward: 1500,
                tokenReward: 5,
                difficulty: 'ORTA',
              ),
              const SizedBox(height: 16),
              _buildScenarioCard(
                context,
                club,
                title: 'Derbi Zaferi',
                description:
                    'Ezeli rakibine karşı 0-0 giden maçta son dakikada golü bul!',
                rewardText: '5000 ₺ + 20 Token',
                cashReward: 5000,
                tokenReward: 20,
                difficulty: 'EFSANEVİ',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context,
    ClubModel club, {
    required String title,
    required String description,
    required String rewardText,
    required int cashReward,
    required int tokenReward,
    required String difficulty,
  }) {
    final isCompleted = _completedTitles.contains(title);
    final isThisLoading = _isProcessing && _activeScenario == title;

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
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryGreen,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ÖDÜL',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rewardText,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 130,
                child: AppButton(
                  text: isCompleted ? 'TAMAMLANDI' : 'MEYDAN OKU',
                  color: isCompleted ? AppColors.muted : AppColors.primaryGreen,
                  isLoading: isThisLoading,
                  onTap: () {
                    if (isCompleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$title senaryosunun ödülü zaten alındı.',
                          ),
                        ),
                      );
                    } else {
                      _playScenario(
                        context,
                        club,
                        title,
                        cashReward,
                        tokenReward,
                        difficulty,
                      );
                    }
                  },
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
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

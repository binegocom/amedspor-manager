import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_card.dart';
import '../controllers/sponsorship_controller.dart';

class SponsorshipScreen extends ConsumerStatefulWidget {
  const SponsorshipScreen({super.key});

  @override
  ConsumerState<SponsorshipScreen> createState() => _SponsorshipScreenState();
}

class _SponsorshipScreenState extends ConsumerState<SponsorshipScreen> {
  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(currentClubStreamProvider);
    final state = ref.watch(sponsorshipControllerProvider);
    final notifier = ref.read(sponsorshipControllerProvider.notifier);

    ref.listen<SponsorshipState>(sponsorshipControllerProvider, (
      previous,
      next,
    ) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryRed,
            content: Text(next.error!),
          ),
        );
        notifier.clearMessages();
      }

      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Text(next.successMessage!),
          ),
        );
        notifier.clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('SPONSORLUK ANLAŞMALARI', style: AppTextStyles.h3),
      ),
      body: clubAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Hata: $err',
            style: const TextStyle(color: AppColors.primaryRed),
          ),
        ),
        data: (club) {
          if (club == null) {
            return const Center(
              child: Text(
                'Kulüp bilgisi bulunamadı.',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionHeader(title: 'AKTİF SPONSORLAR'),
              const SizedBox(height: 12),
              if (state.activeSponsors.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Henüz aktif bir sponsorunuz yok.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                ...state.activeSponsors.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ActiveSponsorCard(
                      name: s.name,
                      weeklyPay: s.weeklyPay,
                      winBonus: s.winBonus,
                      timeLeft: s.timeLeft,
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              const _SectionHeader(title: 'YENİ TEKLİFLER'),
              const SizedBox(height: 12),
              if (state.availableOffers.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Tüm sponsorluk tekliflerini değerlendirdiniz.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                ...state.availableOffers.map(
                  (o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOfferCard(club, o, state, notifier),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(
    ClubModel club,
    SponsorItem offer,
    SponsorshipState state,
    SponsorshipNotifier notifier,
  ) {
    return PremiumCard(
      backgroundColor: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer.name, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _StatRow(label: 'Haftalık', value: '${offer.weeklyPay} ₺'),
          _StatRow(label: 'Bonus', value: '${offer.winBonus} ₺'),
          _StatRow(label: 'Süre', value: '${offer.durationWeeks} Hafta'),
          const SizedBox(height: 16),
          AppButton(
            text: 'İMZALA',
            color: AppColors.primaryGreen,
            isLoading: state.isProcessing,
            onTap: () => notifier.signSponsor(club, offer),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ActiveSponsorCard extends StatelessWidget {
  final String name;
  final int weeklyPay;
  final int winBonus;
  final String timeLeft;

  const _ActiveSponsorCard({
    required this.name,
    required this.weeklyPay,
    required this.winBonus,
    required this.timeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: AppTextStyles.h3)),
              Text(
                timeLeft,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(label: 'Haftalık Ödeme', value: '$weeklyPay ₺'),
          _StatRow(label: 'Galibiyet Primi', value: '$winBonus ₺'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

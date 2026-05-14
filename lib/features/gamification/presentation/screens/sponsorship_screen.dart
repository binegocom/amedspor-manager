import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class SponsorshipScreen extends StatelessWidget {
  const SponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('SPONSORLUK ANLAŞMALARI', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionHeader(title: 'AKTİF SPONSORLAR'),
          const SizedBox(height: 12),
          _ActiveSponsorCard(
            name: 'DİYARBAKIR TİCARET ODASI',
            weeklyPay: 15000,
            winBonus: 5000,
            timeLeft: '2 Hafta',
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'YENİ TEKLİFLER'),
          const SizedBox(height: 12),
          _OfferCard(
            name: 'AZAD PETROL',
            weeklyPay: 20000,
            winBonus: 2500,
            duration: 4,
          ),
          const SizedBox(height: 12),
          _OfferCard(
            name: 'SUR İNŞAAT',
            weeklyPay: 12000,
            winBonus: 8000,
            duration: 8,
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
      style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }
}

class _ActiveSponsorCard extends StatelessWidget {
  final String name;
  final int weeklyPay;
  final int winBonus;
  final String timeLeft;

  const _ActiveSponsorCard({required this.name, required this.weeklyPay, required this.winBonus, required this.timeLeft});

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
              Text(timeLeft, style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
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

class _OfferCard extends StatelessWidget {
  final String name;
  final int weeklyPay;
  final int winBonus;
  final int duration;

  const _OfferCard({required this.name, required this.weeklyPay, required this.winBonus, required this.duration});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _StatRow(label: 'Haftalık', value: '$weeklyPay ₺'),
          _StatRow(label: 'Bonus', value: '$winBonus ₺'),
          _StatRow(label: 'Süre', value: '$duration Hafta'),
          const SizedBox(height: 16),
          AppButton(text: 'İMZALA', onTap: () {}),
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
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

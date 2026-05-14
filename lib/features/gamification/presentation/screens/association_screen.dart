import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class AssociationScreen extends StatelessWidget {
  const AssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('TARAFTAR DERNEKLERİ', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AssociationCard(
            name: 'BARİKAT',
            members: 1250,
            level: 15,
            description: 'Amedspor\'un her zaman yanındaki barikat.',
            isJoined: true,
          ),
          const SizedBox(height: 16),
          _AssociationCard(
            name: 'DİREN HA',
            members: 850,
            level: 10,
            description: 'Direnişin ve mücadelenin tribündeki sesi.',
            isJoined: false,
          ),
          const SizedBox(height: 16),
          _AssociationCard(
            name: 'MOR BARİKAT',
            members: 450,
            level: 8,
            description: 'Kadın taraftarların güçlü sesi.',
            isJoined: false,
          ),
        ],
      ),
    );
  }
}

class _AssociationCard extends StatelessWidget {
  final String name;
  final int members;
  final int level;
  final String description;
  final bool isJoined;

  const _AssociationCard({
    required this.name,
    required this.members,
    required this.level,
    required this.description,
    required this.isJoined,
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.h2),
                    Text('$members Üye | Seviye $level', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (isJoined)
                const _JoinedBadge()
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: isJoined ? 'DERNEĞE GİT' : 'KATIL',
                  onTap: () {},
                  color: isJoined ? AppColors.primaryGreen : AppColors.primaryRed,
                ),
              ),
              if (isJoined) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.gold),
                  onPressed: () {},
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinedBadge extends StatelessWidget {
  const _JoinedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'ÜYESİN',
        style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ClubHeader extends StatelessWidget {
  final String clubName;
  final String managerName;
  final String? emblemUrl;
  final int level;

  const ClubHeader({
    super.key,
    required this.clubName,
    required this.managerName,
    this.emblemUrl,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildEmblem(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(clubName, style: AppTextStyles.h2),
                  const SizedBox(width: 8),
                  _LevelBadge(level: level),
                ],
              ),
              Text(
                'Menajer: $managerName',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmblem() {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: emblemUrl != null
          ? Image.network(emblemUrl!)
          : Image.asset('assets/images/app_icon.png'), // Default Amedspor icon
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        'LVL $level',
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

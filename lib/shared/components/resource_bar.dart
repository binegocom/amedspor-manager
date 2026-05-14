import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ResourceBar extends StatelessWidget {
  final int tokens;
  final int cash;
  final int energy;

  const ResourceBar({
    super.key,
    required this.tokens,
    required this.cash,
    required this.energy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResourceItem(
            icon: Icons.monetization_on_rounded,
            value: '$tokens',
            color: AppColors.gold,
          ),
          const _Divider(),
          _ResourceItem(
            icon: Icons.account_balance_wallet_rounded,
            value: _formatCash(cash),
            color: AppColors.primaryGreen,
          ),
          const _Divider(),
          _ResourceItem(
            icon: Icons.flash_on_rounded,
            value: '$energy',
            color: AppColors.primaryRed,
          ),
        ],
      ),
    );
  }

  String _formatCash(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _ResourceItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white10,
    );
  }
}

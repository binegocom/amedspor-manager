import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PremiumBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const PremiumBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ?? AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color?.withValues(alpha: 0.3) ?? AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor ?? color ?? AppColors.primaryGreen),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: textColor ?? color ?? AppColors.primaryGreen,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

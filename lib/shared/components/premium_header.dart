import 'package:flutter/material.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';

class PremiumHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const PremiumHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showBackButton) ...[
              IconButton(
                onPressed: () {
                  context.popOrGo('/home');
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.card,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Official Amedspor PNG Logo Premium Glow Kapsülü
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shield_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h2.copyWith(
                  letterSpacing: -0.8,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

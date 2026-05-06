import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../../shared/components/app_button.dart';

class MaintenanceScreen extends StatelessWidget {
  final VoidCallback? onAdminBypass;

  const MaintenanceScreen({super.key, this.onAdminBypass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build_circle_rounded, color: AppColors.primaryRed, size: 80),
              const SizedBox(height: 24),
              const Text('Bakımdayız', style: AppTextStyles.h1),
              const SizedBox(height: 16),
              const Text(
                'Size daha iyi bir deneyim sunabilmek için sistemlerimizi güncelliyoruz. Lütfen daha sonra tekrar deneyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              if (onAdminBypass != null) ...[
                const SizedBox(height: 40),
                AppButton(
                  text: 'ADMİN GİRİŞİ (BYPASS)',
                  onTap: onAdminBypass,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

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
              const Icon(Icons.system_update_rounded, color: AppColors.primaryGreen, size: 80),
              const SizedBox(height: 24),
              const Text('Güncelleme Gerekli', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Uygulamanın yeni ve zorunlu bir sürümü yayınlandı. Devam etmek için lütfen mağazadan uygulamayı güncelleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 40),
              // In a real app, this would redirect to the App Store or Google Play
              const CircularProgressIndicator(color: AppColors.primaryRed),
            ],
          ),
        ),
      ),
    );
  }
}

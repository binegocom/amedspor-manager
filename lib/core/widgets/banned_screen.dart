import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

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
              const Icon(Icons.gavel_rounded, color: AppColors.errorRed, size: 80),
              const SizedBox(height: 24),
              const Text('Hesabınız Askıya Alındı', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Topluluk kurallarımızı ihlal ettiğiniz için hesabınız geçici veya kalıcı olarak durdurulmuştur. Destek için iletişime geçebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

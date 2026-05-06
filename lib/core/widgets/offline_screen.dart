import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

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
              const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 80),
              const SizedBox(height: 24),
              const Text('Bağlantı Yok', style: AppTextStyles.h1),
              const SizedBox(height: 16),
              const Text(
                'Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: AppColors.primaryRed),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import 'package:go_router/go_router.dart';

class AccountDisabledScreen extends StatelessWidget {
  const AccountDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.block_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Hesabınız Askıya Alındı',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Topluluk kurallarını ihlal ettiğiniz gerekçesiyle hesabınız dondurulmuştur. Bunun bir hata olduğunu düşünüyorsanız destek ekibiyle iletişime geçin.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'GİRİŞ EKRANINA DÖN',
                onTap: () async {
                  await authService.signOut();
                  if (context.mounted) context.go('/login');
                },
                type: AppButtonType.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

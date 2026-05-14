import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

class LoginRequiredView extends StatelessWidget {
  final String title;
  final String message;

  const LoginRequiredView({
    super.key,
    this.title = 'Üyelik Gerekli',
    this.message = 'Bu özelliği kullanmak, içerik paylaşmak ve ödüller kazanmak için Amedspor taraftar hesabına giriş yapmalısın.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.1), width: 8),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryRed, size: 64),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 40),
            AppButton(
              text: 'GİRİŞ YAP / ÜYE OL',
              onTap: () => context.push('/login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Anasayfaya Dön', style: TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

void showLoginRequiredModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.primaryRed, size: 48),
            const SizedBox(height: 16),
            const Text('Üyelik Gerekli', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            const Text(
              'Bu işlemi yapmak, içerikleri paylaşmak ve puan kazanmak için Amedspor taraftar hesabına giriş yapmalısın.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'GİRİŞ YAP',
              onTap: () {
                Navigator.pop(context);
                context.push('/login');
              },
            ),
          ],
        ),
      );
    },
  );
}

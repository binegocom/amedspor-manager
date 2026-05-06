import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_button.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _launchStore() async {
    String url = '';
    if (kIsWeb) {
      url = 'https://amedspor.com.tr';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      url = 'https://play.google.com/store/apps/details?id=com.example.amedspor_app';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      url = 'https://apps.apple.com/app/id6444855555'; // Placeholder
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

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
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.update_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Güncelleme Gerekli',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Uygulamanın yeni sürümü yayında! En iyi deneyim ve yeni özellikler için lütfen güncelleyin.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'ŞİMDİ GÜNCELLE',
                onTap: _launchStore,
                type: AppButtonType.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_button.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? webUrl;
  final String? androidUrl;
  final String? iosUrl;

  const ForceUpdateScreen({
    super.key,
    this.title = 'Güncelleme Gerekli',
    this.message =
        'Uygulamanın yeni sürümü yayında. En iyi deneyim ve yeni özellikler için lütfen güncelleyin.',
    this.webUrl,
    this.androidUrl,
    this.iosUrl,
  });

  Future<void> _launchStore() async {
    final url = _updateUrl();
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? _updateUrl() {
    if (kIsWeb) return webUrl ?? 'https://amedspor.com.tr';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidUrl ??
          'https://play.google.com/store/apps/details?id=com.example.amedspor_app';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosUrl ?? 'https://apps.apple.com/app/id6444855555';
    }
    return webUrl ?? 'https://amedspor.com.tr';
  }

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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.update_rounded,
                  size: 64,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 48),
              Text(title, style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.muted,
                ),
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

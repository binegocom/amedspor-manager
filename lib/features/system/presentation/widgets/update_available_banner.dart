import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';

class UpdateAvailableBanner extends StatelessWidget {
  final String title;
  final String message;
  final String? webUrl;
  final String? androidUrl;
  final String? iosUrl;
  final VoidCallback onDismiss;

  const UpdateAvailableBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
    this.webUrl,
    this.androidUrl,
    this.iosUrl,
  });

  Future<void> _launchUpdate() async {
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
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primaryGreen),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: Icon(Icons.system_update_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _launchUpdate,
                  child: const Text('GÜNCELLE'),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

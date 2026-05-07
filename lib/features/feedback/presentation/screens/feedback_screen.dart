import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../data/models/user_feedback_model.dart';
import '../../../../data/repositories/feedback_repository.dart';
import 'package:flutter/foundation.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  final _repository = FeedbackRepository();
  String _selectedType = 'bug';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _types = [
    {'id': 'bug', 'label': 'Hata Bildir', 'icon': Icons.bug_report_rounded},
    {'id': 'suggestion', 'label': 'Öneri / İstek', 'icon': Icons.lightbulb_rounded},
    {'id': 'account', 'label': 'Hesap Sorunu', 'icon': Icons.person_off_rounded},
    {'id': 'other', 'label': 'Diğer', 'icon': Icons.more_horiz_rounded},
  ];

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir mesaj yazın.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = authService.currentUser;
      final packageInfo = await PackageInfo.fromPlatform();

      final feedback = UserFeedbackModel(
        id: '',
        userId: user?.uid ?? 'anonymous',
        email: user?.email ?? 'anonymous',
        type: _selectedType,
        message: _messageController.text.trim(),
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        appVersion: packageInfo.version,
        createdAt: DateTime.now(),
      );

      await _repository.submitFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri bildiriminiz için teşekkürler!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Column(
        children: [
          const PremiumHeader(title: 'Geri Bildirim', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konu Seçin',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: _types.map((type) {
                      final isSelected = _selectedType == type['id'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type['id']),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryGreen : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryGreen : Colors.white10,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type['icon'],
                                  color: isSelected ? Colors.white : AppColors.muted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  type['label'],
                                  style: AppTextStyles.label.copyWith(
                                    color: isSelected ? Colors.white : AppColors.muted,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Mesajınız',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Sorunu veya önerinizi detaylıca açıklayın...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      fillColor: AppColors.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  AppButton(
                    text: 'GÖNDER',
                    onTap: _isSubmitting ? null : _submit,
                    type: AppButtonType.primary,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

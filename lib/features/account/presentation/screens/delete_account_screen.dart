import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;
  final _confirmController = TextEditingController();

  Future<void> _deleteAccount() async {
    if (_confirmController.text != 'SIL') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen onaylamak için SIL yazın.')),
      );
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final user = authService.currentUser;
      if (user != null) {
        // 1. Mark user as disabled in Firestore (optional, but good for logs)
        await firestoreService.users.doc(user.uid).update({'disabled': true, 'deletedAt': FieldValue.serverTimestamp()});
        
        // 2. Delete Auth User
        await user.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hesabınız başarıyla silindi.')),
          );
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: Hesabınızı silmek için yakın zamanda giriş yapmış olmalısınız. Lütfen çıkış yapıp tekrar girin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PremiumHeader(title: 'Hesabı Sil'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Bu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecektir.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Onaylamak için aşağıdaki kutuya "SIL" yazın:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'SIL',
                      hintStyle: const TextStyle(color: Colors.white24),
                      fillColor: AppColors.card,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  AppButton(
                    text: 'HESABIMI KALICI OLARAK SİL',
                    onTap: _isDeleting ? null : _deleteAccount,
                    type: AppButtonType.error,
                    isLoading: _isDeleting,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'VAZGEÇ',
                    onTap: () => Navigator.pop(context),
                    type: AppButtonType.secondary,
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

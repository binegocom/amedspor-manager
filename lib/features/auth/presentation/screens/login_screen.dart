import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routePath = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final userRepository = UserRepository();

  bool isRegisterMode = false;
  bool obscurePassword = true;
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (isSubmitting) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Email ve şifre alanları boş olamaz.'),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      if (isRegisterMode) {
        await authService.registerWithEmail(email: email, password: password);
      } else {
        await authService.signInWithEmail(email: email, password: password);
      }

      if (!mounted) return;

      final user = authService.currentUser;
      if (user == null) {
        context.go('/login');
        return;
      }

      final appUser = await userRepository.getUser(user.uid);

      if (!mounted) return;
      context.go(appUser == null ? '/profile-setup' : '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Giriş hatası: $e'),
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Sifre sifirlama icin email adresini yaz.'),
        ),
      );
      return;
    }

    try {
      await authService.sendPasswordResetEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text(
            'Sifre sifirlama baglantisi email adresine gonderildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Sifre sifirlama hatasi: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),

              const SizedBox(height: 28),

              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.primaryRed,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.28),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: Text(
                  isRegisterMode ? 'Hesap Oluştur' : 'Giriş Yap',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  isRegisterMode
                      ? 'Dijital tribüne katıl, kadronu paylaş.'
                      : 'Kadro kurmak ve sohbete katılmak için giriş yap.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
                ),
              ),

              const SizedBox(height: 34),

              AppTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              AppTextField(
                controller: passwordController,
                label: 'Şifre',
                icon: Icons.lock_rounded,
                obscureText: obscurePassword,
                suffix: IconButton(
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ),

              if (!isRegisterMode) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      'Şifremi unuttum',
                      style: TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              AppButton(
                text: isRegisterMode ? 'KAYIT OL' : 'GİRİŞ YAP',
                isLoading: isSubmitting,
                onTap: _submit,
              ),

              const SizedBox(height: 26),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRegisterMode
                        ? 'Zaten hesabın var mı?'
                        : 'Hesabın yok mu?',
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => isRegisterMode = !isRegisterMode);
                    },
                    child: Text(
                      isRegisterMode ? 'Giriş yap' : 'Kayıt ol',
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


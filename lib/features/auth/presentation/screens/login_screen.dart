import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
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
  bool _kvkkAccepted = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (isSubmitting) return;

    HapticFeedback.mediumImpact();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Strict Email Regex Validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Lütfen geçerli bir e-posta adresi giriniz.'),
        ),
      );
      return;
    }

    // Strict Password Length Validation
    if (password.length < 6) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Şifreniz en az 6 karakter uzunluğunda olmalıdır.'),
        ),
      );
      return;
    }

    if (isRegisterMode && !_kvkkAccepted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Kayıt olmak için kullanıcı sözleşmesini kabul etmelisiniz.'),
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
        HapticFeedback.heavyImpact();
        setState(() => isSubmitting = false);
        return;
      }

      final appUser = await userRepository.getUser(user.uid);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      context.go(appUser == null ? '/profile-setup' : '/home');
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => isSubmitting = false);

      // Cleaned error formatting for user visibility
      String errMsg = 'Giriş başarısız. Lütfen bilgilerinizi kontrol ediniz.';
      if (e.toString().contains('invalid-credential') || e.toString().contains('wrong-password')) {
        errMsg = 'E-posta adresi veya şifre hatalı.';
      } else if (e.toString().contains('email-already-in-use')) {
        errMsg = 'Bu e-posta adresi zaten kullanımda.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text(errMsg),
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    HapticFeedback.mediumImpact();
    final email = emailController.text.trim();

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Şifre sıfırlama için geçerli bir e-posta adresi yazınız.'),
        ),
      );
      return;
    }

    try {
      await authService.sendPasswordResetEmail(email);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text(
            'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Şifre sıfırlama talebi gönderilemedi.'),
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
                isPassword: obscurePassword,
                suffixIcon: IconButton(
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

              if (isRegisterMode) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _kvkkAccepted,
                        activeColor: AppColors.primaryRed,
                        side: const BorderSide(color: AppColors.muted),
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _kvkkAccepted = v ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _kvkkAccepted = !_kvkkAccepted);
                        },
                        child: const Text(
                          'Kullanıcı sözleşmesini ve gizlilik politikasını okudum, kabul ediyorum.',
                          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 16),
              ],

              AppButton(
                text: isRegisterMode ? 'KAYIT OL' : 'GİRİŞ YAP',
                isLoading: isSubmitting,
                onTap: (isRegisterMode && !_kvkkAccepted) ? null : _submit,
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
                      HapticFeedback.lightImpact();
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


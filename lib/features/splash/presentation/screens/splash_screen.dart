import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/gamification/gamification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routePath = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final userRepository = UserRepository();
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 3), _navigateToNext);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    _navigationTimer?.cancel();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;

    try {
      final onboardingCompleted = await appStateService.isOnboardingCompleted();

      if (!onboardingCompleted) {
        if (!mounted) return;
        context.go('/onboarding');
        return;
      }

      final user = authService.currentUser;

      if (user != null) {
        // 🔥 Update daily login streak & award XP (Safely)
        try {
          await GamificationService().updateDailyLoginStreak(user.uid);
        } catch (e) {
          debugPrint('Splash: Gamification update failed: $e');
        }

        final appUser = await userRepository.getUser(user.uid);

        if (!mounted) return;
        if (appUser == null) {
          context.go('/profile-setup');
        } else {
          context.go('/home');
        }
        return;
      }

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      debugPrint('Splash Navigation Error: $e');
      if (mounted) {
        context.go('/home'); // Safety fallback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/splash_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Loading indicator at bottom
              const Positioned(
                bottom: 80,
                child: Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE53935),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class OnboardingGuard {
  static Future<String?> redirect(String location) async {
    // Tanıtım ekranları tamamen devredışı bırakıldı, doğrudan geçişe izin ver.
    final bool isOnboardingRoute = location == '/onboarding';
    if (isOnboardingRoute) {
      return '/home';
    }
    return null;
  }
}

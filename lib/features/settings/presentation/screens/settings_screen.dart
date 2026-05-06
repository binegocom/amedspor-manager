import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../main.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/premium_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String routePath = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool matchNotifications = true;
  bool chatNotifications = true;
  bool likeNotifications = true;
  bool darkMode = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => isLoading = true);
    final user = authService.currentUser;
    final themeMode = await appStateService.isDarkMode();
    
    if (user != null) {
      final userData = await userRepository.getUser(user.uid);
      if (userData != null) {
        setState(() {
          matchNotifications = userData.notificationPrefs['match'] ?? true;
          chatNotifications = userData.notificationPrefs['chat'] ?? true;
          likeNotifications = userData.notificationPrefs['like'] ?? true;
          darkMode = themeMode;
          isLoading = false;
        });
        return;
      }
    }

    setState(() {
      darkMode = themeMode;
      isLoading = false;
    });
  }

  Future<void> _updatePrefs() async {
    final user = authService.currentUser;
    if (user == null) return;

    await userRepository.updateNotificationPrefs(user.uid, {
      'match': matchNotifications,
      'chat': chatNotifications,
      'like': likeNotifications,
    });
  }

  void _logout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE53935),
                size: 44,
              ),
              const SizedBox(height: 16),
              const Text(
                'Çıkış yapılsın mı?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hesabından çıkış yapacaksın. Daha sonra tekrar giriş yapabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await authService.signOut();

                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (!mounted) return;
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Çıkış Yap',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(color: Color(0xFFB3B3B3)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Dil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.check_circle_rounded, color: Color(0xFF0F6A3D)),
          title: Text(
            'Turkce',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'Uygulama dili',
            style: TextStyle(color: Color(0xFFB3B3B3)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tamam',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = authService.currentUser?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Sifre sifirlama icin hesaba bagli email bulunamadi.'),
        ),
      );
      return;
    }

    try {
      await authService.sendPasswordResetEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text(
            'Sifre sifirlama baglantisi email adresine gonderildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onBack: () => context.go('/profile')),
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Hesap'),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.person_rounded,
                      title: 'Profili Düzenle',
                      subtitle: 'Kullanıcı adı, şehir ve profil bilgileri',
                      onTap: () => context.go('/profile-setup'),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_rounded,
                      title: 'Şifre Değiştir',
                      subtitle: 'Hesap güvenliğini güncelle',
                      onTap: _sendPasswordReset,
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Bildirimler'),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      icon: Icons.sports_soccer_rounded,
                      title: 'Maç Bildirimleri',
                      subtitle: 'Maç başlangıcı ve önemli anlar',
                      value: matchNotifications,
                      onChanged: (value) {
                        setState(() => matchNotifications = value);
                        _updatePrefs();
                      },
                    ),
                    _SwitchTile(
                      icon: Icons.forum_rounded,
                      title: 'Sohbet Bildirimleri',
                      subtitle: 'Yeni mesaj ve oda aktiviteleri',
                      value: chatNotifications,
                      onChanged: (value) {
                        setState(() => chatNotifications = value);
                        _updatePrefs();
                      },
                    ),
                    _SwitchTile(
                      icon: Icons.thumb_up_rounded,
                      title: 'Beğeni Bildirimleri',
                      subtitle: 'Kadro ve yorum beğenileri',
                      value: likeNotifications,
                      onChanged: (value) {
                        setState(() => likeNotifications = value);
                        _updatePrefs();
                      },
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Uygulama'),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Koyu Tema',
                      subtitle: 'Amedspor koyu tema deneyimi',
                      value: darkMode,
                      onChanged: (value) {
                        setState(() => darkMode = value);
                        AmedsporApp.of(context).setDarkMode(value);
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'Dil',
                      subtitle: 'Türkçe',
                      onTap: _showLanguageDialog,
                    ),
                    _SettingsTile(
                      icon: Icons.info_rounded,
                      title: 'Hakkında',
                      subtitle: 'Uygulama bilgileri ve sürüm',
                      onTap: () => context.go('/about'),
                    ),
                    _SettingsTile(
                      icon: Icons.feedback_rounded,
                      title: 'Geri Bildirim',
                      subtitle: 'Hata bildir veya öneri gönder',
                      onTap: () => context.push('/feedback'),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(title: 'Güvenlik'),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.report_rounded,
                      title: 'Raporlarım',
                      subtitle: 'Gönderdiğin şikayetleri görüntüle',
                      onTap: () => context.go('/reports'),
                    ),
                    _SettingsTile(
                      icon: Icons.person_off_rounded,
                      title: 'Engellenen Kişiler',
                      subtitle: 'Engellediğin kullanıcıları yönet',
                      onTap: () => context.push('/blocked-users'),
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Gizlilik ve Kullanım Şartları',
                      subtitle: 'Platform kuralları',
                      onTap: () => context.go('/policy'),
                    ),
                    _SettingsTile(
                      icon: Icons.no_accounts_rounded,
                      title: 'Hesabımı Sil',
                      subtitle: 'Hesabını ve verilerini kalıcı olarak sil',
                      onTap: () => context.push('/delete-account'),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          side: const BorderSide(color: AppColors.primaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Çıkış Yap',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const SizedBox(width: 4),
        const Text(
          'Ayarlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryGreen,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          trailing: Switch(
            value: value,
            activeThumbColor: AppColors.primaryRed,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

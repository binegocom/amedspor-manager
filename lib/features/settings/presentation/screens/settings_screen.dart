import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/navigation_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../main.dart';
import '../../../../shared/components/premium_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String routePath = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> notificationPrefs = Map<String, bool>.from(
    _defaultNotificationPrefs,
  );

  bool darkMode = true;
  bool isLoading = true;
  bool isSavingPrefs = false;

  static const Map<String, bool> _defaultNotificationPrefs = {
    'match': true,
    'matchStart': true,
    'goal': true,
    'lineup': true,
    'prediction': true,
    'chat': true,
    'comment': true,
    'like': true,
    'mission': true,
  };

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
        notificationPrefs
          ..clear()
          ..addAll(_defaultNotificationPrefs)
          ..addAll(userData.notificationPrefs);
      }
    }

    if (!mounted) return;
    setState(() {
      darkMode = themeMode;
      isLoading = false;
    });
  }

  Future<void> _updatePref(String key, bool value) async {
    final previous = notificationPrefs[key] ?? true;
    setState(() {
      notificationPrefs[key] = value;
      isSavingPrefs = true;
    });

    final user = authService.currentUser;
    if (user == null) {
      setState(() => isSavingPrefs = false);
      context.go('/login');
      return;
    }

    try {
      await userRepository.updateNotificationPrefs(user.uid, notificationPrefs);
      if (!mounted) return;
      setState(() => isSavingPrefs = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        notificationPrefs[key] = previous;
        isSavingPrefs = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Bildirim tercihi kaydedilemedi: $e'),
        ),
      );
    }
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
                color: AppColors.primaryRed,
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
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    await authService.signOut();

                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    if (!mounted) return;
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(sheetContext);
                },
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(color: AppColors.muted),
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
          leading: Icon(
            Icons.check_circle_rounded,
            color: AppColors.primaryGreen,
          ),
          title: Text(
            'Türkçe',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'Uygulama dili',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tamam',
              style: TextStyle(color: AppColors.primaryRed),
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
          backgroundColor: AppColors.primaryRed,
          content: Text('Şifre sıfırlama için hesaba bağlı email bulunamadı.'),
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
            'Şifre sıfırlama bağlantısı email adresine gönderildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Şifre sıfırlama hatası: $e'),
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
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onBack: () => context.popOrGo('/profile')),
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
                    _NotificationSectionHeader(isSaving: isSavingPrefs),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      icon: Icons.sports_soccer_rounded,
                      title: 'Maç Özeti',
                      subtitle: 'Maç programı ve genel maç duyuruları',
                      value: notificationPrefs['match'] ?? true,
                      onChanged: (value) => _updatePref('match', value),
                    ),
                    _SwitchTile(
                      icon: Icons.timer_rounded,
                      title: 'Maç Başlıyor',
                      subtitle: 'Başlama saati yaklaşan maç hatırlatmaları',
                      value: notificationPrefs['matchStart'] ?? true,
                      onChanged: (value) => _updatePref('matchStart', value),
                    ),
                    _SwitchTile(
                      icon: Icons.sports_score_rounded,
                      title: 'Gol ve Önemli Anlar',
                      subtitle: 'Gol, kart ve maç içi kritik gelişmeler',
                      value: notificationPrefs['goal'] ?? true,
                      onChanged: (value) => _updatePref('goal', value),
                    ),
                    _SwitchTile(
                      icon: Icons.groups_rounded,
                      title: 'Kadro Açıklandı',
                      subtitle: 'İlk 11 ve kadro kurma fırsatları',
                      value: notificationPrefs['lineup'] ?? true,
                      onChanged: (value) => _updatePref('lineup', value),
                    ),
                    _SwitchTile(
                      icon: Icons.emoji_events_rounded,
                      title: 'Tahmin Hatırlatmaları',
                      subtitle: 'Tahmin süresi bitmeden önce uyarı al',
                      value: notificationPrefs['prediction'] ?? true,
                      onChanged: (value) => _updatePref('prediction', value),
                    ),
                    _SwitchTile(
                      icon: Icons.forum_rounded,
                      title: 'Sohbet Bildirimleri',
                      subtitle: 'Yeni mesaj ve oda aktiviteleri',
                      value: notificationPrefs['chat'] ?? true,
                      onChanged: (value) => _updatePref('chat', value),
                    ),
                    _SwitchTile(
                      icon: Icons.comment_rounded,
                      title: 'Yorum ve Cevaplar',
                      subtitle: 'Gönderilerine gelen yorum ve cevaplar',
                      value: notificationPrefs['comment'] ?? true,
                      onChanged: (value) => _updatePref('comment', value),
                    ),
                    _SwitchTile(
                      icon: Icons.thumb_up_rounded,
                      title: 'Beğeniler',
                      subtitle: 'Kadro, gönderi ve yorum beğenileri',
                      value: notificationPrefs['like'] ?? true,
                      onChanged: (value) => _updatePref('like', value),
                    ),
                    _SwitchTile(
                      icon: Icons.flag_rounded,
                      title: 'Görev ve Ödüller',
                      subtitle: 'Tamamlanan görev, XP ve rozet bildirimleri',
                      value: notificationPrefs['mission'] ?? true,
                      onChanged: (value) => _updatePref('mission', value),
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
                      onTap: () => context.push('/about'),
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
                      onTap: () => context.push('/reports'),
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
                      onTap: () => context.push('/policy'),
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

class _NotificationSectionHeader extends StatelessWidget {
  final bool isSaving;

  const _NotificationSectionHeader({required this.isSaving});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _SectionTitle(title: 'Bildirimler'),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isSaving
              ? const SizedBox(
                  key: ValueKey('saving'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                )
              : const Text(
                  key: ValueKey('saved'),
                  'Kaydedildi',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
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
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

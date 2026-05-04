import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

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

  void _logout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
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
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await authService.signOut();

                    if (!context.mounted) return;
                    Navigator.pop(context);
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
                onPressed: () => Navigator.pop(context),
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

  void _openComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F6A3D),
        content: Text('$title yakında aktif olacak.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                onBack: () => context.go('/profile'),
              ),

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
                onTap: () => _openComingSoon('Şifre değiştirme'),
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
                },
              ),
              _SwitchTile(
                icon: Icons.forum_rounded,
                title: 'Sohbet Bildirimleri',
                subtitle: 'Yeni mesaj ve oda aktiviteleri',
                value: chatNotifications,
                onChanged: (value) {
                  setState(() => chatNotifications = value);
                },
              ),
              _SwitchTile(
                icon: Icons.thumb_up_rounded,
                title: 'Beğeni Bildirimleri',
                subtitle: 'Kadro ve yorum beğenileri',
                value: likeNotifications,
                onChanged: (value) {
                  setState(() => likeNotifications = value);
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
                },
              ),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Dil',
                subtitle: 'Türkçe',
                onTap: () => _openComingSoon('Dil seçimi'),
              ),
              _SettingsTile(
                icon: Icons.info_rounded,
                title: 'Hakkında',
                subtitle: 'Uygulama bilgileri ve sürüm',
                onTap: () => context.go('/about'),
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
                icon: Icons.privacy_tip_rounded,
                title: 'Gizlilik ve Kullanım Şartları',
                subtitle: 'Platform kuralları',
                onTap: () => context.go('/policy'),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
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
    return _DarkCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F6A3D),
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
          style: const TextStyle(
            color: Color(0xFFB3B3B3),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white38,
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
    return _DarkCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F6A3D),
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
          style: const TextStyle(
            color: Color(0xFFB3B3B3),
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          activeThumbColor: const Color(0xFFE53935),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _DarkCard({
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
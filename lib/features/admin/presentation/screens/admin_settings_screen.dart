import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_sidebar.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  static const String routePath = '/admin/settings';

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final appNameController = TextEditingController();
  final announcementController = TextEditingController();
  final supportEmailController = TextEditingController();

  bool maintenanceMode = false;
  bool predictionsEnabled = true;
  bool chatEnabled = true;
  bool feedEnabled = true;
  bool isLoaded = false;
  bool isSaving = false;

  Future<bool> _isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Future<void> _loadSettings() async {
    if (isLoaded) return;

    final doc = await FirebaseFirestore.instance
        .collection('appSettings')
        .doc('main')
        .get();

    final data = doc.data();

    appNameController.text = data?['appName'] ?? 'Amedspor Dijital Tribün';
    announcementController.text = data?['announcement'] ?? '';
    supportEmailController.text = data?['supportEmail'] ?? '';

    maintenanceMode = data?['maintenanceMode'] ?? false;
    predictionsEnabled = data?['predictionsEnabled'] ?? true;
    chatEnabled = data?['chatEnabled'] ?? true;
    feedEnabled = data?['feedEnabled'] ?? true;

    isLoaded = true;
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('appSettings')
          .doc('main')
          .set({
            'appName': appNameController.text.trim(),
            'announcement': announcementController.text.trim(),
            'supportEmail': supportEmailController.text.trim(),
            'maintenanceMode': maintenanceMode,
            'predictionsEnabled': predictionsEnabled,
            'chatEnabled': chatEnabled,
            'feedEnabled': feedEnabled,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Ayarlar kaydedildi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Ayar kaydetme hatası: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }

        if (adminSnapshot.data != true) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0E0E),
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Admin girişi yap'),
              ),
            ),
          );
        }

        return FutureBuilder<void>(
          future: _loadSettings(),
          builder: (context, settingsSnapshot) {
            if (settingsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0E0E0E),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE53935)),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 900;

                return Scaffold(
                  backgroundColor: const Color(0xFF0E0E0E),
                  appBar: compact
                      ? AppBar(
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          title: const Text('Platform Ayarları'),
                        )
                      : null,
                  drawer: compact
                      ? const Drawer(
                          backgroundColor: Color(0xFF111111),
                          child: AdminSidebar(
                            activeRoute: AdminSettingsScreen.routePath,
                            width: double.infinity,
                          ),
                        )
                      : null,
                  body: Row(
                    children: [
                      if (!compact) const _AdminSidebar(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 860),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Platform Ayarları',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Uygulama adı, bakım modu, duyuru ve modül erişimlerini yönet.',
                                    style: TextStyle(
                                      color: Color(0xFFB3B3B3),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  _AdminCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Genel Bilgiler',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        _AdminTextField(
                                          controller: appNameController,
                                          label: 'Platform adı',
                                          icon: Icons.apps_rounded,
                                        ),
                                        const SizedBox(height: 16),

                                        _AdminTextField(
                                          controller: supportEmailController,
                                          label: 'Destek email',
                                          icon: Icons.email_rounded,
                                        ),
                                        const SizedBox(height: 16),

                                        _AdminTextField(
                                          controller: announcementController,
                                          label: 'Duyuru mesajı',
                                          icon: Icons.campaign_rounded,
                                          minLines: 4,
                                          maxLines: 6,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  _AdminCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sistem Durumu',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        _SwitchTile(
                                          title: 'Bakım modu',
                                          subtitle:
                                              'Açılırsa kullanıcılar uygulamaya erişemeden bakım mesajı görür.',
                                          value: maintenanceMode,
                                          color: const Color(0xFFE53935),
                                          onChanged: (value) {
                                            setState(
                                              () => maintenanceMode = value,
                                            );
                                          },
                                        ),
                                        _SwitchTile(
                                          title: 'Tahmin sistemi aktif',
                                          subtitle:
                                              'Kullanıcıların maç tahmini yapmasına izin ver.',
                                          value: predictionsEnabled,
                                          color: const Color(0xFF0F6A3D),
                                          onChanged: (value) {
                                            setState(
                                              () => predictionsEnabled = value,
                                            );
                                          },
                                        ),
                                        _SwitchTile(
                                          title: 'Sohbet sistemi aktif',
                                          subtitle:
                                              'Sohbet odalarını kullanıcılar için aç/kapat.',
                                          value: chatEnabled,
                                          color: const Color(0xFF0F6A3D),
                                          onChanged: (value) {
                                            setState(() => chatEnabled = value);
                                          },
                                        ),
                                        _SwitchTile(
                                          title: 'Feed aktif',
                                          subtitle:
                                              'Sosyal akış ve post sistemini aç/kapat.',
                                          value: feedEnabled,
                                          color: const Color(0xFF0F6A3D),
                                          onChanged: (value) {
                                            setState(() => feedEnabled = value);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: isSaving
                                          ? null
                                          : _saveSettings,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE53935,
                                        ),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.white12,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      icon: isSaving
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save_rounded),
                                      label: Text(
                                        isSaving
                                            ? 'Kaydediliyor...'
                                            : 'AYARLARI KAYDET',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Widget child;

  const _AdminCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int? minLines;
  final int? maxLines;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.minLines,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFE53935),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
        prefixIcon: Icon(icon, color: const Color(0xFF0F6A3D)),
        filled: true,
        fillColor: const Color(0xFF111111),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final icon = CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(
              value ? Icons.check_rounded : Icons.close_rounded,
              color: color,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
            ],
          );

          final toggle = Switch(
            value: value,
            activeThumbColor: color,
            onChanged: onChanged,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [icon, const SizedBox(width: 14), toggle]),
                const SizedBox(height: 12),
                content,
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(child: content),
              toggle,
            ],
          );
        },
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AMEDSPOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Admin Panel',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            onTap: () => context.go('/admin/dashboard'),
          ),
          _SidebarItem(
            icon: Icons.sports_soccer_rounded,
            title: 'Maçlar',
            onTap: () => context.go('/admin/matches'),
          ),
          _SidebarItem(
            icon: Icons.people_rounded,
            title: 'Kullanıcılar',
            onTap: () => context.go('/admin/users'),
          ),
          _SidebarItem(
            icon: Icons.article_rounded,
            title: 'Postlar',
            onTap: () => context.go('/admin/posts'),
          ),
          _SidebarItem(
            icon: Icons.report_rounded,
            title: 'Raporlar',
            onTap: () => context.go('/admin/reports'),
          ),
          _SidebarItem(
            icon: Icons.notifications_rounded,
            title: 'Bildirim',
            onTap: () => context.go('/admin/notifications'),
          ),
          _SidebarItem(
            icon: Icons.forum_rounded,
            title: 'Sohbet',
            onTap: () => context.go('/admin/chats'),
          ),
          _SidebarItem(
            icon: Icons.emoji_events_rounded,
            title: 'Tahminler',
            onTap: () => context.go('/admin/predictions'),
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            title: 'Ayarlar',
            active: true,
            onTap: () => context.go('/admin/settings'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authService.signOut();
                if (!context.mounted) return;
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFE53935)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool active;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: active ? const Color(0xFF0F6A3D) : Colors.transparent,
        leading: Icon(
          icon,
          color: active ? Colors.white : const Color(0xFFB3B3B3),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB3B3B3),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/admin_layout.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const String routePath = '/admin/dashboard';

  static void showUnavailable(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFE53935),
        content: Text('$title modulu bu surumde aktif degil.'),
      ),
    );
  }

  Stream<Map<String, int>> _watchStats() {
    final db = FirebaseFirestore.instance;

    return db.collection('users').snapshots().asyncMap((usersSnapshot) async {
      final matchesSnapshot = await db.collection('matches').get();
      final postsSnapshot = await db.collection('posts').get();
      final reportsSnapshot = await db.collection('reports').get();
      final predictionsSnapshot = await db.collection('predictions').get();

      return {
        'users': usersSnapshot.docs.length,
        'matches': matchesSnapshot.docs.length,
        'posts': postsSnapshot.docs.length,
        'reports': reportsSnapshot.docs.length,
        'predictions': predictionsSnapshot.docs.length,
      };
    });
  }

  int _gridColumns(double width, {required int desktop, int tablet = 2}) {
    if (width >= 1200) return desktop;
    if (width >= 640) return tablet;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminDashboardScreen.routePath,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ListView(
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Amedspor platform yönetim merkezi',
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            ),
            const SizedBox(height: 28),

            StreamBuilder<Map<String, int>>(
              stream: _watchStats(),
              builder: (context, snapshot) {
                final stats =
                    snapshot.data ??
                    {
                      'users': 0,
                      'matches': 0,
                      'posts': 0,
                      'reports': 0,
                      'predictions': 0,
                    };

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _gridColumns(
                      constraints.maxWidth,
                      desktop: 5,
                    );

                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: columns == 1 ? 2.2 : 1.35,
                      children: [
                        _StatCard(
                          icon: Icons.people_rounded,
                          title: 'Kullanıcı',
                          value: (stats['users'] ?? 0).toString(),
                          subtitle: 'Toplam kullanıcı',
                        ),
                        _StatCard(
                          icon: Icons.sports_soccer_rounded,
                          title: 'Maç',
                          value: (stats['matches'] ?? 0).toString(),
                          subtitle: 'Toplam maç',
                        ),
                        _StatCard(
                          icon: Icons.article_rounded,
                          title: 'Post',
                          value: (stats['posts'] ?? 0).toString(),
                          subtitle: 'Toplam paylaşım',
                        ),
                        _StatCard(
                          icon: Icons.report_rounded,
                          title: 'Rapor',
                          value: (stats['reports'] ?? 0).toString(),
                          subtitle: 'Toplam rapor',
                        ),
                        _StatCard(
                          icon: Icons.emoji_events_rounded,
                          title: 'Tahmin',
                          value: (stats['predictions'] ?? 0).toString(),
                          subtitle: 'Toplam tahmin',
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns = _gridColumns(constraints.maxWidth, desktop: 4);

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: columns == 1 ? 2.45 : 1.45,
                  children: [
                    _DashboardCard(
                      icon: Icons.sports_soccer_rounded,
                      title: 'Maç Yönetimi',
                      subtitle: 'Maç ekle, düzenle, skor gir',
                      onTap: () => context.go('/admin/matches'),
                    ),
                    _DashboardCard(
                      icon: Icons.people_rounded,
                      title: 'Kullanıcılar',
                      subtitle: 'Kullanıcıları ve rolleri yönet',
                      onTap: () => context.go('/admin/users'),
                    ),
                    _DashboardCard(
                      icon: Icons.article_rounded,
                      title: 'Postlar',
                      subtitle: 'Paylaşımları incele ve yönet',
                      onTap: () => context.go('/admin/posts'),
                    ),
                    _DashboardCard(
                      icon: Icons.report_rounded,
                      title: 'Raporlar',
                      subtitle: 'Şikayetleri ve moderasyonu yönet',
                      onTap: () => context.go('/admin/reports'),
                    ),
                    _DashboardCard(
                      icon: Icons.notifications_rounded,
                      title: 'Bildirim Gönder',
                      subtitle: 'Kullanıcılara duyuru gönder',
                      onTap: () => context.go('/admin/notifications'),
                    ),
                    _DashboardCard(
                      icon: Icons.forum_rounded,
                      title: 'Sohbet Odaları',
                      subtitle: 'Odaları ve mesajları yönet',
                      onTap: () => context.go('/admin/chats'),
                    ),
                    _DashboardCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Tahminler',
                      subtitle: 'Puan ve sonuç yönetimi',
                      onTap: () => context.go('/admin/predictions'),
                    ),
                    _DashboardCard(
                      icon: Icons.settings_rounded,
                      title: 'Ayarlar',
                      subtitle: 'Platform ayarları',
                      onTap: () => context.go('/admin/settings'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF0F6A3D),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE53935),
              child: Icon(icon, color: Colors.white),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

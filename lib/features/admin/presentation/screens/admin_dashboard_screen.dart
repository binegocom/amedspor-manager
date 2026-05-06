import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_card.dart';
import '../widgets/admin_layout.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const String routePath = '/admin/dashboard';

  static Map<String, int>? _cachedStats;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  Stream<Map<String, int>> _watchStats() async* {
    final now = DateTime.now();
    final hasValidCache = _cachedStats != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheExpiration;

    if (_cachedStats != null) yield _cachedStats!;
    if (hasValidCache) return;

    try {
      final db = FirebaseFirestore.instance;
      final usersCount = await db.collection('users').count().get();
      final matchesCount = await db.collection('matches').count().get();
      final postsCount = await db.collection('posts').count().get();
      final reportsCount = await db.collection('reports').count().get();

      _cachedStats = {
        'users': usersCount.count ?? 0,
        'matches': matchesCount.count ?? 0,
        'posts': postsCount.count ?? 0,
        'reports': reportsCount.count ?? 0,
      };
      _lastFetchTime = now;
      yield _cachedStats!;
    } catch (e) {
      if (_cachedStats == null) {
        yield {'users': 0, 'matches': 0, 'posts': 0, 'reports': 0};
      }
    }
  }

  int _gridColumns(double width) {
    if (width >= 1400) return 4;
    if (width >= 900) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminDashboardScreen.routePath,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Admin Dashboard', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          const Text('Platform yönetim ve istatistik merkezi', style: AppTextStyles.body),
          const SizedBox(height: 40),
          StreamBuilder<Map<String, int>>(
            stream: _watchStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {'users': 0, 'matches': 0, 'posts': 0, 'reports': 0};
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = _gridColumns(constraints.maxWidth);
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.8,
                    children: [
                      _StatCard(title: 'Kullanıcılar', value: '${stats['users']}', icon: Icons.people_rounded, color: AppColors.primaryGreen),
                      _StatCard(title: 'Aktif Maçlar', value: '${stats['matches']}', icon: Icons.sports_soccer_rounded, color: AppColors.primaryRed),
                      _StatCard(title: 'Toplam Post', value: '${stats['posts']}', icon: Icons.feed_rounded, color: AppColors.gold),
                      _StatCard(title: 'Raporlar', value: '${stats['reports']}', icon: Icons.report_rounded, color: AppColors.errorRed),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 48),
          const Text('Hızlı İşlemler', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = _gridColumns(constraints.maxWidth);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _ActionCard(title: 'Maç Yönetimi', subtitle: 'Canlı skor ve etkinlik girişi', icon: Icons.stadium_rounded, onTap: () => context.go('/admin/matches')),
                  _ActionCard(title: 'Oyuncu Havuzu', subtitle: 'Kadro kurma oyuncuları', icon: Icons.person_add_rounded, onTap: () => context.go('/admin/players')),
                  _ActionCard(title: 'Moderasyon', subtitle: 'Raporlar ve içerik denetimi', icon: Icons.gavel_rounded, onTap: () => context.go('/admin/reports')),
                  _ActionCard(title: 'Ayarlar', subtitle: 'Sistem ve uygulama ayarları', icon: Icons.settings_rounded, onTap: () => context.go('/admin/settings')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.h1.copyWith(fontSize: 28)),
                Text(title, style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 32),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

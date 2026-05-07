import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../data/repositories/audit_log_repository.dart';
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
      title: 'Yönetim Merkezi',
      subtitle: 'Amedspor Dijital Tribün sistem durumu ve özet istatistikler.',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          _PlatformStatusBar(),
          const SizedBox(height: 32),
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
                    childAspectRatio: cols == 1 ? 2.5 : 1.8,
                    children: [
                      _StatCard(title: 'Toplam Taraftar', value: '${stats['users']}', icon: Icons.people_rounded, color: const Color(0xFF0F6A3D), trend: '+12%'),
                      _StatCard(title: 'Aktif Maçlar', value: '${stats['matches']}', icon: Icons.sports_soccer_rounded, color: const Color(0xFFE53935), trend: 'Canlı'),
                      _StatCard(title: 'Sosyal Etkileşim', value: '${stats['posts']}', icon: Icons.feed_rounded, color: const Color(0xFFFFB300), trend: '+5%'),
                      _StatCard(title: 'Bekleyen Raporlar', value: '${stats['reports']}', icon: Icons.report_rounded, color: const Color(0xFF7B1FA2), trend: 'Kritik'),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 1000;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hızlı Erişim', style: AppTextStyles.h2),
                        const SizedBox(height: 24),
                        GridView.count(
                          crossAxisCount: constraints.maxWidth > 600 ? 2 : 1,
                          shrinkWrap: true,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.2,
                          children: [
                            _ActionCard(title: 'Canlı Maç Yönetimi', subtitle: 'Skor ve olay takibi', icon: Icons.live_tv_rounded, onTap: () => context.go('/admin/matches')),
                            _ActionCard(title: 'İçerik Moderasyonu', subtitle: 'Rapor ve yorum denetimi', icon: Icons.gavel_rounded, onTap: () => context.go('/admin/reports')),
                            _ActionCard(title: 'Kullanıcı Yetkileri', subtitle: 'Rol ve erişim yönetimi', icon: Icons.admin_panel_settings_rounded, onTap: () => context.go('/admin/users')),
                            _ActionCard(title: 'Sistem Ayarları', subtitle: 'Bakım modu ve konfigürasyon', icon: Icons.settings_suggest_rounded, onTap: () => context.go('/admin/settings')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 48),
                    const Expanded(
                      flex: 2,
                      child: _RecentActivityFeed(),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 48),
          if (MediaQuery.of(context).size.width <= 1000) const _RecentActivityFeed(),
          const SizedBox(height: 64),
        ],
      ),
    );
  }
}

class _PlatformStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _StatusItem(label: 'Firebase', status: 'Optimal', color: const Color(0xFF0F6A3D)),
          _StatusDivider(),
          _StatusItem(label: 'Bildirimler', status: 'Aktif', color: const Color(0xFF0F6A3D)),
          _StatusDivider(),
          _StatusItem(label: 'Güvenlik', status: 'Sertifikalı', color: const Color(0xFF0F6A3D)),
          const Spacer(),
          const Text(
            'Sistem Güncellemesi: 12.05.2024',
            style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String status;
  final Color color;
  const _StatusItem({required this.label, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(status, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }
}

class _StatusDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 24, width: 1, margin: const EdgeInsets.symmetric(horizontal: 24), color: Colors.white10);
  }
}

class _RecentActivityFeed extends StatelessWidget {
  const _RecentActivityFeed();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Son Etkinlikler', style: AppTextStyles.h2),
            TextButton(onPressed: () => context.go('/admin/audit-logs'), child: const Text('Tümünü Gör')),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: AuditLogRepository().watchRecentLogs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Erişim yetkisi yetersiz', style: TextStyle(color: Colors.white38)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) return const Center(child: Text('Henüz etkinlik yok', style: TextStyle(color: Colors.white38)));

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 32),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                        child: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFFE53935)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['adminEmail'] ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${log['action']} - ${log['targetType']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yeni', // For simplicity
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trend,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: AppTextStyles.h1.copyWith(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(title, style: AppTextStyles.label.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
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
    return PremiumCard(
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

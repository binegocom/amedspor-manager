import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class AdminSidebar extends StatelessWidget {
  final String activeRoute;
  final double width;

  const AdminSidebar({super.key, required this.activeRoute, this.width = 280});

  bool _isActive(String route) => activeRoute == route;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.white, width: 0.05)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AMEDSPOR', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const Text('PREMIUM ADMIN', style: TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 48),
            Expanded(
              child: ListView(
                children: [
                  _SidebarItem(icon: Icons.dashboard_rounded, title: 'Dashboard', active: _isActive('/admin/dashboard'), onTap: () => context.go('/admin/dashboard')),
                  _SidebarItem(icon: Icons.stadium_rounded, title: 'Maçlar', active: _isActive('/admin/matches'), onTap: () => context.go('/admin/matches')),
                  _SidebarItem(icon: Icons.person_add_rounded, title: 'Oyuncular', active: _isActive('/admin/players'), onTap: () => context.go('/admin/players')),
                  _SidebarItem(icon: Icons.groups_rounded, title: 'Kadrolar', active: _isActive('/admin/lineups'), onTap: () => context.go('/admin/lineups')),
                  _SidebarItem(icon: Icons.people_rounded, title: 'Kullanıcılar', active: _isActive('/admin/users'), onTap: () => context.go('/admin/users')),
                  _SidebarItem(icon: Icons.feed_rounded, title: 'Postlar', active: _isActive('/admin/posts'), onTap: () => context.go('/admin/posts')),
                  _SidebarItem(icon: Icons.gavel_rounded, title: 'Moderasyon', active: _isActive('/admin/reports'), onTap: () => context.go('/admin/reports')),
                  _SidebarItem(icon: Icons.notifications_active_rounded, title: 'Duyurular', active: _isActive('/admin/notifications'), onTap: () => context.go('/admin/notifications')),
                  _SidebarItem(icon: Icons.forum_rounded, title: 'Sohbet', active: _isActive('/admin/chats'), onTap: () => context.go('/admin/chats')),
                   _SidebarItem(icon: Icons.emoji_events_rounded, title: 'Tahminler', active: _isActive('/admin/predictions'), onTap: () => context.go('/admin/predictions')),
                  _SidebarItem(icon: Icons.bug_report_rounded, title: 'Hata Merkezi', active: _isActive('/admin/errors'), onTap: () => context.go('/admin/errors')),
                  _SidebarItem(icon: Icons.history_rounded, title: 'Audit Log', active: _isActive('/admin/audit-logs'), onTap: () => context.go('/admin/audit-logs')),
                  _SidebarItem(icon: Icons.settings_rounded, title: 'Ayarlar', active: _isActive('/admin/settings'), onTap: () => context.go('/admin/settings')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await authService.signOut();
                if (!context.mounted) return;
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('GÜVENLİ ÇIKIŞ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool active;
  const _SidebarItem({required this.icon, required this.title, required this.onTap, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryRed.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? AppColors.primaryRed : AppColors.muted, size: 22),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

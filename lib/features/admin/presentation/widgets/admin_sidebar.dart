import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/firebase/firebase_providers.dart';

class AdminSidebar extends StatelessWidget {
  final String activeRoute;
  final double width;

  const AdminSidebar({super.key, required this.activeRoute, this.width = 260});

  bool _isActive(String route) => activeRoute == route;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: ListView(
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
              active: _isActive('/admin/dashboard'),
              onTap: () => context.go('/admin/dashboard'),
            ),
            _SidebarItem(
              icon: Icons.sports_soccer_rounded,
              title: 'Maçlar',
              active: _isActive('/admin/matches'),
              onTap: () => context.go('/admin/matches'),
            ),
            _SidebarItem(
              icon: Icons.people_rounded,
              title: 'Kullanıcılar',
              active: _isActive('/admin/users'),
              onTap: () => context.go('/admin/users'),
            ),
            _SidebarItem(
              icon: Icons.article_rounded,
              title: 'Postlar',
              active: _isActive('/admin/posts'),
              onTap: () => context.go('/admin/posts'),
            ),
            _SidebarItem(
              icon: Icons.report_rounded,
              title: 'Raporlar',
              active: _isActive('/admin/reports'),
              onTap: () => context.go('/admin/reports'),
            ),
            _SidebarItem(
              icon: Icons.notifications_rounded,
              title: 'Bildirim',
              active: _isActive('/admin/notifications'),
              onTap: () => context.go('/admin/notifications'),
            ),
            _SidebarItem(
              icon: Icons.forum_rounded,
              title: 'Sohbet',
              active: _isActive('/admin/chats'),
              onTap: () => context.go('/admin/chats'),
            ),
            _SidebarItem(
              icon: Icons.emoji_events_rounded,
              title: 'Tahminler',
              active: _isActive('/admin/predictions'),
              onTap: () => context.go('/admin/predictions'),
            ),
            _SidebarItem(
              icon: Icons.settings_rounded,
              title: 'Ayarlar',
              active: _isActive('/admin/settings'),
              onTap: () => context.go('/admin/settings'),
            ),

            const SizedBox(height: 24),

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
    required this.active,
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

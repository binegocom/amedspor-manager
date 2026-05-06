import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  static const String routePath = '/admin/users';

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final userRepository = UserRepository();
  String searchQuery = '';

  Future<bool> _isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Future<void> _updateRole({
    required AppUserModel user,
    required String role,
  }) async {
    try {
      await firestoreService.users.doc(user.id).update({
        'role': role,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text('${user.username} rolü $role olarak güncellendi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Rol güncelleme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _toggleUserDisabled(AppUserModel user) async {
    final currentValue = await firestoreService.users.doc(user.id).get();
    final data = currentValue.data();
    final isDisabled = data?['disabled'] == true;

    try {
      await firestoreService.users.doc(user.id).update({
        'disabled': !isDisabled,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text(
            !isDisabled
                ? '${user.username} pasifleştirildi.'
                : '${user.username} tekrar aktif edildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Kullanıcı güncelleme hatası: $e'),
        ),
      );
    }
  }

  List<AppUserModel> _filterUsers(List<AppUserModel> users) {
    final q = searchQuery.trim().toLowerCase();

    if (q.isEmpty) return users;

    return users.where((user) {
      return user.username.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q) ||
          user.role.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: Text(
            'Admin panel sadece web üzerinde kullanılabilir.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

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

        return Scaffold(
          backgroundColor: const Color(0xFF0E0E0E),
          body: Row(
            children: [
              const _AdminSidebar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kullanıcı Yönetimi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kullanıcıları görüntüle, rol değiştir ve hesap durumunu yönet.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: 520,
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          cursorColor: const Color(0xFFE53935),
                          onChanged: (value) {
                            setState(() => searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Kullanıcı adı, email veya rol ara...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF777777),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF0F6A3D),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Colors.white10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Expanded(
                        child: StreamBuilder<List<AppUserModel>>(
                          stream: userRepository.watchLeaderboard(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE53935),
                                ),
                              );
                            }

                            final users = _filterUsers(snapshot.data ?? []);

                            if (users.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Kullanıcı bulunamadı.',
                                  style: TextStyle(
                                    color: Color(0xFFB3B3B3),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: users.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final user = users[index];

                                return _UserCard(
                                  user: user,
                                  onRoleChanged: (role) {
                                    _updateRole(
                                      user: user,
                                      role: role,
                                    );
                                  },
                                  onToggleDisabled: () {
                                    _toggleUserDisabled(user);
                                  },
                                  onOpenProfile: () {
                                    context.go('/profile/${user.id}');
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUserModel user;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onToggleDisabled;
  final VoidCallback onOpenProfile;

  const _UserCard({
    required this.user,
    required this.onRoleChanged,
    required this.onToggleDisabled,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final username =
        user.username.startsWith('@') ? user.username : '@${user.username}';

    return FutureBuilder(
      future: firestoreService.users.doc(user.id).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final isDisabled = data?['disabled'] == true;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDisabled
                ? const Color(0xFF241515)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDisabled ? const Color(0xFFE53935) : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF0F6A3D),
                backgroundImage:
                    user.avatarUrl.isEmpty ? null : NetworkImage(user.avatarUrl),
                child: user.avatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Color(0xFFB3B3B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniBadge(
                          text: '${user.points} puan',
                          color: const Color(0xFF0F6A3D),
                        ),
                        const SizedBox(width: 8),
                        _MiniBadge(
                          text: isDisabled ? 'Pasif' : 'Aktif',
                          color: isDisabled
                              ? const Color(0xFFE53935)
                              : const Color(0xFF0F6A3D),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 160,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: user.role,
                    dropdownColor: const Color(0xFF1A1A1A),
                    iconEnabledColor: Colors.white,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'user',
                        child: Text(
                          'User',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'moderator',
                        child: Text(
                          'Moderator',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text(
                          'Admin',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      onRoleChanged(value);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              OutlinedButton.icon(
                onPressed: onOpenProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF0F6A3D)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Profil'),
              ),

              const SizedBox(width: 8),

              OutlinedButton.icon(
                onPressed: onToggleDisabled,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDisabled
                      ? const Color(0xFF0F6A3D)
                      : const Color(0xFFE53935),
                  side: BorderSide(
                    color: isDisabled
                        ? const Color(0xFF0F6A3D)
                        : const Color(0xFFE53935),
                  ),
                ),
                icon: Icon(
                  isDisabled
                      ? Icons.check_circle_rounded
                      : Icons.block_rounded,
                  size: 18,
                ),
                label: Text(isDisabled ? 'Aktifleştir' : 'Pasifleştir'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
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
            active: true,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
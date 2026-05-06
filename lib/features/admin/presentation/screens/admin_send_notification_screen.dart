import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_sidebar.dart';

class AdminSendNotificationScreen extends StatefulWidget {
  const AdminSendNotificationScreen({super.key});

  static const String routePath = '/admin/notifications';

  @override
  State<AdminSendNotificationScreen> createState() =>
      _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState
    extends State<AdminSendNotificationScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final routeController = TextEditingController(text: '/notifications');

  final userRepository = UserRepository();
  final notificationRepository = NotificationRepository();
  final uuid = const Uuid();

  String selectedType = 'general';
  String targetMode = 'all';
  String? selectedUserId;
  bool isSending = false;

  final types = const [
    'general',
    'match',
    'comment',
    'like',
    'prediction',
    'report',
  ];

  Future<bool> _isAdmin() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Future<void> _sendNotification(List<AppUserModel> users) async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();
    final route = routeController.text.trim().isEmpty
        ? '/notifications'
        : routeController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Başlık ve mesaj boş olamaz.'),
        ),
      );
      return;
    }

    final targetUsers = targetMode == 'all'
        ? users
        : users.where((user) => user.id == selectedUserId).toList();

    if (targetUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Bildirim gönderilecek kullanıcı bulunamadı.'),
        ),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      for (final user in targetUsers) {
        final notification = NotificationModel(
          id: uuid.v4(),
          userId: user.id,
          title: title,
          message: message,
          type: selectedType,
          targetRoute: route,
          read: false,
          createdAt: DateTime.now(),
        );

        await notificationRepository.createNotification(notification);
      }

      if (!mounted) return;

      titleController.clear();
      messageController.clear();
      routeController.text = '/notifications';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text(
            targetMode == 'all'
                ? 'Bildirim tüm kullanıcılara gönderildi.'
                : 'Bildirim seçili kullanıcıya gönderildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Bildirim gönderme hatası: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;

            return Scaffold(
              backgroundColor: const Color(0xFF0E0E0E),
              appBar: compact
                  ? AppBar(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      title: const Text('Bildirim Gönder'),
                    )
                  : null,
              drawer: compact
                  ? const Drawer(
                      backgroundColor: Color(0xFF111111),
                      child: AdminSidebar(
                        activeRoute: AdminSendNotificationScreen.routePath,
                        width: double.infinity,
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!compact) const _AdminSidebar(),
                  Expanded(
                    child: StreamBuilder<List<AppUserModel>>(
                      stream: userRepository.watchLeaderboard(),
                      builder: (context, usersSnapshot) {
                        final users = usersSnapshot.data ?? [];

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 860),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bildirim Gönder',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tüm kullanıcılara veya seçili kullanıcıya uygulama içi bildirim gönder.',
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
                                          'Hedef',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            _ModeChip(
                                              title: 'Tüm Kullanıcılar',
                                              active: targetMode == 'all',
                                              onTap: () {
                                                setState(() {
                                                  targetMode = 'all';
                                                  selectedUserId = null;
                                                });
                                              },
                                            ),
                                            _ModeChip(
                                              title: 'Tek Kullanıcı',
                                              active: targetMode == 'single',
                                              onTap: () {
                                                setState(() {
                                                  targetMode = 'single';
                                                  selectedUserId = users.isEmpty
                                                      ? null
                                                      : users.first.id;
                                                });
                                              },
                                            ),
                                          ],
                                        ),

                                        if (targetMode == 'single') ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF111111),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: Colors.white10,
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedUserId,
                                                dropdownColor: const Color(
                                                  0xFF1A1A1A,
                                                ),
                                                iconEnabledColor: Colors.white,
                                                isExpanded: true,
                                                hint: const Text(
                                                  'Kullanıcı seç',
                                                  style: TextStyle(
                                                    color: Color(0xFFB3B3B3),
                                                  ),
                                                ),
                                                items: users.map((user) {
                                                  final username =
                                                      user.username.startsWith(
                                                        '@',
                                                      )
                                                      ? user.username
                                                      : '@${user.username}';

                                                  return DropdownMenuItem(
                                                    value: user.id,
                                                    child: Text(
                                                      '$username • ${user.email}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(
                                                    () =>
                                                        selectedUserId = value,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 26),

                                        const Text(
                                          'Bildirim İçeriği',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        _AdminTextField(
                                          controller: titleController,
                                          label: 'Başlık',
                                          icon: Icons.title_rounded,
                                        ),
                                        const SizedBox(height: 16),
                                        _AdminTextField(
                                          controller: messageController,
                                          label: 'Mesaj',
                                          icon: Icons.message_rounded,
                                          minLines: 4,
                                          maxLines: 6,
                                        ),
                                        const SizedBox(height: 16),

                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final compact =
                                                constraints.maxWidth < 620;

                                            final typeField = Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF111111),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                border: Border.all(
                                                  color: Colors.white10,
                                                ),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: selectedType,
                                                  dropdownColor: const Color(
                                                    0xFF1A1A1A,
                                                  ),
                                                  iconEnabledColor:
                                                      Colors.white,
                                                  isExpanded: true,
                                                  items: types.map((type) {
                                                    return DropdownMenuItem(
                                                      value: type,
                                                      child: Text(
                                                        'Tip: $type',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    if (value == null) return;
                                                    setState(
                                                      () =>
                                                          selectedType = value,
                                                    );
                                                  },
                                                ),
                                              ),
                                            );

                                            final routeField = _AdminTextField(
                                              controller: routeController,
                                              label:
                                                  'Hedef Route örn: /matches',
                                              icon: Icons.route_rounded,
                                            );

                                            if (compact) {
                                              return Column(
                                                children: [
                                                  typeField,
                                                  const SizedBox(height: 16),
                                                  routeField,
                                                ],
                                              );
                                            }

                                            return Row(
                                              children: [
                                                Expanded(child: typeField),
                                                const SizedBox(width: 16),
                                                Expanded(child: routeField),
                                              ],
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 26),

                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton.icon(
                                            onPressed: isSending
                                                ? null
                                                : () =>
                                                      _sendNotification(users),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFE53935,
                                              ),
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  Colors.white12,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            icon: isSending
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons
                                                        .notifications_active_rounded,
                                                  ),
                                            label: Text(
                                              isSending
                                                  ? 'Gönderiliyor...'
                                                  : 'BİLDİRİM GÖNDER',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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

class _ModeChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F6A3D) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? const Color(0xFF0F6A3D) : Colors.white10,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB3B3B3),
            fontWeight: FontWeight.w900,
          ),
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
            active: true,
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

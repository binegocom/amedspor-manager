import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/notification_model.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const String routePath = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String activeFilter = 'Tümü';

  final notificationRepository = NotificationRepository();

  final List<String> filters = const ['Tümü', 'Okunmamış', 'Okunan'];

  List<NotificationModel> _filterNotifications(List<NotificationModel> items) {
    if (activeFilter == 'Okunmamış') {
      return items.where((item) => !item.read).toList();
    }

    if (activeFilter == 'Okunan') {
      return items.where((item) => item.read).toList();
    }

    return items;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'match':
        return Icons.sports_soccer_rounded;
      case 'like':
        return Icons.thumb_up_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'prediction':
        return Icons.emoji_events_rounded;
      case 'lineup':
        return Icons.groups_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'match':
        return const Color(0xFFE53935);
      case 'like':
        return const Color(0xFF0F6A3D);
      case 'comment':
        return const Color(0xFF2E7DFF);
      case 'prediction':
        return const Color(0xFFFFB300);
      case 'lineup':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFFB3B3B3);
    }
  }

  Future<void> _openNotification(NotificationModel item) async {
    await notificationRepository.markAsRead(item.id);

    if (!mounted) return;
    context.go(item.targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.go('/profile'),
              onSettings: () => context.go('/settings'),
            ),

            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final filter = filters[index];

                  return _FilterChip(
                    title: filter,
                    active: activeFilter == filter,
                    onTap: () => setState(() => activeFilter = filter),
                  );
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<List<NotificationModel>>(
                stream: notificationRepository.watchUserNotifications(
                  authService.currentUser?.uid ?? '',
                ),
                builder: (context, snapshot) {
                  if (authService.currentUser == null) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Giriş Yap'),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final list = _filterNotifications(snapshot.data ?? []);

                  if (list.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = list[index];

                      return _NotificationCard(
                        item: item,
                        icon: _iconForType(item.type),
                        color: _colorForType(item.type),
                        onTap: () => _openNotification(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const _Header({required this.onBack, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Icon(Icons.notifications_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Text(
            'Bildirimler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F6A3D) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? const Color(0xFF0F6A3D) : Colors.white10,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
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

class _NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour = item.createdAt.hour.toString().padLeft(2, '0');
    final minute = item.createdAt.minute.toString().padLeft(2, '0');

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: !item.read ? const Color(0xFF202020) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !item.read ? color.withValues(alpha: 0.45) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!item.read)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$hour:$minute',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Bildirim bulunamadı.',
        style: TextStyle(color: Color(0xFFB3B3B3), fontWeight: FontWeight.w600),
      ),
    );
  }
}

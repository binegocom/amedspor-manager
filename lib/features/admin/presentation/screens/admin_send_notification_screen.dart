import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../widgets/admin_layout.dart';

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
    return AdminLayout(
      activeRoute: AdminSendNotificationScreen.routePath,
      title: 'Bildirim Gönder',
      subtitle: 'Tüm kullanıcılara veya seçili kullanıcıya uygulama içi bildirim gönder.',
      child: StreamBuilder<List<AppUserModel>>(
        stream: userRepository.watchLeaderboard(),
        builder: (context, usersSnapshot) {
          final users = usersSnapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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

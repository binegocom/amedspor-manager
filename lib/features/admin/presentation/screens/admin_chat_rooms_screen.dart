import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class AdminChatRoomsScreen extends StatefulWidget {
  const AdminChatRoomsScreen({super.key});

  static const String routePath = '/admin/chats';

  @override
  State<AdminChatRoomsScreen> createState() => _AdminChatRoomsScreenState();
}

class _AdminChatRoomsScreenState extends State<AdminChatRoomsScreen> {
  final chatRepository = ChatRepository();

  String selectedRoomId = 'general';

  final rooms = const [
    _AdminRoom(id: 'general', title: 'Genel Sohbet', subtitle: 'Tüm taraftarlar'),
    _AdminRoom(id: 'matchday', title: 'Maç Günü', subtitle: 'Maç önü ve maç anı'),
    _AdminRoom(id: 'transfer', title: 'Transfer', subtitle: 'Transfer gündemi'),
  ];

  Future<void> _deleteMessage({
    required String roomId,
    required MessageModel message,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Mesaj silinsin mi?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            message.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFB3B3B3)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sil',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await firestoreService.messages(roomId).doc(message.id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Mesaj silindi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Mesaj silme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _clearRoom(String roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Oda temizlensin mi?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Bu odadaki son mesajlar silinecek. Bu işlem geri alınamaz.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Temizle',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final snapshot = await firestoreService.messages(roomId).limit(100).get();
      final batch = firestoreService.chatRooms.firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Oda temizlendi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Oda temizleme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _toggleRoomLocked(String roomId) async {
    final roomDoc = await firestoreService.chatRooms.doc(roomId).get();
    final isLocked = roomDoc.data()?['locked'] == true;

    try {
      await firestoreService.chatRooms.doc(roomId).set(
        {
          'locked': !isLocked,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text(!isLocked ? 'Oda kilitlendi.' : 'Oda açıldı.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Oda güncelleme hatası: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Admin paneli çok geniş bir sidebar yapısına sahip olduğu için 
    // sadece geniş ekranlarda (Web/Tablet) tam işlevsel çalışır.
    final bool isLargeScreen = MediaQuery.of(context).size.width > 900;

    if (!kIsWeb && !isLargeScreen) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: Text(
            'Admin paneli için geniş ekranlı bir cihaz gereklidir.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    'Sohbet Odaları',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sohbet odalarını, mesajları ve oda durumlarını yönet.',
                    style: TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 320,
                          child: ListView.separated(
                            itemCount: rooms.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final room = rooms[index];

                              return _RoomCard(
                                room: room,
                                active: selectedRoomId == room.id,
                                onTap: () {
                                  setState(() => selectedRoomId = room.id);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _MessagesPanel(
                            roomId: selectedRoomId,
                            chatRepository: chatRepository,
                            onDeleteMessage: (message) {
                              _deleteMessage(
                                roomId: selectedRoomId,
                                message: message,
                              );
                            },
                            onClearRoom: () => _clearRoom(selectedRoomId),
                            onToggleRoomLocked: () {
                              _toggleRoomLocked(selectedRoomId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesPanel extends StatelessWidget {
  final String roomId;
  final ChatRepository chatRepository;
  final ValueChanged<MessageModel> onDeleteMessage;
  final VoidCallback onClearRoom;
  final VoidCallback onToggleRoomLocked;

  const _MessagesPanel({
    required this.roomId,
    required this.chatRepository,
    required this.onDeleteMessage,
    required this.onClearRoom,
    required this.onToggleRoomLocked,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestoreService.chatRooms.doc(roomId).snapshots(),
      builder: (context, roomSnapshot) {
        final roomData = roomSnapshot.data?.data();
        final isLocked = roomData?['locked'] == true;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isLocked ? const Color(0xFFE53935) : const Color(0xFF0F6A3D),
                    child: Icon(
                      isLocked ? Icons.lock_rounded : Icons.forum_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Oda: $roomId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onToggleRoomLocked,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isLocked
                          ? const Color(0xFF0F6A3D)
                          : const Color(0xFFFFB300),
                      side: BorderSide(
                        color: isLocked
                            ? const Color(0xFF0F6A3D)
                            : const Color(0xFFFFB300),
                      ),
                    ),
                    icon: Icon(
                      isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 18,
                    ),
                    label: Text(isLocked ? 'Odayı Aç' : 'Kilitle'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onClearRoom,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                    label: const Text('Temizle'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: chatRepository.watchMessages(roomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE53935),
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Bu odada mesaj yok.',
                          style: TextStyle(
                            color: Color(0xFFB3B3B3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        return _MessageCard(
                          message: message,
                          onDelete: () => onDeleteMessage(message),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  final _AdminRoom room;
  final bool active;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestoreService.chatRooms.doc(room.id).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final locked = data?['locked'] == true;

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF0F6A3D) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: active ? const Color(0xFF0F6A3D) : Colors.white10,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      active ? Colors.white24 : const Color(0xFF0F6A3D),
                  child: Icon(
                    locked ? Icons.lock_rounded : Icons.forum_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        locked ? 'Kilitli • ${room.subtitle}' : room.subtitle,
                        style: TextStyle(
                          color: active
                              ? Colors.white70
                              : const Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.message,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hour = message.createdAt.hour.toString().padLeft(2, '0');
    final minute = message.createdAt.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF0F6A3D),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.username,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$hour:$minute',
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton.icon(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _AdminRoom {
  final String id;
  final String title;
  final String subtitle;

  const _AdminRoom({
    required this.id,
    required this.title,
    required this.subtitle,
  });
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
            active: true,
            onTap: () => context.go('/admin/chats'),
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_layout.dart';

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
    _AdminRoom(id: 'general', title: 'Genel Sohbet', subtitle: 'Topluluk iletişimi'),
    _AdminRoom(id: 'matchday', title: 'Maç Günü', subtitle: 'Canlı heyecan alanı'),
    _AdminRoom(id: 'transfer', title: 'Transfer', subtitle: 'Fısıltı gazetesi'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminChatRoomsScreen.routePath,
      title: 'Sohbet Yönetimi',
      subtitle: 'Oda durumlarını ve mesaj trafiğini profesyonelce denetleyin.',
      child: Container(
        margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Oda Listesi (Sol Panel)
            SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  children: rooms.map((room) => _RoomSelectorCard(
                    room: room,
                    isActive: selectedRoomId == room.id,
                    onTap: () => setState(() => selectedRoomId = room.id),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Mesaj Akışı (Sağ Panel)
            Expanded(
              child: _ChatControlCenter(
                roomId: selectedRoomId,
                roomTitle: rooms.firstWhere((r) => r.id == selectedRoomId).title,
                chatRepository: chatRepository,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomSelectorCard extends StatelessWidget {
  final _AdminRoom room;
  final bool isActive;
  final VoidCallback onTap;

  const _RoomSelectorCard({required this.room, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryRed : const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive ? [BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))] : [],
          ),
          child: Row(
            children: [
              Icon(isActive ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded, color: isActive ? Colors.white : Colors.white38, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(room.subtitle, style: TextStyle(color: isActive ? Colors.white70 : Colors.white24, fontSize: 11)),
                  ],
                ),
              ),
              if (isActive) const Icon(Icons.keyboard_double_arrow_right_rounded, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatControlCenter extends StatelessWidget {
  final String roomId;
  final String roomTitle;
  final ChatRepository chatRepository;

  const _ChatControlCenter({required this.roomId, required this.roomTitle, required this.chatRepository});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(roomTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                _ActionButton(
                  label: 'TEMİZLE',
                  icon: Icons.auto_delete_rounded,
                  color: AppColors.errorRed,
                  onTap: () => _showClearConfirm(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatRepository.watchMessages(roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                final messages = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  reverse: true, // Newest at bottom
                  itemCount: messages.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _AdminMessageRow(
                    message: messages[index],
                    onDelete: () => _deleteMessage(context, roomId, messages[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Odayı Temizle', style: TextStyle(color: Colors.white)),
        content: const Text('Bu odadaki son mesajlar silinecek. Onaylıyor musunuz?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet, Temizle', style: TextStyle(color: AppColors.errorRed))),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await firestoreService.messages(roomId).limit(50).get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  void _deleteMessage(BuildContext context, String roomId, MessageModel message) async {
    await chatRepository.deleteMessage(roomId: roomId, messageId: message.id);
  }
}

class _AdminMessageRow extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onDelete;

  const _AdminMessageRow({required this.message, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            child: Text(message.username[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(message.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message.text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.white24, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _AdminRoom {
  final String id;
  final String title;
  final String subtitle;
  const _AdminRoom({required this.id, required this.title, required this.subtitle});
}
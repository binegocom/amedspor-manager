import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/gamification/gamification_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({super.key, required this.roomId});

  static const String routePath = '/chat/:roomId';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  final ChatRepository chatRepository = ChatRepository();
  final uuid = const Uuid();
  bool isSending = false;

  String get roomTitle {
    switch (widget.roomId) {
      case 'matchday':
        return 'Maç Günü';
      case 'transfer':
        return 'Transfer';
      case 'general':
        return 'Genel Sohbet';
      default:
        return widget.roomId;
    }
  }

  bool get isCustomRoom =>
      !const {'general', 'matchday', 'transfer'}.contains(widget.roomId);

  Future<void> _sendMessage() async {
    if (isSending) return;

    final text = _messageController.text.trim();
    final user = authService.currentUser;

    if (text.isEmpty) return;

    if (user == null) {
      _showLoginRequired();
      return;
    }

    final message = MessageModel(
      id: uuid.v4(),
      userId: user.uid,
      username: user.email ?? 'Taraftar',
      text: text,
      likes: 0,
      createdAt: DateTime.now(),
    );

    setState(() => isSending = true);

    try {
      await chatRepository.sendMessage(roomId: widget.roomId, message: message);

      // 🔥 Award XP for matchday chat participation
      if (widget.roomId == 'matchday') {
        await GamificationService().awardXp(
          userId: user.uid,
          amount: GamificationService.xpChatMessageMatchday,
          reason: 'Maç günü sohbetine katıldığın için',
          eventType: 'chat_message_matchday',
          sourceType: 'chat',
          sourceId: message.id,
        );
      }

      _messageController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Mesaj gonderilemedi. Lutfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void _showLoginRequired() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                color: Color(0xFFE53935),
                size: 44,
              ),
              const SizedBox(height: 16),
              const Text(
                'Üyelik Gerekli',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sohbete mesaj yazmak için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(color: Color(0xFFB3B3B3)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createRoom() async {
    final user = authService.currentUser;
    if (user == null) {
      _showLoginRequired();
      return;
    }

    _roomController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Yeni sohbet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: TextField(
            controller: _roomController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Sohbet adi',
              hintStyle: TextStyle(color: Color(0xFF777777)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Vazgec',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = _roomController.text.trim();
                if (name.isEmpty) return;

                final roomId = name
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                    .replaceAll(RegExp(r'-+'), '-')
                    .replaceAll(RegExp(r'^-|-$'), '');

                if (roomId.isEmpty) return;

                try {
                  await chatRepository.createRoom(
                    roomId: roomId,
                    name: name,
                    createdBy: user.uid,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  context.go('/chat/$roomId');
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFFE53935),
                      content: Text(
                        'Sohbet olusturulamadi. Lutfen tekrar deneyin.',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Olustur',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCurrentRoom() async {
    if (!isCustomRoom) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Sohbeti sil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Bu sohbet odasini silmek istiyor musun?',
          style: TextStyle(color: Color(0xFFB3B3B3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgec'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await chatRepository.deleteRoom(widget.roomId);
      if (!mounted) return;
      context.go('/chat/general');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Sohbet silinemedi. Yetkin olmayabilir.'),
        ),
      );
    }
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final user = authService.currentUser;
    if (user == null || user.uid != message.userId) return;

    try {
      await chatRepository.deleteMessage(
        roomId: widget.roomId,
        messageId: message.id,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Mesaj silinemedi. Lutfen tekrar deneyin.'),
        ),
      );
    }
  }

  bool get isLoggedIn => authService.currentUser != null;

  @override
  void dispose() {
    _messageController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              title: roomTitle,
              isCustomRoom: isCustomRoom,
              onBack: () => context.go('/home'),
              onCreateRoom: _createRoom,
              onDeleteRoom: _deleteCurrentRoom,
            ),

            _RoomTabs(activeRoomId: widget.roomId),

            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatRepository.watchMessages(widget.roomId),
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
                        'Henüz mesaj yok. İlk mesajı sen yaz.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final currentUser = authService.currentUser;

                      return _ChatBubble(
                        message: message,
                        isMe:
                            currentUser != null &&
                            message.userId == currentUser.uid,
                        onDelete: () => _deleteMessage(message),
                      );
                    },
                  );
                },
              ),
            ),

            _ChatInputBar(
              controller: _messageController,
              isSending: isSending,
              onSend: () {
                if (!isLoggedIn) {
                  _showLoginRequired();
                  return;
                }

                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String title;
  final bool isCustomRoom;
  final VoidCallback onBack;
  final VoidCallback onCreateRoom;
  final VoidCallback onDeleteRoom;

  const _ChatHeader({
    required this.title,
    required this.isCustomRoom,
    required this.onBack,
    required this.onCreateRoom,
    required this.onDeleteRoom,
  });

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
          const Icon(Icons.forum_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Yeni sohbet',
            onPressed: onCreateRoom,
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
          ),
          if (isCustomRoom)
            IconButton(
              tooltip: 'Sohbeti sil',
              onPressed: onDeleteRoom,
              icon: const Icon(Icons.delete_rounded, color: Color(0xFFE53935)),
            ),
        ],
      ),
    );
  }
}

class _RoomTabs extends StatelessWidget {
  final String activeRoomId;

  const _RoomTabs({required this.activeRoomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _RoomChip(
            title: 'Genel',
            active: activeRoomId == 'general',
            onTap: () => context.go('/chat/general'),
          ),
          const SizedBox(width: 10),
          _RoomChip(
            title: 'Maç Günü',
            active: activeRoomId == 'matchday',
            onTap: () => context.go('/chat/matchday'),
          ),
          const SizedBox(width: 10),
          _RoomChip(
            title: 'Transfer',
            active: activeRoomId == 'transfer',
            onTap: () => context.go('/chat/transfer'),
          ),
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _RoomChip({
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

class _ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onDelete;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? const Color(0xFF0F6A3D)
        : const Color(0xFF1A1A1A);

    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          isMe ? 'Sen' : message.username,
          style: TextStyle(
            color: isMe ? const Color(0xFFE53935) : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onLongPress: isMe ? onDelete : null,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => isSending ? null : onSend(),
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFE53935),
              decoration: InputDecoration(
                hintText: 'Mesaj yaz...',
                hintStyle: const TextStyle(color: Color(0xFF777777)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

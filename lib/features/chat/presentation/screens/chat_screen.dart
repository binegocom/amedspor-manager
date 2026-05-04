import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({
    super.key,
    required this.roomId,
  });

  static const String routePath = '/chat/:roomId';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ChatRepository chatRepository = ChatRepository();
  final uuid = const Uuid();

  String get roomTitle {
    switch (widget.roomId) {
      case 'matchday':
        return 'Maç Günü';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Genel Sohbet';
    }
  }

  Future<void> _sendMessage() async {
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

    await chatRepository.sendMessage(
      roomId: widget.roomId,
      message: message,
    );

    _messageController.clear();
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
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  height: 1.5,
                ),
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

  bool get isLoggedIn => authService.currentUser != null;

  @override
  void dispose() {
    _messageController.dispose();
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
              onBack: () => context.go('/home'),
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
                        isMe: currentUser != null &&
                            message.userId == currentUser.uid,
                      );
                    },
                  );
                },
              ),
            ),

            _ChatInputBar(
              controller: _messageController,
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
  final VoidCallback onBack;

  const _ChatHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
          const Icon(
            Icons.forum_rounded,
            color: Color(0xFFE53935),
          ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              '124 aktif',
              style: TextStyle(
                color: Color(0xFFB3B3B3),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  const _ChatBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isMe ? const Color(0xFF0F6A3D) : const Color(0xFF1A1A1A);

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
        Container(
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
            style: const TextStyle(
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
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
            onTap: onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
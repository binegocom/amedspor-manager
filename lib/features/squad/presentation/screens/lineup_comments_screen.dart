import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/navigation_helpers.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/comment_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class LineupCommentsScreen extends StatefulWidget {
  final String lineupId;

  const LineupCommentsScreen({super.key, required this.lineupId});

  static const String routePath = '/lineup-comments/:lineupId';

  @override
  State<LineupCommentsScreen> createState() => _LineupCommentsScreenState();
}

class _LineupCommentsScreenState extends State<LineupCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final lineupRepository = LineupRepository();
  final uuid = const Uuid();

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = authService.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final comment = CommentModel(
      id: uuid.v4(),
      userId: user.uid,
      postId: widget.lineupId,
      username: user.email ?? 'Taraftar',
      text: text,
      createdAt: DateTime.now(),
    );

    try {
      await lineupRepository.addLineupComment(
        lineupId: widget.lineupId,
        comment: comment,
      );
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Yorum gönderilemedi: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Kadro Yorumları',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          onPressed: () => context.popOrGo('/lineups/me'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: lineupRepository.watchLineupComments(widget.lineupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE53935)),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz yorum yapılmamış.',
                      style: TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return _CommentTile(comment: comments[index]);
                  },
                );
              },
            ),
          ),
          _CommentInput(controller: _commentController, onSend: _sendComment),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF0F6A3D).withValues(alpha: 0.2),
          child: Text(
            comment.username[0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF0F6A3D),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comment.text,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.white24,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Yanıtla',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _CommentInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Yorumunuzu yazın...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: const Color(0xFFE53935),
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

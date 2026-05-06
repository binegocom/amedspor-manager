import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/comment_model.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  static const String routePath = '/post/:postId';

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final commentController = TextEditingController();
  final commentFocusNode = FocusNode();

  final postRepository = PostRepository();
  final uuid = const Uuid();

  bool liked = false;

  bool get isLoggedIn => authService.currentUser != null;

  Future<void> _toggleLike(PostModel post) async {
    if (!isLoggedIn) {
      _showLoginRequired('Beğeni yapmak için giriş yapmalısın.');
      return;
    }

    final nextLiked = !liked;
    setState(() => liked = nextLiked);

    try {
      await postRepository.toggleLike(postId: widget.postId, liked: nextLiked);
    } catch (_) {
      if (!mounted) return;
      setState(() => liked = !nextLiked);
      _showError('Begeni kaydedilemedi. Lutfen tekrar dene.');
    }
  }

  Future<void> _sendComment() async {
    final text = commentController.text.trim();
    final user = authService.currentUser;

    if (user == null) {
      _showLoginRequired('Yorum yapmak için giriş yapmalısın.');
      return;
    }

    if (text.isEmpty) return;

    final comment = CommentModel(
      id: uuid.v4(),
      postId: widget.postId,
      userId: user.uid,
      username: user.email ?? 'Taraftar',
      text: text,
      createdAt: DateTime.now(),
    );

    try {
      await postRepository.addComment(postId: widget.postId, comment: comment);
      commentController.clear();
    } catch (_) {
      if (!mounted) return;
      _showError('Yorum gonderilemedi. Lutfen tekrar dene.');
    }
  }

  void _focusCommentInput() {
    if (!isLoggedIn) {
      _showLoginRequired('Yorum yapmak iÃ§in giriÅŸ yapmalÄ±sÄ±n.');
      return;
    }

    commentFocusNode.requestFocus();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFE53935),
        content: Text(message),
      ),
    );
  }

  void _showLoginRequired(String message) {
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
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
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

  void _reportPost() {
    context.go('/report/post/${widget.postId}');
  }

  @override
  void dispose() {
    commentController.dispose();
    commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.go('/feed'), onReport: _reportPost),

            Expanded(
              child: FutureBuilder<PostModel?>(
                future: postRepository.getPost(widget.postId),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final post = postSnapshot.data;

                  if (post == null) {
                    return const Center(
                      child: Text(
                        'Post bulunamadı.',
                        style: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    );
                  }

                  return StreamBuilder<List<CommentModel>>(
                    stream: postRepository.watchComments(widget.postId),
                    builder: (context, commentsSnapshot) {
                      final comments = commentsSnapshot.data ?? [];

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        children: [
                          _DarkCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFF0F6A3D),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        post.username,
                                        style: const TextStyle(
                                          color: Color(0xFFE53935),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Color(0xFF777777),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  post.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  post.content,
                                  style: const TextStyle(
                                    color: Color(0xFFB3B3B3),
                                    height: 1.5,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    _ActionButton(
                                      icon: liked
                                          ? Icons.thumb_up_alt
                                          : Icons.thumb_up_alt_outlined,
                                      label: '${post.likes}',
                                      active: liked,
                                      onTap: () => _toggleLike(post),
                                    ),
                                    const SizedBox(width: 14),
                                    _ActionButton(
                                      icon: Icons.chat_bubble_outline_rounded,
                                      label: '${comments.length}',
                                      active: false,
                                      onTap: _focusCommentInput,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          const Text(
                            'Yorumlar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (comments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Center(
                                child: Text(
                                  'Henüz yorum yok.',
                                  style: TextStyle(color: Color(0xFFB3B3B3)),
                                ),
                              ),
                            )
                          else
                            ...comments.map(
                              (comment) => _CommentCard(comment: comment),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            _CommentInputBar(
              controller: commentController,
              focusNode: commentFocusNode,
              onSend: _sendComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onReport;

  const _Header({required this.onBack, required this.onReport});

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
          const Text(
            'Post Detay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onReport,
            icon: const Icon(Icons.flag_rounded, color: Color(0xFFE53935)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F6A3D) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommentModel comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF0F6A3D),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.text,
                  style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
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
              focusNode: focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFE53935),
              decoration: InputDecoration(
                hintText: 'Yorum yaz...',
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
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _DarkCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

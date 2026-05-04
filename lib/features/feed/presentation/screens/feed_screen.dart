import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  static const String routePath = '/feed';

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final postRepository = PostRepository();

  void _openPost(PostModel post) {
    context.go('/post/${post.id}');
  }

  void _createPost() {
    context.go('/create-post');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        onPressed: _createPost,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.go('/home'),
              onSearch: () => context.go('/search'),
            ),

            SizedBox(
              height: 54,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: const [
                  _FeedChip(title: 'Tümü', active: true),
                  SizedBox(width: 10),
                  _FeedChip(title: 'Kadrolar', active: false),
                  SizedBox(width: 10),
                  _FeedChip(title: 'Yorumlar', active: false),
                  SizedBox(width: 10),
                  _FeedChip(title: 'Maç Günü', active: false),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<PostModel>>(
                stream: postRepository.watchPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz paylaşım yok. İlk postu sen oluştur.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return _PostCard(
                        post: post,
                        onTap: () => _openPost(post),
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
  final VoidCallback onSearch;

  const _Header({
    required this.onBack,
    required this.onSearch,
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
          const Icon(
            Icons.dynamic_feed_rounded,
            color: Color(0xFFE53935),
          ),
          const SizedBox(width: 10),
          const Text(
            'Taraftar Akışı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  final String title;
  final bool active;

  const _FeedChip({
    required this.title,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _PostCard({
    required this.post,
    required this.onTap,
  });

  IconData get icon {
    if (post.category == 'Kadro') {
      return Icons.sports_soccer_rounded;
    }

    return Icons.article_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F6A3D),
                  child: Icon(icon, color: Colors.white),
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
            const SizedBox(height: 16),
            Text(
              post.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              style: const TextStyle(
                color: Color(0xFFB3B3B3),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _PostAction(
                  icon: Icons.thumb_up_rounded,
                  label: '${post.likes}',
                ),
                const SizedBox(width: 18),
                _PostAction(
                  icon: Icons.chat_bubble_rounded,
                  label: '${post.commentsCount}',
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PostAction({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB3B3B3), size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB3B3B3),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
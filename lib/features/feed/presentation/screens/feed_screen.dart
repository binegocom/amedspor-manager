import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../shared/components/login_required_modal.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  static const String routePath = '/feed';

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final postRepository = PostRepository();
  String activeFilter = 'Tümü';

  void _openPost(PostModel post) {
    if (post.category == 'Kadro' && post.lineupId.isNotEmpty) {
      context.go('/lineup-detail/${post.lineupId}');
      return;
    }
    context.go('/post/${post.id}');
  }

  void _createPost() {
    final user = authService.currentUser;
    if (user == null) {
      showLoginRequiredModal(context);
      return;
    }
    context.push('/create-post');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: _createPost,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PremiumHeader(title: 'TARAFTAR AKIŞI', showBackButton: false),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(title: 'Tümü', active: activeFilter == 'Tümü', onTap: () => setState(() => activeFilter = 'Tümü')),
                  const SizedBox(width: 8),
                  _FilterChip(title: 'Kadrolar', active: activeFilter == 'Kadrolar', onTap: () => setState(() => activeFilter = 'Kadrolar')),
                  const SizedBox(width: 8),
                  _FilterChip(title: 'Maç Günü', active: activeFilter == 'Maç Günü', onTap: () => setState(() => activeFilter = 'Maç Günü')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<PostModel>>(
                stream: postRepository.watchPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                  }

                  final posts = snapshot.data ?? [];
                  final filteredPosts = activeFilter == 'Tümü' 
                      ? posts 
                      : posts.where((p) => p.category == (activeFilter == 'Kadrolar' ? 'Kadro' : activeFilter)).toList();

                  if (filteredPosts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed_outlined, color: AppColors.muted.withValues(alpha: 0.5), size: 64),
                          const SizedBox(height: 16),
                          const Text('Henüz paylaşım yok.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filteredPosts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _PostCard(
                        post: filteredPosts[index],
                        onTap: () => _openPost(filteredPosts[index]),
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

class _FilterChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.title, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.primaryGreen : AppColors.white.withValues(alpha: 0.05)),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(post.category, style: AppTextStyles.label.copyWith(color: AppColors.primaryRed)),
                  ],
                ),
              ),
              Text(
                '${post.createdAt.hour}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.label,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(post.title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, height: 1.5, fontSize: 14),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _ActionItem(icon: Icons.favorite_border_rounded, label: '${post.likes}'),
              const SizedBox(width: 24),
              _ActionItem(icon: Icons.chat_bubble_outline_rounded, label: '${post.commentsCount}'),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.muted, size: 20),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

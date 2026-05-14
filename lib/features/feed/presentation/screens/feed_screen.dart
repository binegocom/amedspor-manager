import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/login_required_modal.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/premium_header.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  static const String routePath = '/feed';

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final postRepository = PostRepository();
  String activeFilter = 'Tümü';

  static const filters = [
    'Tümü',
    'Kadrolar',
    'Maç Yorumu',
    'Maç Günü',
    'Transfer',
    'Tribün',
  ];

  void _openPost(PostModel post) {
    if (post.category == 'Kadro' && post.lineupId.isNotEmpty) {
      context.push('/lineup-detail/${post.lineupId}');
      return;
    }
    context.push('/post/${post.id}');
  }

  void _createPost() {
    final user = authService.currentUser;
    if (user == null) {
      showLoginRequiredModal(context);
      return;
    }
    context.push('/create-post');
  }

  String _categoryForFilter(String filter) {
    return filter == 'Kadrolar' ? 'Kadro' : filter;
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
      body: Stack(
        children: [
          // Breathtaking Glowing Mesh Aura Orbs
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryRed.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryGreen.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content Layer
          SafeArea(
            child: Column(
              children: [
                const PremiumHeader(title: 'TARAFTAR AKIŞI', showBackButton: false),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                const SizedBox(height: 16),
                Expanded(
                  child: ref.watch(postsStreamProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
                    error: (err, stack) => const _FeedMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Akış yüklenemedi.',
                      message: 'Bağlantı veya yetki hatası oluştu. Lütfen tekrar deneyin.',
                    ),
                    data: (posts) {
                      final filteredPosts = activeFilter == 'Tümü'
                          ? posts
                          : posts.where((post) => post.category == _categoryForFilter(activeFilter)).toList();

                      if (filteredPosts.isEmpty) {
                        return const _FeedMessage(
                          icon: Icons.feed_outlined,
                          title: 'Henüz paylaşım yok.',
                          message: 'İlk paylaşımı oluşturmak için artı butonunu kullanın.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filteredPosts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
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
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.muted.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
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

  const _FilterChip({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? AppColors.primaryGreen
                : AppColors.white.withValues(alpha: 0.05),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> with SingleTickerProviderStateMixin {
  final postRepository = PostRepository();
  bool _showHeartPulse = false;

  void _handleDoubleTapLike() async {
    final user = authService.currentUser;
    if (user == null) {
      showLoginRequiredModal(context);
      return;
    }

    setState(() {
      _showHeartPulse = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartPulse = false;
        });
      }
    });

    try {
      await postRepository.toggleLike(postId: widget.post.id, userId: user.uid);
    } catch (_) {}
  }

  void _toggleSingleLike() async {
    final user = authService.currentUser;
    if (user == null) {
      showLoginRequiredModal(context);
      return;
    }
    try {
      await postRepository.toggleLike(postId: widget.post.id, userId: user.uid);
    } catch (_) {}
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.8,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUser = authService.currentUser;

    return GestureDetector(
      onDoubleTap: _handleDoubleTapLike,
      child: PremiumCard(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            post.category,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')}',
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
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, post.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          height: 160,
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (currentUser == null)
                      _ActionItem(
                        icon: Icons.favorite_border_rounded,
                        label: '${post.likes}',
                        color: AppColors.muted,
                        onTap: () => showLoginRequiredModal(context),
                      )
                    else
                      Consumer(
                        builder: (context, ref, child) {
                          final param = PostLikeParam(postId: post.id, userId: currentUser.uid);
                          final isLiked = ref.watch(postLikedStreamProvider(param)).value ?? false;
                          return _ActionItem(
                            icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            label: '${post.likes}',
                            color: isLiked ? AppColors.primaryRed : AppColors.muted,
                            onTap: _toggleSingleLike,
                          );
                        },
                      ),
                    const SizedBox(width: 24),
                    _ActionItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${post.commentsCount}',
                      color: AppColors.muted,
                      onTap: widget.onTap,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.muted,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),

            // 🔥 Pulse overlay heart animation on double tap
            if (_showHeartPulse)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.2),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedOpacity(
                      opacity: _showHeartPulse ? 0.95 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.primaryRed,
                          size: 64,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

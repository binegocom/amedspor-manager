import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/navigation_helpers.dart';
import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/login_required_modal.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String userId;

  const PublicUserProfileScreen({super.key, required this.userId});

  static const String routePath = '/profile/:userId';

  @override
  State<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  bool isFollowing = false;
  bool isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final user = authService.currentUser;
    if (user == null) return;

    final status = await userRepository.isFollowing(user.uid, widget.userId);
    if (!mounted) return;
    setState(() => isFollowing = status);
  }

  Future<void> _toggleFollow() async {
    final user = authService.currentUser;
    if (user == null) {
      showLoginRequiredModal(context);
      return;
    }

    if (user.uid == widget.userId) return;

    setState(() => isActionLoading = true);

    try {
      if (isFollowing) {
        await userRepository.unfollowUser(user.uid, widget.userId);
      } else {
        await userRepository.followUser(user.uid, widget.userId);
      }

      setState(() {
        isFollowing = !isFollowing;
        isActionLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text(
            isFollowing ? 'Kullanıcı takip edildi.' : 'Takipten çıkarıldı.',
          ),
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Hata: $e'),
        ),
      );
    }
  }

  void _reportUser() {
    context.push('/report/user/${widget.userId}');
  }

  @override
  Widget build(BuildContext context) {
    final userRepository = UserRepository();
    final postRepository = PostRepository();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                onBack: () => context.popOrGo('/leaderboard'),
                onReport: _reportUser,
              ),

              const SizedBox(height: 24),

              FutureBuilder<AppUserModel?>(
                future: userRepository.getUser(widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final user = snapshot.data;

                  if (user == null) {
                    return const PremiumCard(
                      child: Text(
                        'Kullanıcı bulunamadı.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _ProfileHero(
                        user: user,
                        isFollowing: isFollowing,
                        isLoading: isActionLoading,
                        onFollow: _toggleFollow,
                      ),
                      const SizedBox(height: 18),
                      _StatsRow(user: user),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              const _SectionTitle(title: 'Rozetler'),
              const SizedBox(height: 12),
              const _BadgesRow(),

              const SizedBox(height: 18),

              const _SectionTitle(title: 'Son Paylaşımlar'),
              const SizedBox(height: 12),

              StreamBuilder<List<PostModel>>(
                stream: postRepository.watchUserPosts(widget.userId),
                builder: (context, snapshot) {
                  final posts = snapshot.data ?? const <PostModel>[];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  if (posts.isEmpty) {
                    return const PremiumCard(
                      child: Text(
                        'Bu kullanicinin henuz paylasimi yok.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }

                  return Column(
                    children: posts
                        .take(5)
                        .map(
                          (post) => _PostPreviewCard(
                            title: post.title,
                            content: post.content,
                            onTap: () => context.push('/post/${post.id}'),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
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
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const Text(
          'Kullanıcı Profili',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onReport,
          icon: const Icon(Icons.flag_rounded, color: AppColors.primaryRed),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AppUserModel user;
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onFollow;

  const _ProfileHero({
    required this.user,
    required this.isFollowing,
    required this.isLoading,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';

    return PremiumCard(
      child: Column(
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.primaryRed, width: 3),
            ),
            child: user.avatarUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 54,
                  )
                : ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.avatarUrl,
                      width: 94,
                      height: 94,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.badges.isEmpty ? 'Taraftar' : user.badges.first,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (authService.currentUser?.uid != user.id)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? AppColors.surface
                      : AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  side: isFollowing
                      ? const BorderSide(color: Colors.white24)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isFollowing
                            ? Icons.check_circle_rounded
                            : Icons.person_add_rounded,
                      ),
                label: Text(
                  isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppUserModel? user;
  const _StatsRow({this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Puan', value: '${user?.points ?? 0}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Takipçi',
            value: '${user?.followersCount ?? 0}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Takip',
            value: '${user?.followingCount ?? 0}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _BadgeCard(icon: Icons.emoji_events_rounded, title: 'Usta'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _BadgeCard(
            icon: Icons.local_fire_department_rounded,
            title: 'Aktif',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _BadgeCard(icon: Icons.forum_rounded, title: 'Tribün'),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BadgeCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onTap;

  const _PostPreviewCard({
    required this.title,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryGreen,
          child: Icon(Icons.article_rounded, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white38,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

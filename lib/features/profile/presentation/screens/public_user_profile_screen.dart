import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/repositories/user_repository.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String userId;

  const PublicUserProfileScreen({
    super.key,
    required this.userId,
  });

  static const String routePath = '/profile/:userId';

  @override
  State<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  bool isFollowing = false;

  void _toggleFollow() {
    setState(() => isFollowing = !isFollowing);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F6A3D),
        content: Text(
          isFollowing ? 'Kullanıcı takip edildi.' : 'Takipten çıkarıldı.',
        ),
      ),
    );
  }

  void _reportUser() {
    context.go('/report/user/${widget.userId}');
  }

  @override
  Widget build(BuildContext context) {
    final userRepository = UserRepository();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                onBack: () => context.go('/leaderboard'),
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
                    return const _DarkCard(
                      child: Text(
                        'Kullanıcı bulunamadı.',
                        style: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    );
                  }

                  return _ProfileHero(
                    user: user,
                    isFollowing: isFollowing,
                    onFollow: _toggleFollow,
                  );
                },
              ),

              const SizedBox(height: 18),

              const _StatsRow(),

              const SizedBox(height: 18),

              const _SectionTitle(title: 'Rozetler'),
              const SizedBox(height: 12),
              const _BadgesRow(),

              const SizedBox(height: 18),

              const _SectionTitle(title: 'Son Paylaşımlar'),
              const SizedBox(height: 12),

              _PostPreviewCard(
                title: 'Maç Önü Yorumu',
                content: 'Bu hafta orta saha maçı belirler.',
                onTap: () => context.go('/post/post_001'),
              ),
              _PostPreviewCard(
                title: 'Benim İlk 11’im',
                content: '4-3-3 ile çıkmalıyız.',
                onTap: () => context.go('/lineup/match_001'),
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

  const _Header({
    required this.onBack,
    required this.onReport,
  });

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
          icon: const Icon(Icons.flag_rounded, color: Color(0xFFE53935)),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AppUserModel user;
  final bool isFollowing;
  final VoidCallback onFollow;

  const _ProfileHero({
    required this.user,
    required this.isFollowing,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final username =
        user.username.startsWith('@') ? user.username : '@${user.username}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F6A3D),
            Color(0xFF111111),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: const Color(0xFFE53935),
                width: 3,
              ),
            ),
            child: user.avatarUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 54,
                  )
                : ClipOval(
                    child: Image.network(
                      user.avatarUrl,
                      width: 94,
                      height: 94,
                      fit: BoxFit.cover,
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
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFE53935),
                foregroundColor: Colors.white,
                side: isFollowing
                    ? const BorderSide(color: Colors.white24)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
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
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCard(label: 'Puan', value: '2450')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Takipçi', value: '318')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Post', value: '42')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 12,
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
          child: _BadgeCard(
            icon: Icons.emoji_events_rounded,
            title: 'Usta',
          ),
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
          child: _BadgeCard(
            icon: Icons.forum_rounded,
            title: 'Tribün',
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BadgeCard({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
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
    return _DarkCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF0F6A3D),
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
          style: const TextStyle(color: Color(0xFFB3B3B3)),
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

class _DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _DarkCard({
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
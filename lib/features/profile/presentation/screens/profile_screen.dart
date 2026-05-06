import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/lineup_model.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/models/prediction_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/repositories/prediction_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routePath = '/profile';

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final userRepository = UserRepository();
    final postRepository = PostRepository();
    final lineupRepository = LineupRepository();
    final predictionRepository = PredictionRepository();

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Giriş Yap'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                onBack: () => context.go('/home'),
                onSettings: () => context.go('/settings'),
              ),

              const SizedBox(height: 24),

              FutureBuilder<AppUserModel?>(
                future: userRepository.getUser(user.uid),
                builder: (context, snapshot) {
                  final appUser = snapshot.data;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHero(user: appUser),
                    const SizedBox(height: 18),
                    _StatsGrid(
                      userId: user.uid,
                      postRepository: postRepository,
                      lineupRepository: lineupRepository,
                      predictionRepository: predictionRepository,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Rozetler'),
                    const SizedBox(height: 12),
                    _BadgesGrid(badges: appUser?.badges ?? const []),
                  ],
                );
                },
              ),

              const SizedBox(height: 18),

              const _SectionTitle(title: 'Hesabım'),
              const SizedBox(height: 12),

              _MenuTile(
                icon: Icons.sports_soccer_rounded,
                title: 'Benim Kadrolarım',
                subtitle: 'Kaydettiğin ve paylaştığın kadrolar',
                onTap: () => context.go('/lineups/me'),
              ),
              _MenuTile(
                icon: Icons.emoji_events_rounded,
                title: 'Tahminlerim',
                subtitle: 'Maç tahmin geçmişin',
                onTap: () => context.go('/predictions/me'),
              ),
              _MenuTile(
                icon: Icons.leaderboard_rounded,
                title: 'Liderlik Tablosu',
                subtitle: 'Haftalık ve genel sıralama',
                onTap: () => context.go('/leaderboard'),
              ),
              _MenuTile(
                icon: Icons.notifications_rounded,
                title: 'Bildirimler',
                subtitle: 'Aktiviteler ve maç hatırlatmaları',
                onTap: () => context.go('/notifications'),
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
  final VoidCallback onSettings;

  const _Header({required this.onBack, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const SizedBox(width: 4),
        const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onSettings,
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AppUserModel? user;

  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    final username = user?.username ?? '@taraftar';
    final avatarUrl = user?.avatarUrl ?? '';
    final points = user?.points ?? 0;
    final badgesCount = user?.badges.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6A3D), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFFE53935), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.28),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: avatarUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 52,
                  )
                : ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            username.startsWith('@') ? username : '@$username',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dijital Tribün Üyesi',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ProfileMiniStat(label: 'Puan', value: '$points'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileMiniStat(
                  label: 'Sehir',
                  value: user?.city.isNotEmpty == true ? user!.city : '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileMiniStat(label: 'Rozet', value: '$badgesCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final String userId;
  final PostRepository postRepository;
  final LineupRepository lineupRepository;
  final PredictionRepository predictionRepository;

  const _StatsGrid({
    required this.userId,
    required this.postRepository,
    required this.lineupRepository,
    required this.predictionRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PredictionModel>>(
      stream: predictionRepository.watchUserPredictions(userId),
      builder: (context, predictionSnapshot) {
        return StreamBuilder<List<LineupModel>>(
          stream: lineupRepository.watchUserLineups(userId),
          builder: (context, lineupSnapshot) {
            return StreamBuilder<List<PostModel>>(
              stream: postRepository.watchUserPosts(userId),
              builder: (context, postSnapshot) {
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_rounded,
                        title: 'Tahmin',
                        value: '${predictionSnapshot.data?.length ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.groups_rounded,
                        title: 'Kadro',
                        value: '${lineupSnapshot.data?.length ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.article_rounded,
                        title: 'Post',
                        value: '${postSnapshot.data?.length ?? 0}',
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0F6A3D),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  final List<String> badges;

  const _BadgesGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    final visibleBadges = badges.isEmpty ? const ['Yeni Taraftar'] : badges;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: visibleBadges
          .map((badge) => _BadgeCard(icon: Icons.shield_rounded, title: badge))
          .toList(),
      /*
        _BadgeCard(icon: Icons.local_fire_department_rounded, title: 'Aktif'),
        _BadgeCard(icon: Icons.emoji_events_rounded, title: 'Usta'),
        _BadgeCard(icon: Icons.sports_soccer_rounded, title: 'Kadrocu'),
        _BadgeCard(icon: Icons.chat_bubble_rounded, title: 'Tribün'),
        _BadgeCard(icon: Icons.star_rounded, title: 'Yıldız'),
        _BadgeCard(icon: Icons.shield_rounded, title: 'Sadık'),
*/
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BadgeCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F6A3D),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white),
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
  final EdgeInsetsGeometry? padding;

  const _DarkCard({required this.child, this.margin, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

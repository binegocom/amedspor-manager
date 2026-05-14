import 'dart:math' as math;
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/navigation_helpers.dart';
import '../../../../shared/components/premium_card.dart';

import '../../../../core/theme/app_colors.dart';
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

import '../../../../shared/components/login_required_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routePath = '/profile';

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: AppBottomNav(currentIndex: 4),
        body: LoginRequiredView(),
      );
    }

    final userRepository = UserRepository();
    final postRepository = PostRepository();
    final lineupRepository = LineupRepository();
    final predictionRepository = PredictionRepository();

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
                onBack: () => context.popOrGo('/home'),
                onSettings: () => context.push('/settings'),
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
                      _LevelProgressBar(user: appUser),
                      const SizedBox(height: 18),
                      _StatsGrid(
                        userId: user.uid,
                        postRepository: postRepository,
                        lineupRepository: lineupRepository,
                        predictionRepository: predictionRepository,
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Oyunlaştırma'),
                      const SizedBox(height: 12),
                      _MenuTile(
                        icon: Icons.assignment_rounded,
                        title: 'Görevler',
                        subtitle: 'Günlük, haftalık ve sezonluk görevlerin',
                        onTap: () => context.push('/missions'),
                      ),
                      _MenuTile(
                        icon: Icons.shield_rounded,
                        title: 'Rozetlerim',
                        subtitle: 'Kazandığın tüm başarı nişanları',
                        onTap: () => context.push('/badges'),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Hesabım'),
                      const SizedBox(height: 12),
                      _MenuTile(
                        icon: Icons.sports_soccer_rounded,
                        title: 'Benim Kadrolarım',
                        subtitle: 'Kaydettiğin ve paylaştığın kadrolar',
                        onTap: () => context.push('/lineups/me'),
                      ),
                      _MenuTile(
                        icon: Icons.emoji_events_rounded,
                        title: 'Tahminlerim',
                        subtitle: 'Maç tahmin geçmişin',
                        onTap: () => context.push('/predictions/me'),
                      ),
                      _MenuTile(
                        icon: Icons.leaderboard_rounded,
                        title: 'Liderlik Tablosu',
                        subtitle: 'Haftalık ve genel sıralama',
                        onTap: () => context.push('/leaderboard'),
                      ),
                      if (appUser?.role == 'admin') ...[
                        _MenuTile(
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'Admin Paneli',
                          subtitle: 'Sistem yönetimi ve içerik kontrolleri',
                          onTap: () => context.go('/admin/dashboard'),
                        ),
                      ],
                      _MenuTile(
                        icon: Icons.notifications_rounded,
                        title: 'Bildirimler',
                        subtitle: 'Aktiviteler ve maç hatırlatmaları',
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
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
    final xp = user?.xp ?? 0;
    final level = user?.level ?? 1;
    final levelTitle = user?.levelTitle ?? 'Yeni Taraftar';

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
          Stack(
            alignment: Alignment.bottomRight,
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
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  'Lvl $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
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
          Text(
            levelTitle,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
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
                  label: 'Şehir',
                  value: user?.city.isNotEmpty == true ? user!.city : '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileMiniStat(label: 'XP', value: '$xp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelProgressBar extends StatelessWidget {
  final AppUserModel? user;

  const _LevelProgressBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final currentLevel = user?.level ?? 1;
    final currentXp = user?.xp ?? 0;

    // Simple level formula: Level = sqrt(xp/100) + 1
    // Reverse: XP for Level L = (L-1)^2 * 100
    final xpForCurrentLevel = math.pow(currentLevel - 1, 2) * 100;
    final xpForNextLevel = math.pow(currentLevel, 2) * 100;

    final progressXp = currentXp - xpForCurrentLevel;
    final requiredXp = xpForNextLevel - xpForCurrentLevel;
    final percent = (progressXp / requiredXp).clamp(0.0, 1.0);

    return PremiumCard(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SEVİYE İLERLEMESİ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF0F6A3D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0F6A3D),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${currentXp.toInt()} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Sıradaki: ${xpForNextLevel.toInt()} XP',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 11,
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatefulWidget {
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
  State<_StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<_StatsGrid> {
  List<PredictionModel>? _predictions;
  List<LineupModel>? _lineups;
  List<PostModel>? _posts;

  late final StreamSubscription<List<PredictionModel>> _predictionSub;
  late final StreamSubscription<List<LineupModel>> _lineupSub;
  late final StreamSubscription<List<PostModel>> _postSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to all three streams independently
    _predictionSub = widget.predictionRepository
        .watchUserPredictions(widget.userId)
        .listen((data) {
          if (mounted) setState(() => _predictions = data);
        });
    _lineupSub = widget.lineupRepository.watchUserLineups(widget.userId).listen(
      (data) {
        if (mounted) setState(() => _lineups = data);
      },
    );
    _postSub = widget.postRepository.watchUserPosts(widget.userId).listen((
      data,
    ) {
      if (mounted) setState(() => _posts = data);
    });
  }

  @override
  void dispose() {
    _predictionSub.cancel();
    _lineupSub.cancel();
    _postSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            title: 'Tahmin',
            value: '${_predictions?.length ?? 0}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.groups_rounded,
            title: 'Kadro',
            value: '${_lineups?.length ?? 0}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.article_rounded,
            title: 'Post',
            value: '${_posts?.length ?? 0}',
          ),
        ),
      ],
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
    return PremiumCard(
      backgroundColor: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF0F6A3D),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
    return PremiumCard(
      backgroundColor: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
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

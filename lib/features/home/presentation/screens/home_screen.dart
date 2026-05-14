import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/lineup_model.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/user_mission_model.dart';
import '../../../../data/repositories/gamification_repository.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();
    final userRepository = UserRepository();
    final gamificationRepository = GamificationRepository();
    final currentUser = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: Stack(
        children: [
          // Ambient Home Screen Aura Glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryGreen.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryRed.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Primary Content
          SafeArea(
            child: StreamBuilder<List<MatchModel>>(
              stream: matchRepository.watchMatches(),
              builder: (context, matchSnapshot) {
                final matches = matchSnapshot.data ?? [];
                final featuredMatch = _selectFeaturedMatch(matches);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Header(),
                      const SizedBox(height: 28),
                      if (matchSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryRed,
                            ),
                          ),
                        )
                      else if (featuredMatch != null)
                        _MatchHeroCard(match: featuredMatch)
                      else
                        _NoMatchCard(onTap: () => context.go('/matches')),
                      const SizedBox(height: 18),
                      if (featuredMatch != null &&
                          _isMatchDay(featuredMatch)) ...[
                        _MatchDayStatusCard(match: featuredMatch),
                        const SizedBox(height: 18),
                      ],
                      _QuickActions(featuredMatch: featuredMatch),
                      const SizedBox(height: 24),
                      if (currentUser != null)
                        FutureBuilder<AppUserModel?>(
                          future: userRepository.getUser(currentUser.uid),
                          builder: (context, userSnapshot) {
                            return StreamBuilder<List<UserMissionModel>>(
                              stream: gamificationRepository.watchUserMissions(
                                currentUser.uid,
                              ),
                              builder: (context, missionSnapshot) {
                                return _TodayHubCard(
                                  user: userSnapshot.data,
                                  missions: missionSnapshot.data ?? const [],
                                );
                              },
                            );
                          },
                        )
                      else
                        _LoginPromptCard(onTap: () => context.go('/login')),
                      const SizedBox(height: 32),
                      const _SectionTitle(title: 'HAFTANIN EN İYİLERİ'),
                      const SizedBox(height: 16),
                      _HaftaninKadrosuCard(
                        onTap: () => context.go('/lineups/weekly-best'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionTitle(title: 'POPÜLER KADROLAR'),
                          TextButton(
                            onPressed: () => context.push('/lineups/top'),
                            child: const Text(
                              'Tümünü Gör',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PopularLineupsList(),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  MatchModel? _selectFeaturedMatch(List<MatchModel> matches) {
    if (matches.isEmpty) return null;

    final liveMatches = matches.where((match) => match.isLive).toList()
      ..sort((a, b) => b.minute.compareTo(a.minute));
    if (liveMatches.isNotEmpty) return liveMatches.first;

    final now = DateTime.now();
    final upcomingMatches =
        matches
            .where(
              (match) =>
                  match.status == 'upcoming' && match.matchDate.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.matchDate.compareTo(b.matchDate));
    if (upcomingMatches.isNotEmpty) return upcomingMatches.first;

    final latestMatches = matches.toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));
    return latestMatches.first;
  }

  bool _isMatchDay(MatchModel match) {
    if (match.isLive) {
      return true;
    }

    final now = DateTime.now();
    return match.matchDate.year == now.year &&
        match.matchDate.month == now.month &&
        match.matchDate.day == now.day;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Official Amedspor PNG Logo Capsule
        Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.shield, color: AppColors.gold),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoş Geldin,', style: AppTextStyles.bodyMedium),
              const Text(
                'AMEDSPORLU',
                style: AppTextStyles.h2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _HeaderIcon(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: 12),
        _HeaderIcon(
          icon: Icons.settings_outlined,
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _MatchHeroCard extends StatelessWidget {
  final MatchModel match;

  const _MatchHeroCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;

    return PremiumCard(
      backgroundColor: AppColors.card,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Text(
                isLive
                    ? 'CANLI MAÇ HEYECANI'
                    : isFinished
                    ? 'SON MAÇ RAPORU'
                    : 'SIRADAKİ MAÇ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TeamView(name: match.homeTeam),
                    Column(
                      children: [
                        if (isLive)
                          Text(
                            '${match.homeScore} - ${match.awayScore}',
                            style: AppTextStyles.h1,
                          )
                        else
                          const Text('VS', style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${match.minute}\'',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            _formatDateTime(match.matchDate),
                            style: AppTextStyles.label,
                          ),
                      ],
                    ),
                    _TeamView(name: match.awayTeam),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: isLive
                      ? 'MAÇ MERKEZİNE GİT'
                      : isFinished
                      ? 'MAÇ RAPORUNU GÖR'
                      : 'KADRO KUR',
                  onTap: () => context.go(
                    isLive
                        ? '/match-live/${match.id}'
                        : isFinished
                        ? '/match-report/${match.id}'
                        : '/lineup/${match.id}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month - $hour:$minute';
  }
}

class _NoMatchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoMatchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.card,
      child: Row(
        children: [
          const Icon(
            Icons.sports_soccer_rounded,
            color: AppColors.primaryGreen,
            size: 36,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maç takvimi bekleniyor', style: AppTextStyles.h3),
                SizedBox(height: 4),
                Text(
                  'Yeni fikstür yayınlandığında burada görünecek.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MatchDayStatusCard extends StatelessWidget {
  final MatchModel match;

  const _MatchDayStatusCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final title = isLive ? 'Maç şu an canlı' : 'Bugün maç günü';
    final description = isLive
        ? 'Skoru, olayları ve maçın oyuncusu oylamasını canlı takip et.'
        : 'Tahminini yap, kadronu kur ve maç sohbetine erkenden katıl.';

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLive
                      ? AppColors.primaryRed.withValues(alpha: 0.18)
                      : AppColors.primaryGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isLive ? Icons.radio_button_checked : Icons.event_available,
                  color: isLive ? AppColors.primaryRed : AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3),
                    const SizedBox(height: 3),
                    Text(
                      '${match.homeTeam} - ${match.awayTeam}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CompactActionButton(
                  label: isLive ? 'Merkez' : 'Tahmin',
                  icon: isLive
                      ? Icons.sports_soccer_rounded
                      : Icons.emoji_events_rounded,
                  onTap: () => context.go(
                    isLive
                        ? '/match-live/${match.id}'
                        : '/prediction/${match.id}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactActionButton(
                  label: 'Sohbet',
                  icon: Icons.forum_rounded,
                  onTap: () => context.go('/chat/general'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.darkBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamView extends StatelessWidget {
  final String name;

  const _TeamView({required this.name});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.shield, color: AppColors.muted, size: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.label.copyWith(color: AppColors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final MatchModel? featuredMatch;

  const _QuickActions({required this.featuredMatch});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _ActionItem(
              icon: Icons.groups_rounded,
              label: 'Kadro',
              onTap: () => context.push('/lineups/top'),
            ),
            const SizedBox(width: 12),
            _ActionItem(
              icon: Icons.emoji_events_rounded,
              label: 'Tahmin',
              onTap: () {
                final matchId = featuredMatch?.id;
                context.go(
                  matchId == null ? '/matches' : '/prediction/$matchId',
                );
              },
            ),
            const SizedBox(width: 12),
            _ActionItem(
              icon: Icons.forum_rounded,
              label: 'Sohbet',
              onTap: () => context.go('/chat/general'),
            ),
            const SizedBox(width: 12),
            _ActionItem(
              icon: Icons.leaderboard_rounded,
              label: 'Liderler',
              onTap: () => context.push('/leaderboard'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.go('/match-simulation'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'CANLI MAÇ SİMÜLASYONU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/market'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB71C1C).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_checkout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'TRANSFER PAZARI (PAKET AÇ)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayHubCard extends StatelessWidget {
  final AppUserModel? user;
  final List<UserMissionModel> missions;

  const _TodayHubCard({required this.user, required this.missions});

  @override
  Widget build(BuildContext context) {
    final activeMissions = missions
        .where((mission) => !mission.claimed)
        .toList();
    final completed = missions.where((mission) => mission.completed).length;
    final nextMission = activeMissions.isNotEmpty ? activeMissions.first : null;
    final xp = user?.xp ?? 0;
    final level = user?.level ?? 1;

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.gold,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Bugünün Taraftar Merkezi',
                  style: AppTextStyles.h3,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/missions'),
                child: const Text(
                  'Görevler',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HubMetric(label: 'Seviye', value: '$level'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HubMetric(label: 'XP', value: '$xp'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HubMetric(label: 'Tamamlanan', value: '$completed'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkBackground.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(
                  nextMission?.completed == true
                      ? Icons.redeem_rounded
                      : Icons.flag_rounded,
                  color: nextMission?.completed == true
                      ? AppColors.gold
                      : AppColors.primaryGreen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nextMission == null
                        ? 'Aktif görev bulunmuyor. Yeni görevler admin panelinden eklenebilir.'
                        : nextMission.completed
                        ? '${nextMission.title} ödülü alınmayı bekliyor.'
                        : '${nextMission.title}: ${nextMission.progress}/${nextMission.requiredCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
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

class _HubMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HubMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginPromptCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColors.primaryRed,
            size: 30,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'XP, görevler ve kişisel istatistikler için giriş yap.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text(
              'Giriş',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HaftaninKadrosuCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HaftaninKadrosuCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      backgroundColor: AppColors.softGreen,
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 40),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HAFTANIN KADROSU', style: AppTextStyles.h3),
                Text(
                  'Hocamızın en beğendiği taktiği gör',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.label);
  }
}

class _PopularLineupsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lineupRepository = LineupRepository();

    return StreamBuilder<List<LineupModel>>(
      stream: lineupRepository.watchTopLineups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }
        final lineups = snapshot.data ?? [];
        if (lineups.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lineups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) =>
                _PopularLineupCard(lineup: lineups[index]),
          ),
        );
      },
    );
  }
}

class _PopularLineupCard extends StatelessWidget {
  final LineupModel lineup;

  const _PopularLineupCard({required this.lineup});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () => context.push('/lineup-detail/${lineup.id}'),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lineup.formation,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text('${lineup.power} GÜÇ', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primaryRed,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text('${lineup.likes}', style: AppTextStyles.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

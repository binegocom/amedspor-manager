import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../data/repositories/lineup_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 32),
              StreamBuilder<List<MatchModel>>(
                stream: matchRepository.watchMatches(),
                builder: (context, snapshot) {
                  final matches = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                  }
                  if (matches.isEmpty) return const SizedBox.shrink();

                  final match = matches.first;
                  return _MatchHeroCard(match: match);
                },
              ),
              const SizedBox(height: 24),
              const _QuickActions(),
              const SizedBox(height: 32),
              const _SectionTitle(title: 'HAFTANIN EN İYİLERİ'),
              const SizedBox(height: 16),
              _HaftaninKadrosuCard(onTap: () => context.go('/lineups/weekly-best')),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle(title: 'POPÜLER KADROLAR'),
                  TextButton(
                    onPressed: () => context.go('/lineups/top'),
                    child: const Text('Tümünü Gör', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PopularLineupsList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoş Geldin,', style: AppTextStyles.bodyMedium),
            const Text('AMEDSPORLU', style: AppTextStyles.h2),
          ],
        ),
        const Spacer(),
        _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: () => context.go('/notifications')),
        const SizedBox(width: 12),
        _HeaderIcon(icon: Icons.settings_outlined, onTap: () => context.go('/settings')),
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
    final isLive = match.status == 'live';

    return PremiumCard(
      backgroundColor: AppColors.card,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Center(
              child: Text(
                isLive ? 'CANLI MAÇ HEYECANI' : 'SIRADAKİ MAÇ',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
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
                          Text('${match.homeScore} - ${match.awayScore}', style: AppTextStyles.h1)
                        else
                          const Text('VS', style: AppTextStyles.h2),
                        const SizedBox(height: 4),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(8)),
                            child: Text('${match.minute}\'', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          Text('19:00', style: AppTextStyles.label),
                      ],
                    ),
                    _TeamView(name: match.awayTeam),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: isLive ? 'MAÇ MERKEZİNE GİT' : 'KADRO KUR',
                  onTap: () => context.go(isLive ? '/match-live/${match.id}' : '/lineup/${match.id}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamView extends StatelessWidget {
  final String name;

  const _TeamView({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Icon(Icons.shield, color: AppColors.muted, size: 30)),
        ),
        const SizedBox(height: 8),
        Text(name, style: AppTextStyles.label.copyWith(color: AppColors.white)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionItem(icon: Icons.groups_rounded, label: 'Kadro', onTap: () => context.go('/lineups/top')),
        const SizedBox(width: 12),
        _ActionItem(icon: Icons.emoji_events_rounded, label: 'Tahmin', onTap: () => context.go('/prediction/match_001')),
        const SizedBox(width: 12),
        _ActionItem(icon: Icons.forum_rounded, label: 'Sohbet', onTap: () => context.go('/chat/general')),
        const SizedBox(width: 12),
        _ActionItem(icon: Icons.leaderboard_rounded, label: 'Liderler', onTap: () => context.go('/leaderboard')),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
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
                Text('Hocamızın en beğendiği taktiği gör', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        final lineups = snapshot.data ?? [];
        if (lineups.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lineups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _PopularLineupCard(lineup: lineups[index]),
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
      onTap: () => context.go('/lineup-detail/${lineup.id}'),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lineup.formation, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 8),
            Text('${lineup.power} GÜÇ', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.primaryRed, size: 14),
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/login_required_modal.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

enum _MatchFilter { all, live, upcoming, finished }

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  _MatchFilter _filter = _MatchFilter.all;

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            const PremiumHeader(title: 'MAÇLAR & FİKSTÜR', showBackButton: false),
            Expanded(
              child: matchesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
                error: (error, stack) => _StateMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Fikstür yüklenemedi',
                  message: '$error',
                ),
                data: (dataList) {
                  final matches = _sortedMatches(dataList);
                  final filteredMatches = _filteredMatches(matches);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      _SimulationBanner(onTap: () => _openSimulation(context)),
                      const SizedBox(height: 18),
                      _SummaryRow(matches: matches),
                      const SizedBox(height: 18),
                      _FilterBar(
                        selected: _filter,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: 16),
                      if (filteredMatches.isEmpty)
                        _StateMessage(
                          icon: Icons.event_busy_rounded,
                          title: _emptyTitle,
                          message: 'Admin panelinden maç eklendiğinde burada görünecek.',
                          compact: true,
                        )
                      else
                        ...filteredMatches.map(
                          (match) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _MatchCard(match: match),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _emptyTitle {
    switch (_filter) {
      case _MatchFilter.live:
        return 'Canlı maç yok';
      case _MatchFilter.upcoming:
        return 'Gelecek maç yok';
      case _MatchFilter.finished:
        return 'Bitmiş maç yok';
      case _MatchFilter.all:
        return 'Henüz maç bilgisi yok';
    }
  }

  List<MatchModel> _sortedMatches(List<MatchModel> matches) {
    final sorted = [...matches];
    sorted.sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      if (a.isFinished != b.isFinished) return a.isFinished ? 1 : -1;
      return a.matchDate.compareTo(b.matchDate);
    });
    return sorted;
  }

  List<MatchModel> _filteredMatches(List<MatchModel> matches) {
    switch (_filter) {
      case _MatchFilter.live:
        return matches.where((match) => match.isLive).toList();
      case _MatchFilter.upcoming:
        return matches
            .where((match) => !match.isLive && !match.isFinished)
            .toList();
      case _MatchFilter.finished:
        return matches.where((match) => match.isFinished).toList();
      case _MatchFilter.all:
        return matches;
    }
  }

  void _openSimulation(BuildContext context) {
    if (authService.currentUser == null) {
      showLoginRequiredModal(context);
      return;
    }
    context.push('/match-simulation');
  }
}

class _SimulationBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SimulationBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF12361E),
      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.28)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canlı Maç Simülasyonu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Takımı sahaya çıkar, anlık olayları yönet.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<MatchModel> matches;

  const _SummaryRow({required this.matches});

  @override
  Widget build(BuildContext context) {
    final live = matches.where((match) => match.isLive).length;
    final upcoming = matches
        .where((match) => !match.isLive && !match.isFinished)
        .length;
    final finished = matches.where((match) => match.isFinished).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Canlı',
            value: '$live',
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Yaklaşan',
            value: '$upcoming',
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Biten',
            value: '$finished',
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _MatchFilter selected;
  final ValueChanged<_MatchFilter> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (_MatchFilter.all, 'Tümü'),
      (_MatchFilter.live, 'Canlı'),
      (_MatchFilter.upcoming, 'Yaklaşan'),
      (_MatchFilter.finished, 'Biten'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            _FilterChip(
              label: item.$2,
              selected: selected == item.$1,
              onTap: () => onChanged(item.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;

    return PremiumCard(
      onTap: () => _openPrimary(context),
      backgroundColor: AppColors.card,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _StatusBadge(match: match),
              const Spacer(),
              Text(
                _formatDateTime(match.matchDate),
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TeamMini(name: match.homeTeam, logo: match.homeLogo),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  match.status == 'upcoming'
                      ? 'VS'
                      : '${match.homeScore} - ${match.awayScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _TeamMini(name: match.awayTeam, logo: match.awayLogo),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLive)
            AppButton(
              text: 'CANLI MERKEZ',
              height: 46,
              onTap: () => context.push('/match-live/${match.id}'),
            )
          else if (match.isFinished)
            AppButton(
              text: 'MAÇ RAPORU',
              height: 46,
              type: AppButtonType.secondary,
              onTap: () => context.push('/match-report/${match.id}'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'TAHMİN',
                    height: 44,
                    onTap: () => _requireLogin(
                      context,
                      () => context.push('/prediction/${match.id}'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    text: 'KADRO',
                    height: 44,
                    type: AppButtonType.secondary,
                    onTap: () => _requireLogin(
                      context,
                      () => context.push('/lineup/${match.id}'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _openPrimary(BuildContext context) {
    if (match.isLive) {
      context.push('/match-live/${match.id}');
    } else if (match.isFinished) {
      context.push('/match-report/${match.id}');
    }
  }

  void _requireLogin(BuildContext context, VoidCallback action) {
    if (authService.currentUser == null) {
      showLoginRequiredModal(context);
      return;
    }
    action();
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.${value.year}  $hour:$minute';
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchModel match;

  const _StatusBadge({required this.match});

  @override
  Widget build(BuildContext context) {
    final color = match.isLive
        ? AppColors.primaryRed
        : match.isFinished
        ? AppColors.gold
        : AppColors.primaryGreen;
    final text = match.isLive
        ? 'CANLI ${match.minute}\''
        : match.isFinished
        ? 'BİTTİ'
        : 'GELECEK MAÇ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.isLive) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMini extends StatelessWidget {
  final String name;
  final String logo;

  const _TeamMini({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Takım' : name;

    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: logo.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logo,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const Icon(
                    Icons.shield,
                    color: AppColors.muted,
                    size: 24,
                  ),
                )
              : const Icon(Icons.shield, color: AppColors.muted, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool compact;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PremiumCard(
          backgroundColor: AppColors.surface,
          child: SizedBox(
            width: double.infinity,
            height: compact ? null : 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.muted, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}

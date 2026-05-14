import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/navigation_helpers.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';

class WeeklyBestLineupsScreen extends StatelessWidget {
  const WeeklyBestLineupsScreen({super.key});

  static const String routePath = '/lineups/weekly-best';

  @override
  Widget build(BuildContext context) {
    final lineupRepository = LineupRepository();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Haftanın En İyi Kadroları',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          onPressed: () => context.popOrGo('/lineups/top'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<LineupModel>>(
        stream: lineupRepository.watchTopLineups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            );
          }

          final bestLineups = snapshot.data ?? [];

          if (bestLineups.isEmpty) {
            return const Center(
              child: Text(
                'Henüz en iyi kadro seçilmedi.',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: bestLineups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final lineup = bestLineups[index];
              return _BestLineupCard(lineup: lineup, rank: index + 1);
            },
          );
        },
      ),
    );
  }
}

class _BestLineupCard extends StatelessWidget {
  final LineupModel lineup;
  final int rank;

  const _BestLineupCard({required this.lineup, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RankBadge(rank: rank),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teknik Direktör',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'User ID: ${lineup.userId.substring(0, 8)}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F6A3D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  lineup.formation,
                  style: const TextStyle(
                    color: Color(0xFF0F6A3D),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'Beğeni',
                value: '${lineup.likes}',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFE53935),
              ),
              _StatItem(
                label: 'Güç',
                value: '${lineup.power}/100',
                icon: Icons.bolt_rounded,
                color: const Color(0xFFFFB300),
              ),
              _StatItem(
                label: 'Yorum',
                value: '${lineup.commentsCount}',
                icon: Icons.comment_rounded,
                color: const Color(0xFF0F6A3D),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => context.push('/lineup-detail/${lineup.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'KADROYU İNCELE',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = rank == 1
        ? const Color(0xFFFFB300)
        : rank == 2
        ? const Color(0xFFC0C0C0)
        : rank == 3
        ? const Color(0xFFCD7F32)
        : Colors.white24;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

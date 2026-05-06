import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';

class TopLineupsScreen extends StatelessWidget {
  const TopLineupsScreen({super.key});

  static const String routePath = '/lineups/top';

  @override
  Widget build(BuildContext context) {
    final lineupRepository = LineupRepository();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.go('/home'),
            ),
            Expanded(
              child: StreamBuilder<List<LineupModel>>(
                stream: lineupRepository.watchTopLineups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final lineups = snapshot.data ?? [];

                  if (lineups.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz öne çıkan kadro yok.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    itemCount: lineups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lineup = lineups[index];

                      return _TopLineupCard(
                        rank: index + 1,
                        lineup: lineup,
                        onTap: () => context.go('/lineup-detail/${lineup.id}'),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const CircleAvatar(
            backgroundColor: Color(0xFFFFB300),
            child: Icon(Icons.emoji_events_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Haftanın Kadroları',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopLineupCard extends StatelessWidget {
  final int rank;
  final LineupModel lineup;
  final VoidCallback onTap;

  const _TopLineupCard({
    required this.rank,
    required this.lineup,
    required this.onTap,
  });

  Color get rankColor {
    if (rank == 1) return const Color(0xFFFFB300);
    if (rank == 2) return const Color(0xFFB3B3B3);
    if (rank == 3) return const Color(0xFFCD7F32);
    return const Color(0xFF0F6A3D);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: rank <= 3 ? rankColor : Colors.white10,
            width: rank <= 3 ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: rankColor.withValues(alpha: 0.18),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lineup.formation} Taraftar Kadrosu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Maç: ${lineup.matchId}',
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniBadge(
                        text: 'Güç ${lineup.power}/100',
                        color: const Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 8),
                      _MiniBadge(
                        text: '👍 ${lineup.likes}',
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

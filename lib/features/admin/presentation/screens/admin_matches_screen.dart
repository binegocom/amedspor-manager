import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../widgets/admin_layout.dart';

class AdminMatchesScreen extends StatelessWidget {
  const AdminMatchesScreen({super.key});

  static const String routePath = '/admin/matches';

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return AdminLayout(
      activeRoute: routePath,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;

                final title = const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maç Yönetimi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Maç ekle, listele ve skor durumunu yönet.',
                      style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
                    ),
                  ],
                );

                final button = SizedBox(
                  width: compact ? double.infinity : null,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/admin/matches/create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Maç Ekle',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 16), button],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    button,
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Expanded(
              child: StreamBuilder<List<MatchModel>>(
                stream: matchRepository.watchMatches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final matches = snapshot.data ?? [];

                  if (matches.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz maç eklenmedi.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: matches.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final match = matches[index];

                      return _AdminMatchCard(
                        match: match,
                        onEdit: () =>
                            context.go('/admin/matches/edit/${match.id}'),
                        onLineup: () => context.go('/lineup/${match.id}'),
                        onPrediction: () =>
                            context.go('/prediction/${match.id}'),
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

class _AdminMatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onEdit;
  final VoidCallback onLineup;
  final VoidCallback onPrediction;

  const _AdminMatchCard({
    required this.match,
    required this.onEdit,
    required this.onLineup,
    required this.onPrediction,
  });

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${match.matchDate.day}.${match.matchDate.month}.${match.matchDate.year}';
    final timeText =
        '${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}';

    final isFinished = match.status == 'finished';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final leading = CircleAvatar(
            radius: 28,
            backgroundColor: isFinished
                ? const Color(0xFF777777)
                : const Color(0xFF0F6A3D),
            child: const Icon(Icons.sports_soccer_rounded, color: Colors.white),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$dateText • $timeText',
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusBadge(
                    text: isFinished ? 'Tamamlandı' : 'Yaklaşan Maç',
                    color: isFinished
                        ? const Color(0xFF777777)
                        : const Color(0xFFE53935),
                  ),
                  if (match.score.isNotEmpty)
                    _StatusBadge(
                      text: 'Skor: ${match.score}',
                      color: const Color(0xFF0F6A3D),
                    ),
                ],
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onLineup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF0F6A3D)),
                ),
                child: const Text('Kadro'),
              ),
              OutlinedButton(
                onPressed: onPrediction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF0F6A3D)),
                ),
                child: const Text('Tahmin'),
              ),
              ElevatedButton.icon(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Düzenle'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 16),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(child: details),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

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
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

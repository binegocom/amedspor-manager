import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class MyLineupsScreen extends StatelessWidget {
  const MyLineupsScreen({super.key});

  static const String routePath = '/lineups/me';

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final lineupRepository = LineupRepository();

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
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.go('/profile')),
            Expanded(
              child: StreamBuilder<List<LineupModel>>(
                stream: lineupRepository.watchUserLineups(user.uid),
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
                        'Henüz kadro kaydetmedin.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    itemCount: lineups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lineup = lineups[index];

                      return _LineupCard(
                        lineup: lineup,
                        onTap: () => context.go('/lineup/${lineup.matchId}'),
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

  const _Header({required this.onBack});

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
          const Icon(Icons.sports_soccer_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Text(
            'Benim Kadrolarım',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineupCard extends StatelessWidget {
  final LineupModel lineup;
  final VoidCallback onTap;

  const _LineupCard({required this.lineup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hour = lineup.createdAt.hour.toString().padLeft(2, '0');
    final minute = lineup.createdAt.minute.toString().padLeft(2, '0');

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF0F6A3D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maç: ${lineup.matchId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${lineup.formation} • $hour:$minute',
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '👍 ${lineup.likes} beğeni',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/navigation_helpers.dart';

import '../../../../data/models/prediction_model.dart';
import '../../../../data/repositories/prediction_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class MyPredictionsScreen extends StatelessWidget {
  const MyPredictionsScreen({super.key});

  static const String routePath = '/predictions/me';

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
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
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.popOrGo('/profile')),

            StreamBuilder<List<PredictionModel>>(
              stream: predictionRepository.watchUserPredictions(user.uid),
              builder: (context, snapshot) {
                final predictions = snapshot.data ?? [];
                final totalPoints = predictions.fold<int>(
                  0,
                  (sum, item) => sum + item.pointsEarned,
                );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: _SummaryCard(totalPoints: totalPoints),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<List<PredictionModel>>(
                stream: predictionRepository.watchUserPredictions(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final predictions = snapshot.data ?? [];

                  if (predictions.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz tahmin yapmadın.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    itemCount: predictions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final prediction = predictions[index];

                      return _PredictionCard(
                        prediction: prediction,
                        onTap: () =>
                            context.push('/prediction/${prediction.matchId}'),
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
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Text(
            'Tahminlerim',
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

class _SummaryCard extends StatelessWidget {
  final int totalPoints;

  const _SummaryCard({required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6A3D), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE53935),
            child: Icon(
              Icons.leaderboard_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam Tahmin Puanı',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalPoints puan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
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

class _PredictionCard extends StatelessWidget {
  final PredictionModel prediction;
  final VoidCallback onTap;

  const _PredictionCard({required this.prediction, required this.onTap});

  Color get color {
    if (prediction.pointsEarned > 0) {
      return const Color(0xFF0F6A3D);
    }

    return const Color(0xFFFFB300);
  }

  String get statusText {
    if (prediction.pointsEarned > 0) {
      return 'Puan Kazandı';
    }

    return 'Bekleniyor';
  }

  IconData get icon {
    if (prediction.pointsEarned > 0) {
      return Icons.check_circle_rounded;
    }

    return Icons.hourglass_bottom_rounded;
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
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maç: ${prediction.matchId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Tahmin: ${prediction.homeScore} - ${prediction.awayScore} • İlk gol: ${prediction.firstScorer}',
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${prediction.pointsEarned} puan',
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

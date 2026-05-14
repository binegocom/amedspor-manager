import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/match_event_model.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/prediction_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../data/repositories/prediction_repository.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/premium_header.dart';

class MatchReportScreen extends StatelessWidget {
  final String matchId;

  const MatchReportScreen({super.key, required this.matchId});

  static const String routePath = '/match-report/:matchId';

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();
    final predictionRepository = PredictionRepository();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: StreamBuilder<MatchModel?>(
          stream: matchRepository.watchMatch(matchId),
          builder: (context, matchSnapshot) {
            if (matchSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }

            final match = matchSnapshot.data;
            if (match == null) {
              return const Center(
                child: Text(
                  'Maç bulunamadı.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return StreamBuilder<List<MatchEventModel>>(
              stream: matchRepository.watchMatchEvents(matchId),
              builder: (context, eventSnapshot) {
                final events = eventSnapshot.data ?? [];

                return StreamBuilder<List<PredictionModel>>(
                  stream: predictionRepository.watchMatchPredictions(matchId),
                  builder: (context, predictionSnapshot) {
                    final predictions = predictionSnapshot.data ?? [];

                    return CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(
                          child: PremiumHeader(
                            title: 'MAÇ RAPORU',
                            showBackButton: true,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _ReportScoreCard(match: match),
                              const SizedBox(height: 16),
                              _ReportStatsGrid(
                                events: events,
                                predictions: predictions,
                                match: match,
                              ),
                              const SizedBox(height: 16),
                              _MotmResultCard(match: match),
                              const SizedBox(height: 24),
                              _SectionHeader(
                                title: 'Maç Hikayesi',
                                actionLabel: match.isLive
                                    ? 'Canlı Merkez'
                                    : null,
                                onAction: match.isLive
                                    ? () => context.push(
                                        '/match-live/${match.id}',
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _EventTimeline(events: events),
                              const SizedBox(height: 24),
                              const _SectionHeader(title: 'Tahmin Özeti'),
                              const SizedBox(height: 12),
                              _PredictionSummary(
                                match: match,
                                predictions: predictions,
                              ),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReportScoreCard extends StatelessWidget {
  final MatchModel match;

  const _ReportScoreCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.card,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Text(
              match.isFinished ? 'MAÇ SONUCU' : _statusLabel(match.status),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _ReportTeam(name: match.homeTeam)),
                    Text(
                      '${match.homeScore} - ${match.awayScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Expanded(child: _ReportTeam(name: match.awayTeam)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _formatDateTime(match.matchDate),
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
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'live':
        return 'CANLI';
      case 'halftime':
        return 'DEVRE ARASI';
      case 'upcoming':
        return 'YAKLAŞAN MAÇ';
      default:
        return 'MAÇ ÖZETİ';
    }
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year - $hour:$minute';
  }
}

class _ReportTeam extends StatelessWidget {
  final String name;

  const _ReportTeam({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.shield, color: AppColors.muted, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ReportStatsGrid extends StatelessWidget {
  final List<MatchEventModel> events;
  final List<PredictionModel> predictions;
  final MatchModel match;

  const _ReportStatsGrid({
    required this.events,
    required this.predictions,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final goals = events.where((event) => event.type == 'goal').length;
    final cards = events
        .where((event) => event.type == 'yellowCard' || event.type == 'redCard')
        .length;
    final exactPredictions = predictions
        .where(
          (prediction) =>
              prediction.homeScore == match.homeScore &&
              prediction.awayScore == match.awayScore,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _ReportStatCard(
            icon: Icons.sports_soccer_rounded,
            label: 'Gol',
            value: '$goals',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ReportStatCard(
            icon: Icons.style_rounded,
            label: 'Kart',
            value: '$cards',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ReportStatCard(
            icon: Icons.fact_check_rounded,
            label: 'Tam İsabet',
            value: '$exactPredictions',
          ),
        ),
      ],
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReportStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 22),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h3),
          const SizedBox(height: 2),
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

class _MotmResultCard extends StatelessWidget {
  final MatchModel match;

  const _MotmResultCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final totalVotes = match.motmResults.values.fold<int>(
      0,
      (sum, votes) => sum + votes,
    );
    final sortedResults = match.motmResults.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final winner = sortedResults.isNotEmpty ? sortedResults.first : null;

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Maçın Oyuncusu', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  winner == null
                      ? 'Oylama sonucu henüz oluşmadı.'
                      : '${winner.key} - ${winner.value}/$totalVotes oy',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: AppTextStyles.label),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _EventTimeline extends StatelessWidget {
  final List<MatchEventModel> events;

  const _EventTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const PremiumCard(
        backgroundColor: AppColors.surface,
        child: Text(
          'Bu maç için olay kaydı bulunmuyor.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        children: events
            .map((event) => _ReportEventTile(event: event))
            .toList(growable: false),
      ),
    );
  }
}

class _ReportEventTile extends StatelessWidget {
  final MatchEventModel event;

  const _ReportEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final style = _eventStyle(event.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '${event.minute}\'',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(style.icon, color: style.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (event.playerNameOut != null &&
                    event.playerNameOut!.isNotEmpty)
                  Text(
                    'Çıkan: ${event.playerNameOut}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _EventStyle _eventStyle(String type) {
    switch (type) {
      case 'goal':
        return const _EventStyle(Icons.sports_soccer, AppColors.primaryGreen);
      case 'yellowCard':
        return const _EventStyle(Icons.square, AppColors.gold);
      case 'redCard':
        return const _EventStyle(Icons.square, AppColors.primaryRed);
      case 'substitution':
        return const _EventStyle(Icons.swap_vert_circle, Colors.blue);
      default:
        return const _EventStyle(Icons.info, AppColors.muted);
    }
  }
}

class _PredictionSummary extends StatelessWidget {
  final MatchModel match;
  final List<PredictionModel> predictions;

  const _PredictionSummary({required this.match, required this.predictions});

  @override
  Widget build(BuildContext context) {
    final exactPredictions = predictions
        .where(
          (prediction) =>
              prediction.homeScore == match.homeScore &&
              prediction.awayScore == match.awayScore,
        )
        .length;

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PredictionRow(
            label: 'Toplam tahmin',
            value: '${predictions.length}',
          ),
          const SizedBox(height: 10),
          _PredictionRow(label: 'Skoru bilen', value: '$exactPredictions'),
          const SizedBox(height: 10),
          _PredictionRow(
            label: 'Başarı oranı',
            value: predictions.isEmpty
                ? '-'
                : '%${((exactPredictions / predictions.length) * 100).round()}',
          ),
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final String label;
  final String value;

  const _PredictionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EventStyle {
  final IconData icon;
  final Color color;

  const _EventStyle(this.icon, this.color);
}

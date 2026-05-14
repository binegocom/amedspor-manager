import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/models/report_model.dart';
import '../widgets/admin_layout.dart';

class AdminQualityScreen extends StatelessWidget {
  const AdminQualityScreen({super.key});

  static const String routePath = '/admin/quality';

  Future<_QualitySnapshot> _loadQualitySnapshot() async {
    final db = FirebaseFirestore.instance;

    final matchesSnapshot = await db
        .collection('matches')
        .orderBy('matchDate', descending: true)
        .limit(50)
        .get();
    final reportsSnapshot = await db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    final errorsSnapshot = await db
        .collection('errorReports')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    final playersSnapshot = await db.collection('players').limit(100).get();

    final matches = matchesSnapshot.docs
        .map((doc) => MatchModel.fromFirestore(doc))
        .toList();
    final reports = reportsSnapshot.docs
        .map((doc) => ReportModel.fromMap(doc.id, doc.data()))
        .toList();
    final players = playersSnapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.id, doc.data()))
        .toList();
    final errors = errorsSnapshot.docs;

    final missingLogoMatches = matches
        .where((match) => match.homeLogo.isEmpty || match.awayLogo.isEmpty)
        .toList();
    final missingMotmMatches = matches
        .where(
          (match) =>
              (match.isLive || match.isFinished) &&
              match.motmCandidates.isEmpty,
        )
        .toList();
    final finishedMatches = matches.where((match) => match.isFinished).toList();
    final finishedWithoutEvents = <MatchModel>[];

    for (final match in finishedMatches.take(20)) {
      final eventSnapshot = await db
          .collection('matches')
          .doc(match.id)
          .collection('events')
          .limit(1)
          .get();
      if (eventSnapshot.docs.isEmpty) {
        finishedWithoutEvents.add(match);
      }
    }

    final pendingReports = reports
        .where(
          (report) => report.status == 'reviewing' || report.status == 'open',
        )
        .toList();
    final openErrors = errors.where((doc) {
      final data = doc.data();
      final status = data['status'] ?? 'open';
      return status == 'open' || status == 'investigating';
    }).toList();
    final incompletePlayers = players
        .where(
          (player) =>
              player.name.trim().isEmpty ||
              player.position.trim().isEmpty ||
              player.number <= 0 ||
              player.rating <= 0,
        )
        .toList();

    return _QualitySnapshot(
      missingLogoMatches: missingLogoMatches,
      missingMotmMatches: missingMotmMatches,
      finishedWithoutEvents: finishedWithoutEvents,
      pendingReports: pendingReports,
      openErrors: openErrors,
      incompletePlayers: incompletePlayers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: routePath,
      title: 'Kalite Kontrol',
      subtitle:
          'Eksik veri, moderasyon kuyruğu ve hata durumlarını tek ekranda izle.',
      child: FutureBuilder<_QualitySnapshot>(
        future: _loadQualitySnapshot(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Kalite raporu yüklenemedi: ${snapshot.error}',
                style: const TextStyle(color: AppColors.muted),
              ),
            );
          }

          final data = snapshot.data ?? _QualitySnapshot.empty();

          return RefreshIndicator(
            color: AppColors.primaryRed,
            onRefresh: () async {
              // FutureBuilder refreshes when this widget rebuilds through route revisit.
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              children: [
                _HealthSummary(snapshot: data),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1200
                        ? 3
                        : constraints.maxWidth >= 760
                        ? 2
                        : 1;

                    return GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: columns == 1 ? 2.2 : 1.45,
                      children: [
                        _QualityCard(
                          title: 'Eksik Logo',
                          count: data.missingLogoMatches.length,
                          icon: Icons.image_not_supported_rounded,
                          color: AppColors.gold,
                          route: '/admin/matches',
                          items: data.missingLogoMatches
                              .map(
                                (match) =>
                                    '${match.homeTeam} - ${match.awayTeam}',
                              )
                              .toList(),
                        ),
                        _QualityCard(
                          title: 'MOTM Adayı Yok',
                          count: data.missingMotmMatches.length,
                          icon: Icons.stars_rounded,
                          color: AppColors.primaryRed,
                          route: '/admin/matches',
                          items: data.missingMotmMatches
                              .map(
                                (match) =>
                                    '${match.homeTeam} - ${match.awayTeam}',
                              )
                              .toList(),
                        ),
                        _QualityCard(
                          title: 'Raporsuz Biten Maç',
                          count: data.finishedWithoutEvents.length,
                          icon: Icons.fact_check_outlined,
                          color: const Color(0xFF2E7DFF),
                          route: '/admin/matches',
                          items: data.finishedWithoutEvents
                              .map(
                                (match) =>
                                    '${match.homeTeam} - ${match.awayTeam}',
                              )
                              .toList(),
                        ),
                        _QualityCard(
                          title: 'Bekleyen Rapor',
                          count: data.pendingReports.length,
                          icon: Icons.gavel_rounded,
                          color: AppColors.primaryRed,
                          route: '/admin/reports',
                          items: data.pendingReports
                              .map(
                                (report) =>
                                    '${report.targetType}: ${report.reason}',
                              )
                              .toList(),
                        ),
                        _QualityCard(
                          title: 'Açık Hata',
                          count: data.openErrors.length,
                          icon: Icons.bug_report_rounded,
                          color: AppColors.gold,
                          route: '/admin/errors',
                          items: data.openErrors.map((doc) {
                            final data = doc.data();
                            return (data['error'] ?? 'Bilinmeyen hata')
                                .toString();
                          }).toList(),
                        ),
                        _QualityCard(
                          title: 'Eksik Oyuncu',
                          count: data.incompletePlayers.length,
                          icon: Icons.person_search_rounded,
                          color: AppColors.primaryGreen,
                          route: '/admin/players',
                          items: data.incompletePlayers
                              .map(
                                (player) => player.name.isEmpty
                                    ? player.id
                                    : player.name,
                              )
                              .toList(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ActionQueue(snapshot: data),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  final _QualitySnapshot snapshot;

  const _HealthSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final issueCount = snapshot.totalIssues;
    final color = issueCount == 0
        ? AppColors.primaryGreen
        : issueCount < 5
        ? AppColors.gold
        : AppColors.primaryRed;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(
              issueCount == 0
                  ? Icons.verified_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issueCount == 0
                      ? 'Sistem temiz görünüyor'
                      : '$issueCount aksiyon bekliyor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Maç verisi, moderasyon, hata raporları ve oyuncu kalitesi kontrol edildi.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String route;
  final List<String> items;

  const _QualityCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.route,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: count == 0 ? Colors.white10 : color.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    color: count == 0 ? AppColors.muted : color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (visibleItems.isEmpty)
              const Text(
                'Aksiyon gerekmiyor.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              )
            else
              ...visibleItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionQueue extends StatelessWidget {
  final _QualitySnapshot snapshot;

  const _ActionQueue({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final actions = <_QueueAction>[
      ...snapshot.pendingReports
          .take(3)
          .map(
            (report) => _QueueAction(
              icon: Icons.gavel_rounded,
              title: 'Rapor incele',
              subtitle: '${report.targetType}: ${report.reason}',
              route: '/admin/reports',
              color: AppColors.primaryRed,
            ),
          ),
      ...snapshot.openErrors.take(3).map((doc) {
        final data = doc.data();
        return _QueueAction(
          icon: Icons.bug_report_rounded,
          title: 'Hata raporunu kontrol et',
          subtitle: (data['error'] ?? 'Bilinmeyen hata').toString(),
          route: '/admin/errors',
          color: AppColors.gold,
        );
      }),
      ...snapshot.finishedWithoutEvents
          .take(3)
          .map(
            (match) => _QueueAction(
              icon: Icons.fact_check_outlined,
              title: 'Maç hikayesi eksik',
              subtitle: '${match.homeTeam} - ${match.awayTeam}',
              route: '/admin/matches/live/${match.id}',
              color: const Color(0xFF2E7DFF),
            ),
          ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Öncelikli Kuyruk',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (actions.isEmpty)
            const Text(
              'Öncelikli aksiyon bulunmuyor.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ...actions.map((action) => _QueueTile(action: action)),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final _QueueAction action;

  const _QueueTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: action.color.withValues(alpha: 0.16),
        child: Icon(action.icon, color: action.color),
      ),
      title: Text(
        action.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        action.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.muted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: () => context.go(action.route),
    );
  }
}

class _QualitySnapshot {
  final List<MatchModel> missingLogoMatches;
  final List<MatchModel> missingMotmMatches;
  final List<MatchModel> finishedWithoutEvents;
  final List<ReportModel> pendingReports;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> openErrors;
  final List<PlayerModel> incompletePlayers;

  const _QualitySnapshot({
    required this.missingLogoMatches,
    required this.missingMotmMatches,
    required this.finishedWithoutEvents,
    required this.pendingReports,
    required this.openErrors,
    required this.incompletePlayers,
  });

  factory _QualitySnapshot.empty() {
    return const _QualitySnapshot(
      missingLogoMatches: [],
      missingMotmMatches: [],
      finishedWithoutEvents: [],
      pendingReports: [],
      openErrors: [],
      incompletePlayers: [],
    );
  }

  int get totalIssues =>
      missingLogoMatches.length +
      missingMotmMatches.length +
      finishedWithoutEvents.length +
      pendingReports.length +
      openErrors.length +
      incompletePlayers.length;
}

class _QueueAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const _QueueAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}

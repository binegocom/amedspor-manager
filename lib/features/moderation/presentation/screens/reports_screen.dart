import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/navigation_helpers.dart';

import '../../../../data/models/report_model.dart';
import '../../../../data/repositories/report_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const String routePath = '/reports';

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final reportRepository = ReportRepository();

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
            _Header(onBack: () => context.popOrGo('/settings')),

            StreamBuilder<List<ReportModel>>(
              stream: reportRepository.watchUserReports(user.uid),
              builder: (context, snapshot) {
                final reports = snapshot.data ?? [];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: _InfoCard(total: reports.length),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<List<ReportModel>>(
                stream: reportRepository.watchUserReports(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final reports = snapshot.data ?? [];

                  if (reports.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = reports[index];

                      return _ReportCard(report: report);
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
          const Icon(Icons.report_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Text(
            'Raporlarım',
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

class _InfoCard extends StatelessWidget {
  final int total;

  const _InfoCard({required this.total});

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
            child: Icon(Icons.shield_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topluluk Güvenliği',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total rapor gönderildi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
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

class _ReportCard extends StatelessWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

  Color get color {
    if (report.status == 'resolved') return const Color(0xFF0F6A3D);
    if (report.status == 'rejected') return const Color(0xFFE53935);
    return const Color(0xFFFFB300);
  }

  String get statusText {
    if (report.status == 'resolved') return 'Çözüldü';
    if (report.status == 'rejected') return 'Reddedildi';
    return 'İnceleniyor';
  }

  IconData get icon {
    if (report.status == 'resolved') return Icons.check_circle_rounded;
    if (report.status == 'rejected') return Icons.cancel_rounded;
    return Icons.hourglass_bottom_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hour = report.createdAt.hour.toString().padLeft(2, '0');
    final minute = report.createdAt.minute.toString().padLeft(2, '0');

    return Container(
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
                  '${report.targetType} Raporu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${report.reason} • $hour:$minute',
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Henüz rapor bulunmuyor.',
        style: TextStyle(color: Color(0xFFB3B3B3), fontWeight: FontWeight.w600),
      ),
    );
  }
}

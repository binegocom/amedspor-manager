import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/report_model.dart';
import '../../../../data/repositories/report_repository.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  static const String routePath = '/admin/moderation';

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  String selectedFilter = 'Bekleyen';

  final reportRepository = ReportRepository();

  final List<String> filters = const ['Bekleyen', 'Çözülen', 'Reddedilen'];

  List<ReportModel> _filterReports(List<ReportModel> reports) {
    return reports.where((report) {
      if (selectedFilter == 'Bekleyen') {
        return report.status == 'reviewing';
      }

      if (selectedFilter == 'Çözülen') {
        return report.status == 'resolved';
      }

      return report.status == 'rejected';
    }).toList();
  }

  void _showActionSheet(ReportModel report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFFE53935),
                size: 46,
              ),
              const SizedBox(height: 16),
              const Text(
                'Moderasyon İşlemi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${report.targetType} için işlem seç.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
              ),
              const SizedBox(height: 22),
              _ActionButton(
                title: 'İçeriği Kaldır',
                icon: Icons.delete_rounded,
                color: const Color(0xFFE53935),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                title: 'Kullanıcıyı Sustur',
                icon: Icons.volume_off_rounded,
                color: const Color(0xFFFFB300),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                title: 'Raporu Reddet',
                icon: Icons.close_rounded,
                color: const Color(0xFF777777),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    if (status == 'resolved') return const Color(0xFF0F6A3D);
    if (status == 'rejected') return const Color(0xFFE53935);
    return const Color(0xFFFFB300);
  }

  String _statusText(String status) {
    if (status == 'resolved') return 'Çözüldü';
    if (status == 'rejected') return 'Reddedildi';
    return 'Bekliyor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.go('/settings')),

            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final filter = filters[index];

                  return _FilterChip(
                    title: filter,
                    active: selectedFilter == filter,
                    onTap: () => setState(() => selectedFilter = filter),
                  );
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<List<ReportModel>>(
                stream: reportRepository.watchAllReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final reports = _filterReports(snapshot.data ?? []);

                  if (reports.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = reports[index];

                      return _ReportCard(
                        report: report,
                        color: _statusColor(report.status),
                        statusText: _statusText(report.status),
                        onTap: () => _showActionSheet(report),
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
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: Color(0xFFE53935),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Admin Moderasyon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F6A3D) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? const Color(0xFF0F6A3D) : Colors.white10,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB3B3B3),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final Color color;
  final String statusText;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.color,
    required this.statusText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = report.detail.isEmpty ? 'Ek açıklama yok.' : report.detail;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(Icons.flag_rounded, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${report.targetType} • ${report.reason}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
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
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Raporlayan ID: ${report.reporterId}',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
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
        'Bu filtrede rapor bulunmuyor.',
        style: TextStyle(color: Color(0xFFB3B3B3), fontWeight: FontWeight.w600),
      ),
    );
  }
}

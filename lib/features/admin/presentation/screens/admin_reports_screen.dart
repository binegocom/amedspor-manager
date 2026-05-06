import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/report_model.dart';
import '../../../../data/repositories/report_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import 'package:amedspor_app/features/admin/presentation/widgets/admin_layout.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  static const String routePath = '/admin/reports';

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final reportRepository = ReportRepository();

  String selectedFilter = 'reviewing';


  List<ReportModel> _filterReports(List<ReportModel> reports) {
    if (selectedFilter == 'all') return reports;
    return reports.where((report) => report.status == selectedFilter).toList();
  }

  Future<void> _updateReportStatus({
    required ReportModel report,
    required String status,
  }) async {
    try {
      await firestoreService.reports.doc(report.id).update({'status': status});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F6A3D),
          content: Text('Rapor durumu $status olarak güncellendi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Rapor güncelleme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _deleteTarget(ReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'İçerik silinsin mi?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '${report.targetType}/${report.targetId} kalıcı olarak silinecek.',
            style: const TextStyle(color: Color(0xFFB3B3B3)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sil',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      if (report.targetType == 'post') {
        await firestoreService.posts.doc(report.targetId).delete();
      }

      if (report.targetType == 'user') {
        await firestoreService.users.doc(report.targetId).update({
          'disabled': true,
        });
      }

      await firestoreService.reports.doc(report.id).update({
        'status': 'resolved',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('İşlem tamamlandı.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('İşlem hatası: $e'),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    if (status == 'resolved') return const Color(0xFF0F6A3D);
    if (status == 'rejected') return const Color(0xFFE53935);
    return const Color(0xFFFFB300);
  }

  String _statusText(String status) {
    if (status == 'resolved') return 'Çözüldü';
    if (status == 'rejected') return 'Reddedildi';
    return 'İnceleniyor';
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminReportsScreen.routePath,
      title: 'Rapor Yönetimi',
      subtitle: 'Kullanıcı şikayetlerini incele, çöz veya reddet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Wrap(
              spacing: 10,
              children: [
                _FilterChip(
                  title: 'İnceleniyor',
                  active: selectedFilter == 'reviewing',
                  onTap: () {
                    setState(() => selectedFilter = 'reviewing');
                  },
                ),
                _FilterChip(
                  title: 'Çözüldü',
                  active: selectedFilter == 'resolved',
                  onTap: () {
                    setState(() => selectedFilter = 'resolved');
                  },
                ),
                _FilterChip(
                  title: 'Reddedildi',
                  active: selectedFilter == 'rejected',
                  onTap: () {
                    setState(() => selectedFilter = 'rejected');
                  },
                ),
                _FilterChip(
                  title: 'Tümü',
                  active: selectedFilter == 'all',
                  onTap: () {
                    setState(() => selectedFilter = 'all');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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

                final reports = _filterReports(
                  snapshot.data ?? [],
                );

                if (reports.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu filtrede rapor bulunmuyor.',
                      style: TextStyle(
                        color: Color(0xFFB3B3B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  itemCount: reports.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final report = reports[index];

                    return _AdminReportCard(
                      report: report,
                      statusColor: _statusColor(report.status),
                      statusText: _statusText(report.status),
                      onOpenTarget: () {
                        if (report.targetType == 'post') {
                          context.go(
                            '/post/${report.targetId}',
                          );
                        } else if (report.targetType == 'user') {
                          context.go(
                            '/profile/${report.targetId}',
                          );
                        }
                      },
                      onResolve: () {
                        _updateReportStatus(
                          report: report,
                          status: 'resolved',
                        );
                      },
                      onReject: () {
                        _updateReportStatus(
                          report: report,
                          status: 'rejected',
                        );
                      },
                      onDeleteTarget: () => _deleteTarget(report),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final ReportModel report;
  final Color statusColor;
  final String statusText;
  final VoidCallback onOpenTarget;
  final VoidCallback onResolve;
  final VoidCallback onReject;
  final VoidCallback onDeleteTarget;

  const _AdminReportCard({
    required this.report,
    required this.statusColor,
    required this.statusText,
    required this.onOpenTarget,
    required this.onResolve,
    required this.onReject,
    required this.onDeleteTarget,
  });

  @override
  Widget build(BuildContext context) {
    final hour = report.createdAt.hour.toString().padLeft(2, '0');
    final minute = report.createdAt.minute.toString().padLeft(2, '0');
    final detail = report.detail.isEmpty ? 'Ek açıklama yok.' : report.detail;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 800;

          final leading = CircleAvatar(
            radius: 28,
            backgroundColor: statusColor.withValues(alpha: 0.18),
            child: Icon(Icons.flag_rounded, color: statusColor),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MiniBadge(text: statusText, color: statusColor),
                  _MiniBadge(
                    text: report.targetType,
                    color: const Color(0xFF0F6A3D),
                  ),
                  Text(
                    '$hour:$minute',
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.reason,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                'Raporlayan ID: ${report.reporterId}',
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hedef: ${report.targetType}/${report.targetId}',
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenTarget,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF0F6A3D)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Hedef'),
              ),
              OutlinedButton.icon(
                onPressed: onResolve,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F6A3D),
                  side: const BorderSide(color: Color(0xFF0F6A3D)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Çöz'),
              ),
              OutlinedButton.icon(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFB300),
                  side: const BorderSide(color: Color(0xFFFFB300)),
                ),
                icon: const Icon(Icons.cancel_rounded, size: 18),
                label: const Text('Reddet'),
              ),
              OutlinedButton.icon(
                onPressed: onDeleteTarget,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                ),
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('İşlem'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F6A3D) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? const Color(0xFF0F6A3D) : Colors.white10,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB3B3B3),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({required this.text, required this.color});

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


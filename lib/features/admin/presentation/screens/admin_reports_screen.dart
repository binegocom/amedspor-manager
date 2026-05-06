import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/report_model.dart';
import '../../../../data/repositories/report_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_sidebar.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  static const String routePath = '/admin/reports';

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final reportRepository = ReportRepository();

  String selectedFilter = 'reviewing';

  Future<bool> _isAdminOrModerator() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final doc = await firestoreService.users.doc(user.uid).get();
    final role = doc.data()?['role'];

    return role == 'admin' || role == 'moderator';
  }

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
    return FutureBuilder<bool>(
      future: _isAdminOrModerator(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }

        if (adminSnapshot.data != true) {
          return Scaffold(
            backgroundColor: const Color(0xFF0E0E0E),
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Admin girişi yap'),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;

            return Scaffold(
              backgroundColor: const Color(0xFF0E0E0E),
              appBar: compact
                  ? AppBar(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      title: const Text('Rapor Yönetimi'),
                    )
                  : null,
              drawer: compact
                  ? const Drawer(
                      backgroundColor: Color(0xFF111111),
                      child: AdminSidebar(
                        activeRoute: AdminReportsScreen.routePath,
                        width: double.infinity,
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!compact) const _AdminSidebar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rapor Yönetimi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Kullanıcı şikayetlerini incele, çöz veya reddet.',
                            style: TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Wrap(
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

                          const SizedBox(height: 24),

                          Expanded(
                            child: StreamBuilder<List<ReportModel>>(
                              stream: reportRepository.watchAllReports(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
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
                                        } else if (report.targetType ==
                                            'user') {
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
                                      onDeleteTarget: () =>
                                          _deleteTarget(report),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AMEDSPOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Admin Panel',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            onTap: () => context.go('/admin/dashboard'),
          ),
          _SidebarItem(
            icon: Icons.sports_soccer_rounded,
            title: 'Maçlar',
            onTap: () => context.go('/admin/matches'),
          ),
          _SidebarItem(
            icon: Icons.people_rounded,
            title: 'Kullanıcılar',
            onTap: () => context.go('/admin/users'),
          ),
          _SidebarItem(
            icon: Icons.article_rounded,
            title: 'Postlar',
            onTap: () => context.go('/admin/posts'),
          ),
          _SidebarItem(
            icon: Icons.report_rounded,
            title: 'Raporlar',
            active: true,
            onTap: () => context.go('/admin/reports'),
          ),
          _SidebarItem(
            icon: Icons.notifications_rounded,
            title: 'Bildirim',
            onTap: () => context.go('/admin/notifications'),
          ),
          _SidebarItem(
            icon: Icons.forum_rounded,
            title: 'Sohbet',
            onTap: () => context.go('/admin/chats'),
          ),
          _SidebarItem(
            icon: Icons.emoji_events_rounded,
            title: 'Tahminler',
            onTap: () => context.go('/admin/predictions'),
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            title: 'Ayarlar',
            onTap: () => context.go('/admin/settings'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authService.signOut();
                if (!context.mounted) return;
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFE53935)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool active;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: active ? const Color(0xFF0F6A3D) : Colors.transparent,
        leading: Icon(
          icon,
          color: active ? Colors.white : const Color(0xFFB3B3B3),
        ),
        title: Text(
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

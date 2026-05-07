import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/repositories/error_report_repository.dart';
import '../widgets/admin_layout.dart';
import 'package:intl/intl.dart';

class AdminErrorsScreen extends StatefulWidget {
  const AdminErrorsScreen({super.key});

  static const String routePath = '/admin/errors';

  @override
  State<AdminErrorsScreen> createState() => _AdminErrorsScreenState();
}

class _AdminErrorsScreenState extends State<AdminErrorsScreen> {
  final _repository = ErrorReportRepository();
  final List<DocumentSnapshot> _docs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _repository.getErrorReportsPaginated(
        limit: 20,
        lastDocument: _docs.isEmpty ? null : _docs.last,
      );

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _docs.addAll(snapshot.docs);
        _isLoading = false;
        if (snapshot.docs.length < 20) _hasMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _repository.updateStatus(id, status);
      setState(() {
        // Find and update local doc data for immediate UI feedback
        final index = _docs.indexWhere((doc) => doc.id == id);
        if (index != -1) {
          // Note: In a real app with models, this is easier. 
          // Here we are working with DocumentSnapshots, so we might just reload or 
          // accept that the next load will have it. 
          // For simplicity, let's just show a snackbar and let the user refresh or wait.
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Durum güncellendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminErrorsScreen.routePath,
      title: 'Hata Merkezi',
      subtitle: 'Sistem hatalarını takip et, kullanıcı bildirimlerini incele ve çözüme kavuştur.',
      child: _docs.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _docs.isEmpty
              ? const Center(child: Text('Henüz bir hata raporu yok.', style: TextStyle(color: AppColors.muted)))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  itemCount: _docs.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _docs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: AppColors.primaryRed),
                        ),
                      );
                    }

                    final data = _docs[index].data() as Map<String, dynamic>;
                    final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final isFatal = data['fatal'] ?? false;
                    final status = data['status'] ?? 'open';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFatal ? AppColors.errorRed.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ExpansionTile(
                        iconColor: Colors.white,
                        collapsedIconColor: AppColors.muted,
                        leading: CircleAvatar(
                          backgroundColor: isFatal ? AppColors.errorRed.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                          child: Icon(
                            isFatal ? Icons.error_rounded : Icons.warning_rounded,
                            color: isFatal ? AppColors.errorRed : Colors.amber,
                          ),
                        ),
                        title: Text(
                          data['error'] ?? 'Bilinmeyen Hata',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM HH:mm').format(date)} • ${data['platform']} • v${data['appVersion']}',
                          style: AppTextStyles.label.copyWith(color: AppColors.muted),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        expandedAlignment: Alignment.topLeft,
                        children: [
                          if (data['userEmail'] != null) ...[
                            _DetailRow(label: 'Kullanıcı:', value: data['userEmail']),
                            const SizedBox(height: 8),
                          ],
                          if (data['reason'] != null) ...[
                            _DetailRow(label: 'Sebep:', value: data['reason']),
                            const SizedBox(height: 8),
                          ],
                          const Text(
                            'Stacktrace:',
                            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['stackTrace'] ?? 'Stacktrace bulunamadı.',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (status == 'open')
                                TextButton(
                                  onPressed: () => _updateStatus(_docs[index].id, 'investigating'),
                                  child: const Text('İNCELEMEYE AL'),
                                ),
                              if (status != 'resolved')
                                TextButton(
                                  onPressed: () => _updateStatus(_docs[index].id, 'resolved'),
                                  child: const Text('ÇÖZÜLDÜ', style: TextStyle(color: Colors.green)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'investigating':
        return Colors.amber;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/audit_log_repository.dart';
import '../widgets/admin_layout.dart';
import 'package:intl/intl.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  static const String routePath = '/admin/audit-logs';

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final _repository = AuditLogRepository();
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _repository.getAuditLogsPaginated(
        limit: 50,
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
        if (snapshot.docs.length < 50) _hasMore = false;
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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminAuditLogsScreen.routePath,
      title: 'İşlem Günlüğü',
      subtitle: 'Yönetici ve moderatörlerin sistem üzerindeki tüm kritik aksiyonları.',
      child: Column(
        children: [
          Expanded(
            child: _docs.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : _docs.isEmpty
                    ? const Center(child: Text('Henüz bir log kaydı yok.', style: TextStyle(color: AppColors.muted)))
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        itemCount: _docs.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _docs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.primaryRed),
                              ),
                            );
                          }

                          final data = _docs[index].data() as Map<String, dynamic>;
                          final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                          final action = data['action'] ?? '';
                          final isDelete = action.toLowerCase().contains('delete');

                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isDelete ? AppColors.errorRed.withValues(alpha: 0.1) : AppColors.primaryGreen.withValues(alpha: 0.1),
                                child: Icon(
                                  isDelete ? Icons.delete_sweep_rounded : Icons.edit_note_rounded,
                                  color: isDelete ? AppColors.errorRed : AppColors.primaryGreen,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    data['adminEmail'] ?? 'Bilinmeyen Admin',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      data['platform']?.toUpperCase() ?? 'WEB',
                                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${data['action']} -> ${data['targetType']} (${data['targetId']})\n${DateFormat('dd MMM yyyy, HH:mm:ss').format(date)}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/admin_layout.dart';
import 'package:intl/intl.dart';

class AdminErrorsScreen extends StatelessWidget {
  const AdminErrorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Hata Merkezi',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('errorReports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Henüz bir hata raporu yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final isFatal = data['fatal'] ?? false;
              final status = data['status'] ?? 'open';

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFatal ? AppColors.error.withOpacity(0.3) : Colors.white10,
                  ),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isFatal ? AppColors.error.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                    child: Icon(
                      isFatal ? Icons.error_rounded : Icons.warning_rounded,
                      color: isFatal ? AppColors.error : Colors.amber,
                    ),
                  ),
                  title: Text(
                    data['error'] ?? 'Bilinmeyen Hata',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h4,
                  ),
                  subtitle: Text(
                    '${DateFormat('dd/MM HH:mm').format(date)} • ${data['platform']} • v${data['appVersion']}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
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
                            onPressed: () => _updateStatus(docs[index].id, 'investigating'),
                            child: const Text('İNCELEMEYE AL'),
                          ),
                        if (status != 'resolved')
                          TextButton(
                            onPressed: () => _updateStatus(docs[index].id, 'resolved'),
                            child: const Text('ÇÖZÜLDÜ', style: TextStyle(color: Colors.green)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
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

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('errorReports').doc(id).update({
      'status': status,
    });
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

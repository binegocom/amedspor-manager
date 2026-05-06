import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/prediction_model.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class AdminPredictionsScreen extends StatefulWidget {
  const AdminPredictionsScreen({super.key});

  static const String routePath = '/admin/predictions';

  @override
  State<AdminPredictionsScreen> createState() => _AdminPredictionsScreenState();
}

class _AdminPredictionsScreenState extends State<AdminPredictionsScreen> {
  String selectedFilter = 'all';

  Stream<List<PredictionModel>> _watchPredictions() {
    return firestoreService.predictions
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PredictionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  List<PredictionModel> _filterPredictions(List<PredictionModel> predictions) {
    if (selectedFilter == 'scored') {
      return predictions.where((item) => item.pointsEarned > 0).toList();
    }

    if (selectedFilter == 'pending') {
      return predictions.where((item) => item.pointsEarned == 0).toList();
    }

    return predictions;
  }

  Future<void> _updatePredictionPoints({
    required PredictionModel prediction,
    required int points,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final predictionRef =
            firestoreService.predictions.doc(prediction.id);
        final userRef = firestoreService.users.doc(prediction.userId);

        final predictionDoc = await transaction.get(predictionRef);
        final oldPoints = predictionDoc.data()?['pointsEarned'] ?? 0;

        transaction.update(predictionRef, {
          'pointsEarned': points,
        });

        transaction.update(userRef, {
          'points': FieldValue.increment(points - oldPoints),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Tahmin puanı güncellendi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Puan güncelleme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _openPointDialog(PredictionModel prediction) async {
    final controller = TextEditingController(
      text: prediction.pointsEarned.toString(),
    );

    final points = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Tahmin Puanı Gir',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFFE53935),
            decoration: InputDecoration(
              labelText: 'Puan',
              labelStyle: const TextStyle(color: Color(0xFFB3B3B3)),
              filled: true,
              fillColor: const Color(0xFF111111),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE53935)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim()) ?? 0;
                Navigator.pop(context, value);
              },
              child: const Text(
                'Kaydet',
                style: TextStyle(color: Color(0xFF0F6A3D)),
              ),
            ),
          ],
        );
      },
    );

    if (points == null) return;

    await _updatePredictionPoints(
      prediction: prediction,
      points: points,
    );
  }

  Future<void> _deletePrediction(PredictionModel prediction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Tahmin silinsin mi?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Bu tahmin kalıcı olarak silinecek. Kullanıcı puanı da geri alınacak.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
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
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final predictionRef =
            firestoreService.predictions.doc(prediction.id);
        final userRef = firestoreService.users.doc(prediction.userId);

        transaction.delete(predictionRef);

        if (prediction.pointsEarned > 0) {
          transaction.update(userRef, {
            'points': FieldValue.increment(-prediction.pointsEarned),
          });
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Tahmin silindi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Tahmin silme hatası: $e'),
        ),
      );
    }
  }

  Color _statusColor(PredictionModel prediction) {
    if (prediction.pointsEarned > 0) return const Color(0xFF0F6A3D);
    return const Color(0xFFFFB300);
  }

  String _statusText(PredictionModel prediction) {
    if (prediction.pointsEarned > 0) return 'Puanlandı';
    return 'Bekliyor';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: Text(
            'Admin panel sadece web üzerinde kullanılabilir.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          const _AdminSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tahmin Yönetimi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kullanıcı tahminlerini görüntüle, puan gir ve sıralamayı güncelle.',
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
                        title: 'Tümü',
                        active: selectedFilter == 'all',
                        onTap: () => setState(() => selectedFilter = 'all'),
                      ),
                      _FilterChip(
                        title: 'Bekleyen',
                        active: selectedFilter == 'pending',
                        onTap: () => setState(() => selectedFilter = 'pending'),
                      ),
                      _FilterChip(
                        title: 'Puanlanan',
                        active: selectedFilter == 'scored',
                        onTap: () => setState(() => selectedFilter = 'scored'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: StreamBuilder<List<PredictionModel>>(
                      stream: _watchPredictions(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE53935),
                            ),
                          );
                        }

                        final predictions =
                            _filterPredictions(snapshot.data ?? []);

                        if (predictions.isEmpty) {
                          return const Center(
                            child: Text(
                              'Tahmin bulunamadı.',
                              style: TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: predictions.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final prediction = predictions[index];

                            return _PredictionAdminCard(
                              prediction: prediction,
                              statusColor: _statusColor(prediction),
                              statusText: _statusText(prediction),
                              onOpenMatch: () {
                                context.go(
                                  '/prediction/${prediction.matchId}',
                                );
                              },
                              onEditPoints: () {
                                _openPointDialog(prediction);
                              },
                              onDelete: () {
                                _deletePrediction(prediction);
                              },
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
  }
}

class _PredictionAdminCard extends StatelessWidget {
  final PredictionModel prediction;
  final Color statusColor;
  final String statusText;
  final VoidCallback onOpenMatch;
  final VoidCallback onEditPoints;
  final VoidCallback onDelete;

  const _PredictionAdminCard({
    required this.prediction,
    required this.statusColor,
    required this.statusText,
    required this.onOpenMatch,
    required this.onEditPoints,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hour = prediction.createdAt.hour.toString().padLeft(2, '0');
    final minute = prediction.createdAt.minute.toString().padLeft(2, '0');

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
            backgroundColor: statusColor.withValues(alpha: 0.18),
            child: Icon(Icons.emoji_events_rounded, color: statusColor),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniBadge(text: statusText, color: statusColor),
                    const SizedBox(width: 8),
                    _MiniBadge(
                      text: 'Maç: ${prediction.matchId}',
                      color: const Color(0xFF0F6A3D),
                    ),
                    const SizedBox(width: 8),
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
                  'Tahmin: ${prediction.homeScore} - ${prediction.awayScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'İlk gol: ${prediction.firstScorer.isEmpty ? 'Seçilmedi' : prediction.firstScorer}',
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kullanıcı ID: ${prediction.userId}',
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Text(
            '${prediction.pointsEarned} puan',
            style: const TextStyle(
              color: Color(0xFFFFB300),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(width: 14),

          OutlinedButton.icon(
            onPressed: onOpenMatch,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF0F6A3D)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Aç'),
          ),

          const SizedBox(width: 8),

          ElevatedButton.icon(
            onPressed: onEditPoints,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Puan'),
          ),

          const SizedBox(width: 8),

          OutlinedButton.icon(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Sil'),
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

  const _MiniBadge({
    required this.text,
    required this.color,
  });

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
            active: true,
            onTap: () => context.go('/admin/predictions'),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
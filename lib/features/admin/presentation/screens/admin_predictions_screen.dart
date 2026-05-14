import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/prediction_repository.dart';
import '../../../../data/models/prediction_model.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_layout.dart';

class AdminPredictionsScreen extends StatefulWidget {
  const AdminPredictionsScreen({super.key});

  static const String routePath = '/admin/predictions';

  @override
  State<AdminPredictionsScreen> createState() => _AdminPredictionsScreenState();
}

class _AdminPredictionsScreenState extends State<AdminPredictionsScreen> {
  final _repository = PredictionRepository();
  final List<DocumentSnapshot> _docs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String selectedFilter = 'all';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _repository.getPredictionsSnapshotPaginated(
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

  List<DocumentSnapshot> _filterDocs() {
    if (selectedFilter == 'scored') {
      return _docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['pointsEarned'] ?? 0) > 0;
      }).toList();
    }

    if (selectedFilter == 'pending') {
      return _docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['pointsEarned'] ?? 0) == 0;
      }).toList();
    }

    return _docs;
  }

  Future<void> _updatePredictionPoints({
    required PredictionModel prediction,
    required int points,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final predictionRef = firestoreService.predictions.doc(prediction.id);

        await transaction.get(predictionRef);

        transaction.update(predictionRef, {'pointsEarned': points});
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

    await _updatePredictionPoints(prediction: prediction, points: points);

    // Refresh list locally or wait for re-fetch (simplest is re-fetch or manual update)
    // For now we assume the transaction finished and we can update the local doc
    setState(() {
      final index = _docs.indexWhere((doc) => doc.id == prediction.id);
      if (index != -1) {
        // We can't easily update DocumentSnapshot data, but in this specific UI
        // we can just re-fetch the first page to show changes.
      }
    });
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
        final predictionRef = firestoreService.predictions.doc(prediction.id);

        transaction.delete(predictionRef);
      });

      setState(() {
        _docs.removeWhere((doc) => doc.id == prediction.id);
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
    final filteredDocs = _filterDocs();

    return AdminLayout(
      activeRoute: AdminPredictionsScreen.routePath,
      title: 'Tahmin Yönetimi',
      subtitle:
          'Kullanıcı tahminlerini görüntüle, puan gir ve sıralamayı güncelle.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Wrap(
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
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _docs.isEmpty && _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE53935)),
                  )
                : filteredDocs.isEmpty
                ? const Center(
                    child: Text(
                      'Tahmin bulunamadı.',
                      style: TextStyle(
                        color: Color(0xFFB3B3B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: filteredDocs.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == filteredDocs.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFFE53935),
                            ),
                          ),
                        );
                      }

                      final doc = filteredDocs[index];
                      final prediction = PredictionModel.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      );

                      return _PredictionAdminCard(
                        prediction: prediction,
                        statusColor: _statusColor(prediction),
                        statusText: _statusText(prediction),
                        onOpenMatch: () =>
                            context.go('/prediction/${prediction.matchId}'),
                        onEditPoints: () => _openPointDialog(prediction),
                        onDelete: () => _deletePrediction(prediction),
                      );
                    },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          final leading = CircleAvatar(
            radius: 28,
            backgroundColor: statusColor.withValues(alpha: 0.18),
            child: Icon(Icons.emoji_events_rounded, color: statusColor),
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
                    text: 'Maç: ${prediction.matchId}',
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
                style: const TextStyle(color: Color(0xFFB3B3B3), height: 1.4),
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
          );

          final pointsDisplay = Text(
            '${prediction.pointsEarned} puan',
            style: const TextStyle(
              color: Color(0xFFFFB300),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenMatch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF0F6A3D)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Aç'),
              ),
              ElevatedButton.icon(
                onPressed: onEditPoints,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Puan'),
              ),
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
                    const SizedBox(width: 12),
                    pointsDisplay,
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
              pointsDisplay,
              const SizedBox(width: 24),
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

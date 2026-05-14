import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/xp_event_model.dart';
import '../../../../data/repositories/audit_log_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_layout.dart';

class AdminPointsScreen extends StatefulWidget {
  const AdminPointsScreen({super.key});

  static const String routePath = '/admin/points';

  @override
  State<AdminPointsScreen> createState() => _AdminPointsScreenState();
}

class _AdminPointsScreenState extends State<AdminPointsScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  AppUserModel? _selectedUser;
  bool _searching = false;
  bool _saving = false;
  bool _rebuilding = false;
  String? _error;
  Map<String, dynamic>? _lastRebuild;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
      _selectedUser = null;
    });

    try {
      final byId = await firestoreService.users.doc(query).get();
      if (byId.exists && byId.data() != null) {
        setState(() {
          _selectedUser = AppUserModel.fromMap(byId.id, byId.data()!);
          _lastRebuild = null;
        });
        return;
      }

      final username = query.startsWith('@') ? query.substring(1) : query;
      final snapshot = await firestoreService.users
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => _error = 'Kullanıcı bulunamadı.');
        return;
      }

      final doc = snapshot.docs.first;
      setState(() {
        _selectedUser = AppUserModel.fromMap(doc.id, doc.data());
        _lastRebuild = null;
      });
    } catch (e) {
      setState(() => _error = 'Arama hatası: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Stream<List<XpEventModel>> _watchEvents(String userId) {
    return firestoreService
        .userXpEvents(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => XpEventModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> _submitAdjustment() async {
    final user = _selectedUser;
    if (user == null || _saving) return;

    final amount = int.tryParse(_amountController.text.trim());
    final reason = _reasonController.text.trim();

    if (amount == null || amount == 0) {
      _showSnack('Sıfır olmayan geçerli bir XP miktarı gir.', isError: true);
      return;
    }

    if (reason.length < 12) {
      _showSnack('Gerekçe en az 12 karakter olmalı.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'awardServerSideXp',
      );
      final sourceId =
          'manual-${user.id}-${DateTime.now().millisecondsSinceEpoch}';

      await callable.call({
        'targetUserId': user.id,
        'amount': amount,
        'reason': reason,
        'eventType': 'admin_adjustment',
        'sourceType': 'admin',
        'sourceId': sourceId,
        'metadata': {
          'operatorReason': reason,
          'userEmail': user.email,
          'username': user.username,
        },
      });

      await AuditLogRepository().logAction(
        adminEmail: authService.currentUser?.email ?? 'unknown',
        action: 'POINT_ADJUSTMENT',
        targetType: 'USER',
        targetId: user.id,
        platform: 'ADMIN_POINTS',
      );

      _amountController.clear();
      _reasonController.clear();
      await _refreshSelectedUser();
      _showSnack('Puan düzeltmesi kaydedildi.');
    } catch (e) {
      _showSnack('Puan düzeltme hatası: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _rebuildPoints({required bool dryRun}) async {
    final user = _selectedUser;
    if (user == null || _rebuilding) return;

    setState(() => _rebuilding = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'rebuildUserPoints',
      );
      final response = await callable.call({
        'targetUserId': user.id,
        'dryRun': dryRun,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() => _lastRebuild = data);

      if (!dryRun) {
        await _refreshSelectedUser();
      }

      _showSnack(
        dryRun ? 'Dry-run tamamlandı.' : 'Puan cache yeniden yazıldı.',
      );
    } catch (e) {
      _showSnack('Rebuild hatası: $e', isError: true);
    } finally {
      if (mounted) setState(() => _rebuilding = false);
    }
  }

  Future<void> _refreshSelectedUser() async {
    final user = _selectedUser;
    if (user == null) return;

    final doc = await firestoreService.users.doc(user.id).get();
    if (!mounted || !doc.exists || doc.data() == null) return;

    setState(() => _selectedUser = AppUserModel.fromMap(doc.id, doc.data()!));
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF0F6A3D),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminPointsScreen.routePath,
      title: 'Puan Kontrol Merkezi',
      subtitle:
          'Kullanıcı puan geçmişini denetle, gerekçeli manuel düzeltme yap ve sezon puanını izle.',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        children: [
          _SearchPanel(
            controller: _searchController,
            searching: _searching,
            error: _error,
            onSearch: _searchUser,
          ),
          const SizedBox(height: 18),
          if (_selectedUser == null)
            const _EmptyPanel()
          else ...[
            _UserPointsSummary(user: _selectedUser!),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final adjustment = _AdjustmentPanel(
                  amountController: _amountController,
                  reasonController: _reasonController,
                  saving: _saving,
                  onSubmit: _submitAdjustment,
                );
                final rebuild = _RebuildPanel(
                  rebuilding: _rebuilding,
                  result: _lastRebuild,
                  onDryRun: () => _rebuildPoints(dryRun: true),
                  onApply: () => _rebuildPoints(dryRun: false),
                );
                final history = _HistoryPanel(
                  stream: _watchEvents(_selectedUser!.id),
                );

                if (!wide) {
                  return Column(
                    children: [
                      adjustment,
                      const SizedBox(height: 18),
                      rebuild,
                      const SizedBox(height: 18),
                      history,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: Column(
                        children: [
                          adjustment,
                          const SizedBox(height: 18),
                          rebuild,
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: history),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final String? error;
  final VoidCallback onSearch;

  const _SearchPanel({
    required this.controller,
    required this.searching,
    required this.error,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kullanıcı Seç',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onSearch(),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Kullanıcı ID veya @username',
                    hintStyle: TextStyle(color: Color(0xFF777777)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0F6A3D),
                    ),
                    filled: true,
                    fillColor: Color(0xFF111111),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: searching ? null : onSearch,
                  icon: searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search_rounded),
                  label: const Text('Ara'),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: Color(0xFFE53935))),
          ],
        ],
      ),
    );
  }
}

class _UserPointsSummary extends StatelessWidget {
  final AppUserModel user;

  const _UserPointsSummary({required this.user});

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Metric(label: 'Kullanıcı', value: '@${user.username}'),
          _Metric(label: 'Toplam Puan', value: '${user.points}'),
          _Metric(label: 'Toplam XP', value: '${user.xp}'),
          _Metric(label: 'Sezon Puanı', value: '${user.seasonPoints}'),
          _Metric(label: 'Sezon XP', value: '${user.seasonXp}'),
          _Metric(label: 'Seviye', value: '${user.level}'),
          _Metric(label: 'Ünvan', value: user.levelTitle),
        ],
      ),
    );
  }
}

class _AdjustmentPanel extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController reasonController;
  final bool saving;
  final VoidCallback onSubmit;

  const _AdjustmentPanel({
    required this.amountController,
    required this.reasonController,
    required this.saving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manuel Düzeltme',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'XP miktarı backend üzerinden işlenir. Puan karşılığı server kuralıyla hesaplanır.',
            style: TextStyle(color: Color(0xFFB3B3B3), height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'XP düzeltmesi (-500 / +500)',
              labelStyle: TextStyle(color: Color(0xFFB3B3B3)),
              filled: true,
              fillColor: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            minLines: 4,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Zorunlu gerekçe',
              labelStyle: TextStyle(color: Color(0xFFB3B3B3)),
              filled: true,
              fillColor: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSubmit,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_chart_rounded),
              label: Text(saving ? 'Kaydediliyor' : 'Düzeltmeyi Uygula'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final Stream<List<XpEventModel>> stream;

  const _HistoryPanel({required this.stream});

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puan Geçmişi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<XpEventModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const Text(
                  'Puan olayı yok.',
                  style: TextStyle(color: Color(0xFFB3B3B3)),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: Colors.white10, height: 22),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final points = event.pointsAmount;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: event.amount >= 0
                            ? const Color(0xFF0F6A3D).withValues(alpha: 0.18)
                            : const Color(0xFFE53935).withValues(alpha: 0.18),
                        child: Icon(
                          event.amount >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: event.amount >= 0
                              ? const Color(0xFF0F6A3D)
                              : const Color(0xFFE53935),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.reason,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${event.eventType} / ${event.sourceType}:${event.sourceId}',
                              style: const TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${event.amount >= 0 ? '+' : ''}${event.amount} XP',
                            style: const TextStyle(
                              color: Color(0xFFFFB300),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (points != 0)
                            Text(
                              '${points >= 0 ? '+' : ''}$points puan',
                              style: const TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RebuildPanel extends StatelessWidget {
  final bool rebuilding;
  final Map<String, dynamic>? result;
  final VoidCallback onDryRun;
  final VoidCallback onApply;

  const _RebuildPanel({
    required this.rebuilding,
    required this.result,
    required this.onDryRun,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final diff = Map<String, dynamic>.from(result?['diff'] ?? const {});
    final duplicates = List<dynamic>.from(
      result?['duplicateDedupeKeys'] ?? const [],
    );

    return _AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puan Rebuild',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'xpEvents kaynak alınır; kullanıcı dokümanındaki cache alanları yeniden üretilebilir.',
            style: TextStyle(color: Color(0xFFB3B3B3), height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: rebuilding ? null : onDryRun,
                  icon: const Icon(Icons.preview_rounded),
                  label: const Text('Dry-run'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: rebuilding ? null : onApply,
                  icon: rebuilding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restart_alt_rounded),
                  label: const Text('Uygula'),
                ),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            _DiffLine(label: 'XP farkı', value: diff['xp']),
            _DiffLine(label: 'Puan farkı', value: diff['points']),
            _DiffLine(label: 'Sezon XP farkı', value: diff['seasonXp']),
            _DiffLine(label: 'Sezon puan farkı', value: diff['seasonPoints']),
            _DiffLine(label: 'Seviye farkı', value: diff['level']),
            const SizedBox(height: 10),
            Text(
              'Event: ${result?['eventCount'] ?? 0} / Sezon: ${result?['seasonId'] ?? 'global'}',
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
            ),
            if (duplicates.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tekrarlı dedupe: ${duplicates.length}',
                style: const TextStyle(color: Color(0xFFFFB300), fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  final String label;
  final dynamic value;

  const _DiffLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final number = value is num ? value : num.tryParse('$value') ?? 0;
    final color = number == 0
        ? const Color(0xFFB3B3B3)
        : number > 0
        ? const Color(0xFF0F6A3D)
        : const Color(0xFFE53935);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
            ),
          ),
          Text(
            '${number > 0 ? '+' : ''}$number',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const _AdminPanel(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Denetlemek için kullanıcı seç.',
            style: TextStyle(color: Color(0xFFB3B3B3)),
          ),
        ),
      ),
    );
  }
}

class _AdminPanel extends StatelessWidget {
  final Widget child;

  const _AdminPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

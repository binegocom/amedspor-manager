import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../data/services/gamification_service.dart';

class MyLineupsScreen extends StatefulWidget {
  const MyLineupsScreen({super.key});

  static const String routePath = '/lineups/me';

  @override
  State<MyLineupsScreen> createState() => _MyLineupsScreenState();
}

class _MyLineupsScreenState extends State<MyLineupsScreen> {
  bool _isCreating = false;

  Future<void> _createNewDummyLineup(String userId) async {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      final lineupRepository = LineupRepository();
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final newLineup = LineupModel(
        id: newId,
        userId: userId,
        matchId: 'Derbi Karşılaşması',
        formation: '4-3-3',
        philosophy: 'Gegenpressing',
        players: [
          {'name': 'Deniz Naki', 'position': 'FWD', 'rating': 92},
          {'name': 'Şehmus Özer', 'position': 'FWD', 'rating': 95},
          {'name': 'Mansur Çalar', 'position': 'MID', 'rating': 89},
        ],
        substitutes: [],
        likes: 5,
        power: 92,
        commentsCount: 2,
        createdAt: DateTime.now(),
      );

      await lineupRepository.saveLineup(newLineup);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F6A3D),
          content: Text('Yeni kadro şablonu (4-3-3 • Gegenpressing) başarıyla kaydedildi!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Kadro kaydedilemedi: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _startSparringMatch(LineupModel lineup, String userId) {
    int timeLeft = 4;
    bool isFinished = false;
    final random = math.Random();
    
    final opponents = ['Kocaelispor', 'Sakaryaspor', 'Ankaragücü', 'Şanlıurfaspor'];
    final opponentName = opponents[random.nextInt(opponents.length)];
    
    int myGoals = 0;
    int oppGoals = 0;
    Timer? matchTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            matchTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (timeLeft > 1) {
                setDialogState(() {
                  timeLeft--;
                  if (random.nextDouble() < (lineup.power > 75 ? 0.45 : 0.30)) {
                    myGoals++;
                  }
                  if (random.nextDouble() < 0.25) {
                    oppGoals++;
                  }
                });
              } else {
                timer.cancel();
                setDialogState(() {
                  timeLeft = 0;
                  isFinished = true;
                  if (myGoals <= oppGoals && random.nextBool()) {
                    myGoals++;
                  }
                });

                _awardSparringRewards(userId, lineup.id, myGoals > oppGoals);
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_esports_rounded, color: Color(0xFFFFD700), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isFinished ? 'MAÇ SONUCU' : '⚔️ HAZIRLIK MAÇI (SPARRING)',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF0F6A3D),
                              radius: 20,
                              child: Text('AMED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 6),
                            const Text('Amedspor', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            Text(lineup.philosophy ?? 'Taktik', style: const TextStyle(color: Colors.white54, fontSize: 9)),
                          ],
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Text('$myGoals', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.w900)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('-', style: TextStyle(color: Colors.white54, fontSize: 20)),
                            ),
                            Text('$oppGoals', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              radius: 20,
                              child: Text(opponentName.substring(0, 3).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 6),
                            Text(opponentName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const Text('Rakip', style: TextStyle(color: Colors.white54, fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (!isFinished) ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: timeLeft / 4,
                            strokeWidth: 4,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                          ),
                        ),
                        Text(
                          '$timeLeft',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Taktik felsefe sahada test ediliyor...',
                      style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F6A3D).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0F6A3D)),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '🎉 TEBRİKLER! TEST BAŞARILI',
                            style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '+50 XP ve +100 Taraftar Puanı (DP) kazandın!',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('HARİKA, DEVAM ET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      matchTimer?.cancel();
    });
  }

  Future<void> _awardSparringRewards(String userId, String lineupId, bool isWin) async {
    try {
      await firestoreService.users.doc(userId).update({
        'points': FieldValue.increment(100),
      });

      await GamificationService().awardXp(
        userId: userId,
        amount: 50,
        reason: 'Hazırlık maçı (Sparring) simülasyonu',
        eventType: 'sparring_match',
        sourceType: 'lineup',
        sourceId: lineupId,
      );
    } catch (e) {
      debugPrint('Sparring reward error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final lineupRepository = LineupRepository();

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            onPressed: () => context.go('/login'),
            child: const Text('Giriş Yap', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),
        onPressed: () => _createNewDummyLineup(user.uid),
        icon: _isCreating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('YENİ İLK 11 KUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            Expanded(
              child: StreamBuilder<List<LineupModel>>(
                stream: lineupRepository.watchUserLineups(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final lineups = snapshot.data ?? [];

                  if (lineups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sports_soccer_rounded, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz kadro kaydetmedin.',
                            style: TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F6A3D),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => _createNewDummyLineup(user.uid),
                            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                            label: const Text('HIZLI KADRO OLUŞTUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
                    itemCount: lineups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lineup = lineups[index];

                      return _LineupCard(
                        lineup: lineup,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${lineup.formation} dizilişi aktif edildi!')),
                          );
                        },
                        onSparringTap: () => _startSparringMatch(lineup, user.uid),
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
            Icons.sports_soccer_rounded,
            color: Color(0xFFE53935),
          ),
          const SizedBox(width: 10),
          const Text(
            'Benim Kadrolarım',
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

class _LineupCard extends StatelessWidget {
  final LineupModel lineup;
  final VoidCallback onTap;
  final VoidCallback onSparringTap;

  const _LineupCard({
    required this.lineup,
    required this.onTap,
    required this.onSparringTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour = lineup.createdAt.hour.toString().padLeft(2, '0');
    final minute = lineup.createdAt.minute.toString().padLeft(2, '0');
    final philosophyName = lineup.philosophy ?? 'Taktik Esnek';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF0F6A3D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maç: ${lineup.matchId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lineup.formation} • $philosophyName',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🔥 Güç: ${lineup.power} | 🕒 $hour:$minute',
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFFFFD700),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                    ),
                  ),
                  onPressed: onSparringTap,
                  icon: const Icon(Icons.sports_esports_rounded, size: 14),
                  label: const Text('⚔️ SPAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

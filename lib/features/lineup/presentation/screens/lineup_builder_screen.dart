import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_header.dart';
import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import 'lineup_rating_result_screen.dart';

class LineupBuilderScreen extends StatefulWidget {
  final String matchId;

  const LineupBuilderScreen({
    super.key,
    required this.matchId,
  });

  static const String routePath = '/lineup/:matchId';

  @override
  State<LineupBuilderScreen> createState() => _LineupBuilderScreenState();
}

class _LineupBuilderScreenState extends State<LineupBuilderScreen> {
  final lineupRepository = LineupRepository();
  final playerRepository = PlayerRepository();
  final postRepository = PostRepository();
  final uuid = const Uuid();

  String selectedFormation = '4-3-3';
  String? captainName;
  bool isSaving = false;

  final List<String> formations = const [
    '4-3-3',
    '4-2-3-1',
    '3-5-2',
    '4-4-2',
    '3-4-3',
    '5-4-1',
    '4-1-2-1-2',
  ];

  final List<_Player> players = [
    _Player(name: 'Kaleci', position: 'GK', top: 0.84, left: 0.50),
    _Player(name: 'Sol Bek', position: 'DEF', top: 0.66, left: 0.18),
    _Player(name: 'Stoper 1', position: 'DEF', top: 0.68, left: 0.38),
    _Player(name: 'Stoper 2', position: 'DEF', top: 0.68, left: 0.62),
    _Player(name: 'Sağ Bek', position: 'DEF', top: 0.66, left: 0.82),
    _Player(name: 'Orta Saha 1', position: 'MID', top: 0.45, left: 0.30),
    _Player(name: 'Orta Saha 2', position: 'MID', top: 0.45, left: 0.50),
    _Player(name: 'Orta Saha 3', position: 'MID', top: 0.45, left: 0.70),
    _Player(name: 'Sol Kanat', position: 'FWD', top: 0.22, left: 0.22),
    _Player(name: 'Forvet', position: 'FWD', top: 0.18, left: 0.50),
    _Player(name: 'Sağ Kanat', position: 'FWD', top: 0.22, left: 0.78),
  ];

  int get lineupPower {
    final formationBonus = selectedFormation == '4-3-3' ? 8 : 5;
    final captainBonus = captainName == null ? 0 : 12;
    final ratingAverage =
        players.fold<int>(0, (acc, player) => acc + player.rating) / players.length;

    return (ratingAverage + formationBonus + captainBonus).round().clamp(0, 100);
  }

  void _showLoginRequired() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.primaryRed, size: 48),
              const SizedBox(height: 16),
              const Text('Üyelik Gerekli', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              const Text(
                'Kadronu kaydetmek, paylaşmak ve puan kazanmak için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'GİRİŞ YAP',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeFormation(String formation) {
    setState(() {
      selectedFormation = formation;

      if (formation == '4-3-3') {
        players[0] = players[0].copyWith(top: 0.84, left: 0.50);
        players[1] = players[1].copyWith(top: 0.66, left: 0.18);
        players[2] = players[2].copyWith(top: 0.68, left: 0.38);
        players[3] = players[3].copyWith(top: 0.68, left: 0.62);
        players[4] = players[4].copyWith(top: 0.66, left: 0.82);
        players[5] = players[5].copyWith(top: 0.45, left: 0.30);
        players[6] = players[6].copyWith(top: 0.45, left: 0.50);
        players[7] = players[7].copyWith(top: 0.45, left: 0.70);
        players[8] = players[8].copyWith(top: 0.22, left: 0.22);
        players[9] = players[9].copyWith(top: 0.18, left: 0.50);
        players[10] = players[10].copyWith(top: 0.22, left: 0.78);
      } else if (formation == '4-2-3-1') {
        players[5] = players[5].copyWith(top: 0.50, left: 0.40);
        players[6] = players[6].copyWith(top: 0.50, left: 0.60);
        players[7] = players[7].copyWith(top: 0.35, left: 0.50);
        players[8] = players[8].copyWith(top: 0.28, left: 0.22);
        players[9] = players[9].copyWith(top: 0.16, left: 0.50);
        players[10] = players[10].copyWith(top: 0.28, left: 0.78);
      } else if (formation == '3-5-2') {
        players[1] = players[1].copyWith(top: 0.66, left: 0.28);
        players[2] = players[2].copyWith(top: 0.68, left: 0.50);
        players[3] = players[3].copyWith(top: 0.66, left: 0.72);
        players[4] = players[4].copyWith(top: 0.48, left: 0.14);
        players[5] = players[5].copyWith(top: 0.45, left: 0.35);
        players[6] = players[6].copyWith(top: 0.42, left: 0.50);
        players[7] = players[7].copyWith(top: 0.45, left: 0.65);
        players[8] = players[8].copyWith(top: 0.48, left: 0.86);
        players[9] = players[9].copyWith(top: 0.18, left: 0.40);
        players[10] = players[10].copyWith(top: 0.18, left: 0.60);
      } else if (formation == '4-4-2') {
        players[5] = players[5].copyWith(top: 0.46, left: 0.20);
        players[6] = players[6].copyWith(top: 0.46, left: 0.40);
        players[7] = players[7].copyWith(top: 0.46, left: 0.60);
        players[8] = players[8].copyWith(top: 0.46, left: 0.80);
        players[9] = players[9].copyWith(top: 0.18, left: 0.40);
        players[10] = players[10].copyWith(top: 0.18, left: 0.60);
      }
    });
  }

  void _openPlayerSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final selectedPosition = players[index].position;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<List<PlayerModel>>(
              stream: playerRepository.watchActivePlayers(),
              builder: (context, snapshot) {
                final allPlayers = snapshot.data ?? [];
                final filteredPlayers = allPlayers.where((player) {
                  return player.position == selectedPosition;
                }).toList();

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                    ),
                    Text('$selectedPosition Seç', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: filteredPlayers.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, playerIndex) {
                                final player = filteredPlayers[playerIndex];
                                return AppCard(
                                  onTap: () {
                                    setState(() {
                                      players[index] = players[index].copyWith(
                                        name: player.name,
                                        rating: player.rating,
                                        number: player.number,
                                      );
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                                        child: Center(child: Text('${player.number}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(player.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            Text('GÜÇ: ${player.rating}', style: AppTextStyles.label),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.add_circle_outline, color: AppColors.primaryRed),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveLineup() async {
    final user = authService.currentUser;
    if (user == null) {
      _showLoginRequired();
      return;
    }

    setState(() => isSaving = true);

    try {
      final lineup = LineupModel(
        id: uuid.v4(),
        userId: user.uid,
        matchId: widget.matchId,
        formation: selectedFormation,
        players: players.map((player) {
          return {
            'name': player.name,
            'position': player.position,
            'top': player.top,
            'left': player.left,
            'rating': player.rating,
            'number': player.number,
            'captain': player.name == captainName,
          };
        }).toList(),
        likes: 0,
        power: lineupPower,
        commentsCount: 0,
        createdAt: DateTime.now(),
      );

      await lineupRepository.saveLineup(lineup);

      await firestoreService.users.doc(user.uid).update({
        'points': FieldValue.increment(10),
      });

      if (!mounted) return;

      context.go(
        LineupRatingResultScreen.routePath,
        extra: {
          'score': lineupPower,
          'pointsEarned': 10,
          'matchId': widget.matchId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _shareLineup() async {
    final user = authService.currentUser;
    if (user == null) {
      _showLoginRequired();
      return;
    }

    try {
      final lineupId = uuid.v4();
      final lineup = LineupModel(
        id: lineupId,
        userId: user.uid,
        matchId: widget.matchId,
        formation: selectedFormation,
        players: players.map((p) => {
          'name': p.name,
          'position': p.position,
          'top': p.top,
          'left': p.left,
          'rating': p.rating,
          'number': p.number,
          'captain': p.name == captainName,
        }).toList(),
        likes: 0,
        power: lineupPower,
        commentsCount: 0,
        createdAt: DateTime.now(),
      );

      await lineupRepository.saveLineup(lineup);

      final post = PostModel(
        id: uuid.v4(),
        userId: user.uid,
        username: user.email ?? 'Taraftar',
        title: 'Benim $selectedFormation Kadrom',
        content: 'Yeni kadromu kurdum! Güç: $lineupPower. Sen de gel kadronu kur!',
        category: 'Kadro',
        likes: 0,
        commentsCount: 0,
        lineupId: lineupId,
        createdAt: DateTime.now(),
      );

      await postRepository.createLineupPost(post: post, lineupId: lineupId);
      await firestoreService.users.doc(user.uid).update({'points': FieldValue.increment(15)});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kadron paylaşıldı! +15 puan.')));
      context.go('/feed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'KADRO KUR', showBackButton: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _StatusCard(power: lineupPower, captain: captainName),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: formations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final formation = formations[index];
                  final active = selectedFormation == formation;
                  return GestureDetector(
                    onTap: () => _changeFormation(formation),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryGreen : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: active ? AppColors.primaryGreen : AppColors.white.withValues(alpha: 0.05)),
                      ),
                      alignment: Alignment.center,
                      child: Text(formation, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _PitchView(
                players: players,
                captainName: captainName,
                onPlayerTap: _openPlayerSheet,
                onCaptainSet: (name) => setState(() => captainName = name),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'PAYLAŞ',
                      type: AppButtonType.secondary,
                      onTap: _shareLineup,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'KAYDET',
                      isLoading: isSaving,
                      onTap: _saveLineup,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final int power;
  final String? captain;
  const _StatusCard({required this.power, required this.captain});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.bolt_rounded, color: AppColors.primaryGreen, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kadro Gücü: $power/100', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('Kaptan: ${captain ?? 'Seçilmedi'}', style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchView extends StatelessWidget {
  final List<_Player> players;
  final String? captainName;
  final ValueChanged<int> onPlayerTap;
  final ValueChanged<String> onCaptainSet;

  const _PitchView({
    required this.players,
    required this.captainName,
    required this.onPlayerTap,
    required this.onCaptainSet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pitchWidth = constraints.maxWidth;
        final pitchHeight = constraints.maxHeight;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0.9),
                AppColors.primaryGreen.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white10, width: 2),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
              ...players.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isCaptain = p.name == captainName;

                return Positioned(
                  top: p.top * pitchHeight - 30,
                  left: p.left * pitchWidth - 30,
                  child: GestureDetector(
                    onTap: () => onPlayerTap(idx),
                    onLongPress: () {
                      if (p.name != p.position) {
                        onCaptainSet(p.name);
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: isCaptain ? AppColors.gold : AppColors.white, width: 2),
                            boxShadow: [
                              if (isCaptain) BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 12),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              p.number > 0 ? '${p.number}' : '?',
                              style: TextStyle(color: isCaptain ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                          child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50, paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Goal areas
    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, size.height * 0.12), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, size.height * 0.88, size.width * 0.6, size.height * 0.12), paint);
    
    // Outer border
    canvas.drawRect(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Player {
  final String name;
  final String position;
  final double top;
  final double left;
  final int rating;
  final int number;

  _Player({
    required this.name,
    required this.position,
    required this.top,
    required this.left,
    this.rating = 60,
    this.number = 0,
  });

  _Player copyWith({
    String? name,
    String? position,
    double? top,
    double? left,
    int? rating,
    int? number,
  }) {
    return _Player(
      name: name ?? this.name,
      position: position ?? this.position,
      top: top ?? this.top,
      left: left ?? this.left,
      rating: rating ?? this.rating,
      number: number ?? this.number,
    );
  }
}
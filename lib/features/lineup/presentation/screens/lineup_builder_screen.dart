import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/login_required_modal.dart';
import 'lineup_rating_result_screen.dart';
import '../../../../core/gamification/gamification_service.dart';

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
    _Player(name: 'OYUNCU SEÇ', position: 'GK', top: 0.84, left: 0.50),
    _Player(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.66, left: 0.18),
    _Player(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.68, left: 0.38),
    _Player(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.68, left: 0.62),
    _Player(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.66, left: 0.82),
    _Player(name: 'OYUNCU SEÇ', position: 'MID', top: 0.45, left: 0.30),
    _Player(name: 'OYUNCU SEÇ', position: 'MID', top: 0.45, left: 0.50),
    _Player(name: 'OYUNCU SEÇ', position: 'MID', top: 0.45, left: 0.70),
    _Player(name: 'OYUNCU SEÇ', position: 'FWD', top: 0.22, left: 0.22),
    _Player(name: 'OYUNCU SEÇ', position: 'FWD', top: 0.18, left: 0.50),
    _Player(name: 'OYUNCU SEÇ', position: 'FWD', top: 0.22, left: 0.78),
  ];

  final List<_Player> substitutes = [];

  int get lineupPower {
    final formationBonus = selectedFormation == '4-3-3' ? 8 : 5;
    final captainBonus = captainName == null ? 0 : 12;
    final ratingSum = players.fold<int>(0, (acc, p) => acc + p.rating);
    final ratingAverage = ratingSum / players.length;

    return (ratingAverage + formationBonus + captainBonus).round().clamp(0, 100);
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

  void _openPlayerSheet(int? index, {bool isSub = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final selectedPosition = index != null ? players[index].position : 'ALL';

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
                final filteredPlayers = selectedPosition == 'ALL' 
                    ? allPlayers 
                    : allPlayers.where((player) => player.position == selectedPosition).toList();

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                    ),
                    Text(isSub ? 'Yedek Oyuncu Seç' : '$selectedPosition Seç', style: AppTextStyles.h3),
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
                                
                                // Check if player already in lineup
                                final isInLineup = players.any((p) => p.name == player.name) || 
                                                  substitutes.any((p) => p.name == player.name);

                                return Opacity(
                                  opacity: isInLineup ? 0.5 : 1.0,
                                  child: PremiumCard(
                                    onTap: isInLineup ? null : () {
                                      setState(() {
                                        if (isSub) {
                                          substitutes.add(_Player(
                                            name: player.name,
                                            position: player.position,
                                            rating: player.rating,
                                            number: player.number,
                                            top: 0,
                                            left: 0,
                                          ));
                                        } else if (index != null) {
                                          players[index] = players[index].copyWith(
                                            name: player.name,
                                            rating: player.rating,
                                            number: player.number,
                                          );
                                        }
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: player.position == 'GK' ? AppColors.gold : AppColors.primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(child: Text('${player.number}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(player.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              Text('${player.position} • GÜÇ: ${player.rating}', style: AppTextStyles.label),
                                            ],
                                          ),
                                        ),
                                        if (isInLineup)
                                          const Text('KADRODA', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold))
                                        else
                                          const Icon(Icons.add_circle_outline, color: AppColors.primaryRed),
                                      ],
                                    ),
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
      showLoginRequiredModal(context);
      return;
    }

    setState(() => isSaving = true);

    try {
      final lineup = LineupModel(
        id: uuid.v4(),
        userId: user.uid,
        matchId: widget.matchId,
        formation: selectedFormation,
        players: players.map((p) => p.toMap()).toList(),
        substitutes: substitutes.map((p) => p.toMap()).toList(),
        likes: 0,
        power: lineupPower,
        commentsCount: 0,
        createdAt: DateTime.now(),
      );

      await lineupRepository.saveLineup(lineup);

      // 🔥 Award XP for saving lineup
      await GamificationService().awardXp(
        userId: user.uid,
        amount: GamificationService.xpLineupSaved,
        reason: 'Kadro kurduğun için',
        eventType: 'lineup_saved',
        sourceType: 'lineup',
        sourceId: lineup.id,
      );

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
      showLoginRequiredModal(context);
      return;
    }

    try {
      final lineupId = uuid.v4();
      final lineup = LineupModel(
        id: lineupId,
        userId: user.uid,
        matchId: widget.matchId,
        formation: selectedFormation,
        players: players.map((p) => p.toMap()).toList(),
        substitutes: substitutes.map((p) => p.toMap()).toList(),
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
      
      // 🔥 Award XP for sharing lineup
      await GamificationService().awardXp(
        userId: user.uid,
        amount: GamificationService.xpLineupShared,
        reason: 'Kadro paylaştığın için',
        eventType: 'lineup_shared',
        sourceType: 'lineup',
        sourceId: lineupId,
      );

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
            const PremiumHeader(title: 'KADRO KUR', showBackButton: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _StatusCard(power: lineupPower, captain: captainName, players: players),
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
                onPlayerTap: (idx) => _openPlayerSheet(idx),
                onCaptainSet: (name) => setState(() => captainName = name),
              ),
            ),
            _buildSubstitutesBench(),
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

  Widget _buildSubstitutesBench() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YEDEK KULÜBESİ (${substitutes.length})',
                style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              if (substitutes.length < 12)
                GestureDetector(
                  onTap: () => _openPlayerSheet(null, isSub: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: AppColors.primaryGreen, size: 14),
                        SizedBox(width: 4),
                        Text('EKLE', style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 8),
          child: substitutes.isEmpty
              ? Center(
                  child: Text(
                    'Henüz yedek oyuncu eklenmedi.',
                    style: TextStyle(color: AppColors.muted.withValues(alpha: 0.5), fontSize: 12),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: substitutes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final p = substitutes[index];
                    return Stack(
                      children: [
                        Column(
                          children: [
                            _ProJersey(
                              number: p.number,
                              isCaptain: false,
                              position: p.position,
                            ),
                            const SizedBox(height: 4),
                            _PlayerLabel(name: p.name, rating: p.rating),
                          ],
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: GestureDetector(
                            onTap: () => setState(() => substitutes.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 10),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final int power;
  final String? captain;
  final List<_Player> players;

  const _StatusCard({
    required this.power,
    required this.captain,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate sector scores
    final defScore = _calculateSector(players, 'DEF') + _calculateSector(players, 'GK');
    final midScore = _calculateSector(players, 'MID');
    final fwdScore = _calculateSector(players, 'FWD');

    return PremiumCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildPowerBadge(power),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KADRO ANALİZİ',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      captain != null ? 'Kaptan: $captain' : 'Kaptan Seçilmedi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _AnalysisBar(label: 'SAVUNMA', score: defScore, color: const Color(0xFF2196F3)),
              const SizedBox(width: 12),
              _AnalysisBar(label: 'ORTA SAHA', score: midScore, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 12),
              _AnalysisBar(label: 'HÜCUM', score: fwdScore, color: const Color(0xFFE53935)),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateSector(List<_Player> players, String pos) {
    final sectorPlayers = players.where((p) => p.position == pos).toList();
    if (sectorPlayers.isEmpty) return 0;
    final avg = sectorPlayers.fold<int>(0, (a, b) => a + b.rating) / sectorPlayers.length;
    return avg.round();
  }

  Widget _buildPowerBadge(int power) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$power',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'GÜÇ',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisBar extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _AnalysisBar({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 8, fontWeight: FontWeight.w900),
              ),
              Text(
                '$score',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
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

        return Stack(
          children: [
            // Atmosphere effects (Stadium lights glow)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0F6A3D).withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    center: Alignment.center,
                    radius: 1.2,
                  ),
                ),
              ),
            ),
            
            // 3D Perspective Transform
            Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateX(0.1), // tilt
                alignment: FractionalOffset.center,
                child: Container(
                  width: pitchWidth * 0.95,
                  height: pitchHeight * 0.95,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6A3D),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _ProPitchPainter())),
                        ...players.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final p = entry.value;
                          final isCaptain = p.name == captainName;

                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeInOutCubic,
                            top: p.top * pitchHeight - 40,
                            left: p.left * pitchWidth - 35,
                            child: GestureDetector(
                              onTap: () => onPlayerTap(idx),
                              onLongPress: () {
                                if (p.name != p.position) {
                                  onCaptainSet(p.name);
                                }
                              },
                              child: Column(
                                children: [
                                  _ProJersey(
                                    number: p.number,
                                    isCaptain: isCaptain,
                                    position: p.position,
                                  ),
                                  const SizedBox(height: 4),
                                  _PlayerLabel(name: p.name, rating: p.rating),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProJersey extends StatelessWidget {
  final int number;
  final bool isCaptain;
  final String position;

  const _ProJersey({
    required this.number,
    required this.isCaptain,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final isGK = position == 'GK';
    final Color primaryColor = isGK ? const Color(0xFFFFD700) : const Color(0xFFE53935);
    final Color stripeColor = isGK ? const Color(0xFF111111) : const Color(0xFF0F6A3D);

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Jersey Shape Shadow
          CustomPaint(
            size: const Size(54, 54),
            painter: _JerseyPainter(color: Colors.black.withValues(alpha: 0.3)),
          ),
          // Actual Jersey
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: CustomPaint(
                  size: const Size(50, 50),
                  painter: _JerseyPainter(
                    color: primaryColor,
                    stripeColor: stripeColor,
                    isStripe: !isGK,
                  ),
                ),
              );
            },
          ),
          // Number
          Positioned(
            top: 14,
            child: Text(
              number > 0 ? '$number' : '?',
              style: TextStyle(
                color: isGK ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2),
                ],
              ),
            ),
          ),
          if (isCaptain)
            Positioned(
              right: 2,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Text('C', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

class _JerseyPainter extends CustomPainter {
  final Color color;
  final Color? stripeColor;
  final bool isStripe;

  _JerseyPainter({required this.color, this.stripeColor, this.isStripe = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();

    // Body
    path.moveTo(size.width * 0.2, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.9);
    path.lineTo(size.width * 0.2, size.height * 0.9);
    path.close();

    // Sleeves
    path.moveTo(size.width * 0.2, size.height * 0.1);
    path.lineTo(0, size.height * 0.3);
    path.lineTo(size.width * 0.15, size.height * 0.45);
    path.lineTo(size.width * 0.2, size.height * 0.3);

    path.moveTo(size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width * 0.85, size.height * 0.45);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);

    if (isStripe && stripeColor != null) {
      final sPaint = Paint()..color = stripeColor!..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(size.width * 0.4, size.height * 0.1, size.width * 0.2, size.height * 0.8), sPaint);
    }

    // Border
    final bPaint = Paint()..color = Colors.white.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawPath(path, bPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerLabel extends StatelessWidget {
  final String name;
  final int rating;

  const _PlayerLabel({required this.name, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: rating > 80 ? AppColors.gold : (rating > 70 ? AppColors.primaryGreen : AppColors.muted),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text('$rating', style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          Text(
            name.length > 10 ? '${name.substring(0, 8)}..' : name,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ProPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.3);

    final grassPaint = Paint()..style = PaintingStyle.fill;

    // Draw grass stripes with 3D depth feeling
    const stripes = 12;
    final stripeHeight = size.height / stripes;
    for (var i = 0; i < stripes; i++) {
      grassPaint.color = i % 2 == 0 
          ? const Color(0xFF0F6A3D).withValues(alpha: 0.15) 
          : const Color(0xFF0F6A3D).withValues(alpha: 0.08);
      canvas.drawRect(Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight), grassPaint);
    }

    // Outer border
    canvas.drawRect(Rect.fromLTWH(5, 5, size.width - 10, size.height - 10), paint);

    // Center line and circle
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 70, paint);

    // Goal areas
    _drawPenaltyArea(canvas, size, paint, true); // Top
    _drawPenaltyArea(canvas, size, paint, false); // Bottom

    // Corner arcs
    canvas.drawArc(Rect.fromLTWH(-15, -15, 30, 30), 0, 1.5, false, paint);
    canvas.drawArc(Rect.fromLTWH(size.width - 15, -15, 30, 30), 1.5, 1.5, false, paint);
  }

  void _drawPenaltyArea(Canvas canvas, Size size, Paint paint, bool isTop) {
    final double top = isTop ? 5 : size.height - size.height * 0.22 - 5;
    final double boxHeight = size.height * 0.22;
    final double boxWidth = size.width * 0.75;
    final double boxLeft = (size.width - boxWidth) / 2;

    canvas.drawRect(Rect.fromLTWH(boxLeft, top, boxWidth, boxHeight), paint);

    final double smallBoxWidth = size.width * 0.4;
    final double smallBoxLeft = (size.width - smallBoxWidth) / 2;
    final double smallBoxHeight = size.height * 0.08;
    final double smallBoxTop = isTop ? top : size.height - smallBoxHeight - 5;
    canvas.drawRect(Rect.fromLTWH(smallBoxLeft, smallBoxTop, smallBoxWidth, smallBoxHeight), paint);
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'top': top,
      'left': left,
      'rating': rating,
      'number': number,
    };
  }
}
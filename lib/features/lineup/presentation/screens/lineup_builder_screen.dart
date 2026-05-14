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
import '../../../../data/services/gamification_service.dart';
import '../../../../data/services/ai_tactical_service.dart';

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
  final aiTacticalService = AiTacticalService();

  String selectedFormation = '4-3-3';
  String selectedPhilosophy = 'Gegenpressing'; // Yeni Felsefe Özelliği
  String? captainName;
  bool isSaving = false;
  bool isAiAnalyzing = false;
  int remainingAiTokens = 0;

  final List<String> formations = const [
    '4-3-3',
    '4-2-3-1',
    '3-5-2',
    '4-4-2',
    '3-4-3',
    '5-4-1',
    '4-1-2-1-2',
  ];

  final List<String> philosophies = const [
    'Gegenpressing',
    'Tiki-Taka',
    'Catenaccio',
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
    // Felsefeye göre dinamik OVR bonusu
    int philosophyBonus = 4;
    if (selectedPhilosophy == 'Tiki-Taka') philosophyBonus = 3;
    if (selectedPhilosophy == 'Catenaccio') philosophyBonus = 5;

    final ratingSum = players.fold<int>(0, (acc, p) => acc + p.rating);
    final ratingAverage = ratingSum / players.length;

    return (ratingAverage + formationBonus + captainBonus + philosophyBonus).round().clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();
    _loadAiTokens();
  }

  Future<void> _loadAiTokens() async {
    final tokens = await aiTacticalService.getRemainingTokens();
    if (mounted) {
      setState(() {
        remainingAiTokens = tokens;
      });
    }
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

  Future<void> _autoFillWithOptimalAI() async {
    setState(() => isAiAnalyzing = true);

    try {
      // 1. Veritabanındaki tüm aktif oyuncuları çek
      final snap = await firestoreService.players.where('active', isEqualTo: true).get();
      final allPlayers = snap.docs.map((d) => PlayerModel.fromMap(d.id, d.data())).toList();

      // 2. İsim bazlı tekilleştir (en yüksek reytingli olanı sakla)
      final uniqueMap = <String, PlayerModel>{};
      for (final p in allPlayers) {
        if (!p.injured && !p.suspended) {
          if (!uniqueMap.containsKey(p.name) || uniqueMap[p.name]!.rating < p.rating) {
            uniqueMap[p.name] = p;
          }
        }
      }

      final pool = uniqueMap.values.toList()..sort((a, b) => b.rating.compareTo(a.rating));

      if (pool.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kadro havuzunda aktif ve uygun oyuncu bulunamadı.')),
        );
        return;
      }

      // 3. Sahadaki pozisyonlara en uygun oyuncuyu ata
      final usedNames = <String>{};
      PlayerModel? highestRatedPlayer;

      for (int i = 0; i < players.length; i++) {
        final posTarget = players[i].position; // 'GK', 'DEF', 'MID', 'FWD'
        PlayerModel? candidate;
        
        try {
          candidate = pool.firstWhere((p) => p.position == posTarget && !usedNames.contains(p.name));
        } catch (_) {
          // Eğer tam o pozisyondan kalmadıysa herhangi bir en yüksek reytingliyi (joker) koy
          try {
            candidate = pool.firstWhere((p) => !usedNames.contains(p.name));
          } catch (_) {}
        }

        if (candidate != null) {
          usedNames.add(candidate.name);
          players[i] = players[i].copyWith(
            id: candidate.id,
            name: candidate.name,
            rating: candidate.rating,
            number: candidate.number,
          );

          if (highestRatedPlayer == null || candidate.rating > highestRatedPlayer.rating) {
            highestRatedPlayer = candidate;
          }
        }
      }

      // Kaptanlığı en yüksek reytingli oyuncuya ata
      if (highestRatedPlayer != null) {
        captainName = highestRatedPlayer.name;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.gold,
          content: Text('✨ AI Danışman sahaya en uyumlu ve yüksek reytingli 11 oyuncuyu yerleştirdi!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Doldurma Hatası: $e')));
    } finally {
      if (mounted) setState(() => isAiAnalyzing = false);
    }
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
                
                // Aynı isimdeki tekrarlanan oyuncuları filtrele (sadece benzersiz olanları göster)
                final seenNames = <String>{};
                final uniquePlayers = <PlayerModel>[];
                for (final p in allPlayers) {
                  if (!seenNames.contains(p.name)) {
                    seenNames.add(p.name);
                    uniquePlayers.add(p);
                  }
                }

                final filteredPlayers = selectedPosition == 'ALL' 
                    ? uniquePlayers 
                    : uniquePlayers.where((player) => player.position == selectedPosition).toList();

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

                                final isUnavailable = player.injured || player.suspended;
                                final isDisabled = isInLineup || isUnavailable;

                                return Opacity(
                                  opacity: isDisabled ? 0.5 : 1.0,
                                  child: PremiumCard(
                                    onTap: isDisabled ? null : () {
                                      setState(() {
                                        if (isSub) {
                                          substitutes.add(_Player(
                                            id: player.id,
                                            name: player.name,
                                            position: player.position,
                                            rating: player.rating,
                                            number: player.number,
                                            top: 0,
                                            left: 0,
                                          ));
                                        } else if (index != null) {
                                          players[index] = players[index].copyWith(
                                            id: player.id,
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
                                              if (player.injured)
                                                const Text('SAKAT', style: TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                                              if (player.suspended)
                                                const Text('CEZALI', style: TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
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
        philosophy: selectedPhilosophy,
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
        philosophy: selectedPhilosophy,
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
        title: 'Benim $selectedFormation ($selectedPhilosophy) Kadrom',
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

  Future<void> _requestAiAdvice() async {
    final user = authService.currentUser;
    if (user == null) {
      showLoginRequiredModal(context);
      return;
    }

    final selectedCount = players.where((p) => p.name != 'OYUNCU SEÇ').length;
    if (selectedCount < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI analizi için en az 7 oyuncu seçmelisiniz.')),
      );
      return;
    }

    if (remainingAiTokens <= 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Jeton Kalmadı', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Günlük ücretsiz AI analiz hakkınız doldu.\n250 XP harcayarak yeni bir Taktiksel Danışmanlık Jetonu almak ister misiniz?',
            style: TextStyle(color: AppColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İPTAL', style: TextStyle(color: AppColors.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('XP HARCA', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => isAiAnalyzing = true);
      final success = await aiTacticalService.buyTokenWithXp();
      if (!success) {
        setState(() => isAiAnalyzing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yetersiz XP! Jeton almak için daha fazla XP biriktirmelisiniz.')),
          );
        }
        return;
      }

      await _loadAiTokens();
    } else {
      setState(() => isAiAnalyzing = true);
      await aiTacticalService.consumeToken();
      await _loadAiTokens();
    }

    final report = await aiTacticalService.synthesizeAdvice(
      selectedFormation,
      lineupPower,
      captainName,
    );

    setState(() => isAiAnalyzing = false);

    if (mounted) {
      _showAiReportModal(report);
    }
  }

  void _showAiReportModal(String report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology, color: AppColors.gold, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Taktiksel Danışman', style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Genkit / Gemini Sentezi', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
              child: SingleChildScrollView(
                child: Text(
                  report,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'ANLADIM, TALİMATLARI UYGULA',
                onTap: () => Navigator.pop(ctx),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.tacticalBlueprintGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const PremiumHeader(title: 'KADRO KUR', showBackButton: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _StatusCard(
                  power: lineupPower,
                  captain: captainName,
                  players: players,
                  philosophy: selectedPhilosophy,
                  remainingAiTokens: remainingAiTokens,
                  isAiAnalyzing: isAiAnalyzing,
                  onAiAdvisorTap: _requestAiAdvice,
                ),
              ),
              
              // Formasyon Çubuğu
              SizedBox(
                height: 40,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primaryGreen : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: active ? AppColors.primaryGreen : AppColors.white.withValues(alpha: 0.05)),
                        ),
                        alignment: Alignment.center,
                        child: Text(formation, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Felsefe Çubuğu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.gold, size: 14),
                    const SizedBox(width: 6),
                    const Text('FELSEFE:', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: philosophies.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final phil = philosophies[index];
                            final active = selectedPhilosophy == phil;
                            String bonusText = '+4 OVR';
                            if (phil == 'Tiki-Taka') bonusText = '+3 OVR';
                            if (phil == 'Catenaccio') bonusText = '+5 OVR';

                            return GestureDetector(
                              onTap: () => setState(() => selectedPhilosophy = phil),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.gold.withValues(alpha: 0.18) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: active ? AppColors.gold : Colors.white12),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  children: [
                                    Text(phil, style: TextStyle(color: active ? AppColors.gold : AppColors.muted, fontWeight: FontWeight.bold, fontSize: 10)),
                                    const SizedBox(width: 4),
                                    Text(bonusText, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 8)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ✨ AI Otomatik Optimum Kadro Butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  text: '✨ AI OPTİMUM YERLEŞTİR',
                  color: AppColors.gold,
                  textColor: Colors.black,
                  height: 34,
                  isLoading: isAiAnalyzing,
                  onTap: _autoFillWithOptimalAI,
                ),
              ),
              const SizedBox(height: 10),

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'PAYLAŞ',
                        type: AppButtonType.secondary,
                        height: 38,
                        onTap: _shareLineup,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'KAYDET',
                        height: 38,
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
      ),
    );
  }

  Widget _buildSubstitutesBench() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YEDEK KULÜBESİ (${substitutes.length})',
                style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
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
          height: 80,
          margin: const EdgeInsets.only(bottom: 4),
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
                            const SizedBox(height: 2),
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
  final String philosophy;
  final int remainingAiTokens;
  final bool isAiAnalyzing;
  final VoidCallback? onAiAdvisorTap;

  const _StatusCard({
    required this.power,
    required this.captain,
    required this.players,
    required this.philosophy,
    this.remainingAiTokens = 0,
    this.isAiAnalyzing = false,
    this.onAiAdvisorTap,
  });

  @override
  Widget build(BuildContext context) {
    final defScore = _calculateSector(players, 'DEF') + _calculateSector(players, 'GK');
    final midScore = _calculateSector(players, 'MID');
    final fwdScore = _calculateSector(players, 'FWD');

    return PremiumCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildPowerBadge(power),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KADRO KİMYASI: ${philosophy.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      captain != null ? 'Kaptan: $captain' : 'Kaptan Seçilmedi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: isAiAnalyzing ? null : onAiAdvisorTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: remainingAiTokens > 0 
                          ? [AppColors.gold, const Color(0xFFFFB300)]
                          : [AppColors.card, AppColors.surface],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: remainingAiTokens > 0 ? AppColors.gold : AppColors.muted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: isAiAnalyzing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology,
                              color: remainingAiTokens > 0 ? Colors.black : AppColors.muted,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI DANIŞMAN',
                                  style: TextStyle(
                                    color: remainingAiTokens > 0 ? Colors.black : AppColors.muted,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  remainingAiTokens > 0 ? '$remainingAiTokens ÜCRETSİZ' : 'XP İLE AL',
                                  style: TextStyle(
                                    color: remainingAiTokens > 0 ? Colors.black87 : AppColors.muted.withValues(alpha: 0.7),
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AnalysisBar(label: 'SAVUNMA', score: defScore, color: const Color(0xFF2196F3)),
              const SizedBox(width: 10),
              _AnalysisBar(label: 'ORTA SAHA', score: midScore, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 10),
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
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$power',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'GÜÇ',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 7,
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
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 3,
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
            
            Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.1),
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
                            top: p.top * pitchHeight - 35,
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
                                  _ProJersey(
                                    number: p.number,
                                    isCaptain: isCaptain,
                                    position: p.position,
                                  ),
                                  const SizedBox(height: 2),
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
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(46, 46),
            painter: _JerseyPainter(color: Colors.black.withValues(alpha: 0.3)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: CustomPaint(
                  size: const Size(42, 42),
                  painter: _JerseyPainter(
                    color: primaryColor,
                    stripeColor: stripeColor,
                    isStripe: !isGK,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            child: Text(
              number > 0 ? '$number' : '?',
              style: TextStyle(
                color: isGK ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2),
                ],
              ),
            ),
          ),
          if (isCaptain)
            Positioned(
              right: 2,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Text('C', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
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

    path.moveTo(size.width * 0.2, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.9);
    path.lineTo(size.width * 0.2, size.height * 0.9);
    path.close();

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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: rating > 80 ? AppColors.gold : (rating > 70 ? AppColors.primaryGreen : AppColors.muted),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text('$rating', style: const TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 3),
          Text(
            name.length > 10 ? '${name.substring(0, 8)}..' : name,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.3);

    final grassPaint = Paint()..style = PaintingStyle.fill;

    const stripes = 12;
    final stripeHeight = size.height / stripes;
    for (var i = 0; i < stripes; i++) {
      grassPaint.color = i % 2 == 0 
          ? const Color(0xFF0F6A3D).withValues(alpha: 0.15) 
          : const Color(0xFF0F6A3D).withValues(alpha: 0.08);
      canvas.drawRect(Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight), grassPaint);
    }

    canvas.drawRect(Rect.fromLTWH(5, 5, size.width - 10, size.height - 10), paint);

    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, paint);

    _drawPenaltyArea(canvas, size, paint, true);
    _drawPenaltyArea(canvas, size, paint, false);

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
  final String? id;
  final String name;
  final String position;
  final double top;
  final double left;
  final int rating;
  final int number;

  _Player({
    this.id,
    required this.name,
    required this.position,
    required this.top,
    required this.left,
    this.rating = 60,
    this.number = 0,
  });

  _Player copyWith({
    String? id,
    String? name,
    String? position,
    double? top,
    double? left,
    int? rating,
    int? number,
  }) {
    return _Player(
      id: id ?? this.id,
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
      'id': id,
      'name': name,
      'position': position,
      'top': top,
      'left': left,
      'rating': rating,
      'number': number,
    };
  }
}
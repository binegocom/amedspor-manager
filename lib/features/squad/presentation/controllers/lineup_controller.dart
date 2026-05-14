import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../data/services/ai_tactical_service.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../data/services/gamification_service.dart';

class LineupSlot {
  final String? id;
  final String name;
  final String position;
  final double top;
  final double left;
  final int rating;
  final int number;

  LineupSlot({
    this.id,
    required this.name,
    required this.position,
    required this.top,
    required this.left,
    this.rating = 60,
    this.number = 0,
  });

  LineupSlot copyWith({
    String? id,
    String? name,
    String? position,
    double? top,
    double? left,
    int? rating,
    int? number,
  }) {
    return LineupSlot(
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

class LineupBuilderState {
  final String selectedFormation;
  final String selectedPhilosophy;
  final String? captainName;
  final List<LineupSlot> players;
  final List<LineupSlot> substitutes;
  final bool isSaving;
  final bool isAiAnalyzing;
  final int remainingAiTokens;
  final String? error;
  final String? successMessage;
  final String? aiReport;
  final String? savedLineupId;

  LineupBuilderState({
    required this.selectedFormation,
    required this.selectedPhilosophy,
    this.captainName,
    required this.players,
    required this.substitutes,
    this.isSaving = false,
    this.isAiAnalyzing = false,
    this.remainingAiTokens = 0,
    this.error,
    this.successMessage,
    this.aiReport,
    this.savedLineupId,
  });

  int get lineupPower {
    final formationBonus = selectedFormation == '4-3-3' ? 8 : 5;
    final captainBonus = captainName == null ? 0 : 12;
    
    int philosophyBonus = 4;
    if (selectedPhilosophy == 'Tiki-Taka') philosophyBonus = 3;
    if (selectedPhilosophy == 'Catenaccio') philosophyBonus = 5;

    final ratingSum = players.fold<int>(0, (acc, p) => acc + p.rating);
    final ratingAverage = ratingSum / (players.isEmpty ? 1 : players.length);

    return (ratingAverage + formationBonus + captainBonus + philosophyBonus).round().clamp(0, 100);
  }

  LineupBuilderState copyWith({
    String? selectedFormation,
    String? selectedPhilosophy,
    String? captainName,
    List<LineupSlot>? players,
    List<LineupSlot>? substitutes,
    bool? isSaving,
    bool? isAiAnalyzing,
    int? remainingAiTokens,
    String? error,
    String? successMessage,
    String? aiReport,
    String? savedLineupId,
  }) {
    return LineupBuilderState(
      selectedFormation: selectedFormation ?? this.selectedFormation,
      selectedPhilosophy: selectedPhilosophy ?? this.selectedPhilosophy,
      captainName: captainName ?? this.captainName,
      players: players ?? this.players,
      substitutes: substitutes ?? this.substitutes,
      isSaving: isSaving ?? this.isSaving,
      isAiAnalyzing: isAiAnalyzing ?? this.isAiAnalyzing,
      remainingAiTokens: remainingAiTokens ?? this.remainingAiTokens,
      error: error,
      successMessage: successMessage,
      aiReport: aiReport,
      savedLineupId: savedLineupId ?? this.savedLineupId,
    );
  }
}

class LineupNotifier extends StateNotifier<LineupBuilderState> {
  LineupNotifier() : super(_createInitialState()) {
    loadAiTokens();
  }

  final LineupRepository _lineupRepository = LineupRepository();
  final PostRepository _postRepository = PostRepository();
  final AiTacticalService _aiTacticalService = AiTacticalService();
  final Uuid _uuid = const Uuid();

  static LineupBuilderState _createInitialState() {
    final initialPlayers = [
      LineupSlot(name: 'OYUNCU SEÇ', position: 'GK', top: 0.84, left: 0.50),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.66, left: 0.18),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.68, left: 0.38),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.68, left: 0.62),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'DEF', top: 0.66, left: 0.82),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'MID', top: 0.45, left: 0.30),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'MID', top: 0.45, left: 0.50),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'MID', top: 0.45, left: 0.70),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'FWD', top: 0.22, left: 0.22),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'FWD', top: 0.18, left: 0.50),
      LineupSlot(name: 'OYUNCU SEÇ', position: 'FWD', top: 0.22, left: 0.78),
    ];

    return LineupBuilderState(
      selectedFormation: '4-3-3',
      selectedPhilosophy: 'Gegenpressing',
      players: initialPlayers,
      substitutes: [],
    );
  }

  Future<void> loadAiTokens() async {
    final tokens = await _aiTacticalService.getRemainingTokens();
    state = state.copyWith(remainingAiTokens: tokens);
  }

  void setPhilosophy(String philosophy) {
    state = state.copyWith(selectedPhilosophy: philosophy);
  }

  void setCaptain(String name) {
    state = state.copyWith(captainName: name);
  }

  void setFormation(String formation) {
    final p = List<LineupSlot>.from(state.players);

    if (formation == '4-3-3') {
      p[0] = p[0].copyWith(top: 0.84, left: 0.50, position: 'GK');
      p[1] = p[1].copyWith(top: 0.66, left: 0.18, position: 'DEF');
      p[2] = p[2].copyWith(top: 0.68, left: 0.38, position: 'DEF');
      p[3] = p[3].copyWith(top: 0.68, left: 0.62, position: 'DEF');
      p[4] = p[4].copyWith(top: 0.66, left: 0.82, position: 'DEF');
      p[5] = p[5].copyWith(top: 0.45, left: 0.30, position: 'MID');
      p[6] = p[6].copyWith(top: 0.45, left: 0.50, position: 'MID');
      p[7] = p[7].copyWith(top: 0.45, left: 0.70, position: 'MID');
      p[8] = p[8].copyWith(top: 0.22, left: 0.22, position: 'FWD');
      p[9] = p[9].copyWith(top: 0.18, left: 0.50, position: 'FWD');
      p[10] = p[10].copyWith(top: 0.22, left: 0.78, position: 'FWD');
    } else if (formation == '4-2-3-1') {
      p[0] = p[0].copyWith(top: 0.84, left: 0.50, position: 'GK');
      p[1] = p[1].copyWith(top: 0.66, left: 0.18, position: 'DEF');
      p[2] = p[2].copyWith(top: 0.68, left: 0.38, position: 'DEF');
      p[3] = p[3].copyWith(top: 0.68, left: 0.62, position: 'DEF');
      p[4] = p[4].copyWith(top: 0.66, left: 0.82, position: 'DEF');
      p[5] = p[5].copyWith(top: 0.50, left: 0.40, position: 'MID');
      p[6] = p[6].copyWith(top: 0.50, left: 0.60, position: 'MID');
      p[7] = p[7].copyWith(top: 0.35, left: 0.50, position: 'MID');
      p[8] = p[8].copyWith(top: 0.28, left: 0.22, position: 'FWD');
      p[9] = p[9].copyWith(top: 0.16, left: 0.50, position: 'FWD');
      p[10] = p[10].copyWith(top: 0.28, left: 0.78, position: 'FWD');
    } else if (formation == '3-5-2') {
      p[0] = p[0].copyWith(top: 0.84, left: 0.50, position: 'GK');
      p[1] = p[1].copyWith(top: 0.66, left: 0.28, position: 'DEF');
      p[2] = p[2].copyWith(top: 0.68, left: 0.50, position: 'DEF');
      p[3] = p[3].copyWith(top: 0.66, left: 0.72, position: 'DEF');
      p[4] = p[4].copyWith(top: 0.48, left: 0.14, position: 'MID');
      p[5] = p[5].copyWith(top: 0.45, left: 0.35, position: 'MID');
      p[6] = p[6].copyWith(top: 0.42, left: 0.50, position: 'MID');
      p[7] = p[7].copyWith(top: 0.45, left: 0.65, position: 'MID');
      p[8] = p[8].copyWith(top: 0.48, left: 0.86, position: 'MID');
      p[9] = p[9].copyWith(top: 0.18, left: 0.40, position: 'FWD');
      p[10] = p[10].copyWith(top: 0.18, left: 0.60, position: 'FWD');
    } else if (formation == '4-4-2') {
      p[0] = p[0].copyWith(top: 0.84, left: 0.50, position: 'GK');
      p[1] = p[1].copyWith(top: 0.66, left: 0.18, position: 'DEF');
      p[2] = p[2].copyWith(top: 0.68, left: 0.38, position: 'DEF');
      p[3] = p[3].copyWith(top: 0.68, left: 0.62, position: 'DEF');
      p[4] = p[4].copyWith(top: 0.66, left: 0.82, position: 'DEF');
      p[5] = p[5].copyWith(top: 0.46, left: 0.20, position: 'MID');
      p[6] = p[6].copyWith(top: 0.46, left: 0.40, position: 'MID');
      p[7] = p[7].copyWith(top: 0.46, left: 0.60, position: 'MID');
      p[8] = p[8].copyWith(top: 0.46, left: 0.80, position: 'MID');
      p[9] = p[9].copyWith(top: 0.18, left: 0.40, position: 'FWD');
      p[10] = p[10].copyWith(top: 0.18, left: 0.60, position: 'FWD');
    } else if (formation == '3-4-3') {
      p[0] = p[0].copyWith(top: 0.84, left: 0.50, position: 'GK');
      p[1] = p[1].copyWith(top: 0.68, left: 0.25, position: 'DEF');
      p[2] = p[2].copyWith(top: 0.70, left: 0.50, position: 'DEF');
      p[3] = p[3].copyWith(top: 0.68, left: 0.75, position: 'DEF');
      p[4] = p[4].copyWith(top: 0.48, left: 0.18, position: 'MID');
      p[5] = p[5].copyWith(top: 0.46, left: 0.38, position: 'MID');
      p[6] = p[6].copyWith(top: 0.46, left: 0.62, position: 'MID');
      p[7] = p[7].copyWith(top: 0.48, left: 0.82, position: 'MID');
      p[8] = p[8].copyWith(top: 0.22, left: 0.25, position: 'FWD');
      p[9] = p[9].copyWith(top: 0.16, left: 0.50, position: 'FWD');
      p[10] = p[10].copyWith(top: 0.22, left: 0.75, position: 'FWD');
    } else if (formation == '5-4-1') {
      p[0] = p[0].copyWith(top: 0.84, left: 0.50, position: 'GK');
      p[1] = p[1].copyWith(top: 0.65, left: 0.12, position: 'DEF');
      p[2] = p[2].copyWith(top: 0.68, left: 0.30, position: 'DEF');
      p[3] = p[3].copyWith(top: 0.70, left: 0.50, position: 'DEF');
      p[4] = p[4].copyWith(top: 0.68, left: 0.70, position: 'DEF');
      p[5] = p[5].copyWith(top: 0.65, left: 0.88, position: 'DEF');
      p[6] = p[6].copyWith(top: 0.45, left: 0.22, position: 'MID');
      p[7] = p[7].copyWith(top: 0.42, left: 0.40, position: 'MID');
      p[8] = p[8].copyWith(top: 0.42, left: 0.60, position: 'MID');
      p[9] = p[9].copyWith(top: 0.45, left: 0.78, position: 'MID');
      p[10] = p[10].copyWith(top: 0.18, left: 0.50, position: 'FWD');
    } else if (formation == '4-1-2-1-2') {
      p[0] = p[0].copyWith(top: 0.84, left: 0.50, position: 'GK');
      p[1] = p[1].copyWith(top: 0.66, left: 0.18, position: 'DEF');
      p[2] = p[2].copyWith(top: 0.68, left: 0.38, position: 'DEF');
      p[3] = p[3].copyWith(top: 0.68, left: 0.62, position: 'DEF');
      p[4] = p[4].copyWith(top: 0.66, left: 0.82, position: 'DEF');
      p[5] = p[5].copyWith(top: 0.55, left: 0.50, position: 'MID');
      p[6] = p[6].copyWith(top: 0.44, left: 0.28, position: 'MID');
      p[7] = p[7].copyWith(top: 0.44, left: 0.72, position: 'MID');
      p[8] = p[8].copyWith(top: 0.32, left: 0.50, position: 'MID');
      p[9] = p[9].copyWith(top: 0.18, left: 0.35, position: 'FWD');
      p[10] = p[10].copyWith(top: 0.18, left: 0.65, position: 'FWD');
    }

    state = state.copyWith(selectedFormation: formation, players: p);
  }

  void assignPlayerToSlot(int index, PlayerModel player) {
    final p = List<LineupSlot>.from(state.players);
    p[index] = p[index].copyWith(
      id: player.id,
      name: player.name,
      rating: player.rating,
      number: player.number,
    );

    // Kaptan henüz seçilmemişse veya ilk oyuncu atanıyorsa otomatik kaptan yap
    String? newCap = state.captainName;
    if (newCap == null || !p.any((slot) => slot.name == newCap)) {
      newCap = player.name;
    }

    state = state.copyWith(players: p, captainName: newCap);
  }

  void addSubstitute(PlayerModel player) {
    final subs = List<LineupSlot>.from(state.substitutes);
    subs.add(LineupSlot(
      id: player.id,
      name: player.name,
      position: player.position,
      rating: player.rating,
      number: player.number,
      top: 0,
      left: 0,
    ));
    state = state.copyWith(substitutes: subs);
  }

  void removeSubstitute(int index) {
    final subs = List<LineupSlot>.from(state.substitutes);
    subs.removeAt(index);
    state = state.copyWith(substitutes: subs);
  }

  Future<void> autoFillWithOptimalAi() async {
    state = state.copyWith(isAiAnalyzing: true, error: null);

    try {
      // Aktif oyuncuları çek
      final snap = await firestoreService.players.where('active', isEqualTo: true).get();
      final allPlayers = snap.docs.map((d) => PlayerModel.fromMap(d.id, d.data())).toList();

      // İsim bazlı tekilleştir (en yüksek reytingliyi sakla)
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
        state = state.copyWith(isAiAnalyzing: false, error: 'Kadro havuzunda aktif ve uygun oyuncu bulunamadı.');
        return;
      }

      final p = List<LineupSlot>.from(state.players);
      final usedNames = <String>{};
      PlayerModel? highestRated;

      for (int i = 0; i < p.length; i++) {
        final posTarget = p[i].position;
        PlayerModel? candidate;

        try {
          candidate = pool.firstWhere((pl) => pl.position == posTarget && !usedNames.contains(pl.name));
        } catch (_) {
          // Pozisyona özel oyuncu kalmadıysa joker (herhangi bir en yüksek reytingli) ata
          try {
            candidate = pool.firstWhere((pl) => !usedNames.contains(pl.name));
          } catch (_) {}
        }

        if (candidate != null) {
          usedNames.add(candidate.name);
          p[i] = p[i].copyWith(
            id: candidate.id,
            name: candidate.name,
            rating: candidate.rating,
            number: candidate.number,
          );

          if (highestRated == null || candidate.rating > highestRated.rating) {
            highestRated = candidate;
          }
        }
      }

      String? cap = state.captainName;
      if (highestRated != null) {
        cap = highestRated.name;
      }

      state = state.copyWith(
        players: p,
        captainName: cap,
        isAiAnalyzing: false,
        successMessage: '✨ AI Danışman sahaya en uyumlu ve yüksek reytingli 11 oyuncuyu yerleştirdi!',
      );
    } catch (e) {
      state = state.copyWith(isAiAnalyzing: false, error: 'AI Optimizasyon Hatası: $e');
    }
  }

  Future<void> requestAiAdviceReport(bool buyWithXp) async {
    final selectedCount = state.players.where((p) => p.name != 'OYUNCU SEÇ').length;
    if (selectedCount < 7) {
      state = state.copyWith(error: 'AI analizi için sahada en az 7 oyuncu olmalıdır.');
      return;
    }

    state = state.copyWith(isAiAnalyzing: true, error: null);

    try {
      if (state.remainingAiTokens <= 0) {
        if (!buyWithXp) {
          state = state.copyWith(isAiAnalyzing: false);
          return;
        }

        final success = await _aiTacticalService.buyTokenWithXp();
        if (!success) {
          state = state.copyWith(isAiAnalyzing: false, error: 'Yetersiz XP! Jeton almak için daha fazla XP biriktirmelisiniz.');
          return;
        }
      } else {
        await _aiTacticalService.consumeToken();
      }

      await loadAiTokens();

      final report = await _aiTacticalService.synthesizeAdvice(
        state.selectedFormation,
        state.lineupPower,
        state.captainName,
      );

      state = state.copyWith(isAiAnalyzing: false, aiReport: report);
    } catch (e) {
      state = state.copyWith(isAiAnalyzing: false, error: 'Danışman Raporu Hatası: $e');
    }
  }

  Future<bool> saveLineup(String matchId) async {
    final user = authService.currentUser;
    if (user == null) {
      state = state.copyWith(error: 'AUTH_REQUIRED');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final lineupId = _uuid.v4();
      final lineup = LineupModel(
        id: lineupId,
        userId: user.uid,
        matchId: matchId,
        formation: state.selectedFormation,
        philosophy: state.selectedPhilosophy,
        players: state.players.map((p) => p.toMap()).toList(),
        substitutes: state.substitutes.map((p) => p.toMap()).toList(),
        likes: 0,
        power: state.lineupPower,
        commentsCount: 0,
        createdAt: DateTime.now(),
      );

      await _lineupRepository.saveLineup(lineup);

      await GamificationService().awardXp(
        userId: user.uid,
        amount: GamificationService.xpLineupSaved,
        reason: 'Kadro kurduğun için',
        eventType: 'lineup_saved',
        sourceType: 'lineup',
        sourceId: lineupId,
      );

      state = state.copyWith(isSaving: false, savedLineupId: lineupId);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Kaydetme Hatası: $e');
      return false;
    }
  }

  Future<bool> shareLineup(String matchId) async {
    final user = authService.currentUser;
    if (user == null) {
      state = state.copyWith(error: 'AUTH_REQUIRED');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final lineupId = _uuid.v4();
      final lineup = LineupModel(
        id: lineupId,
        userId: user.uid,
        matchId: matchId,
        formation: state.selectedFormation,
        philosophy: state.selectedPhilosophy,
        players: state.players.map((p) => p.toMap()).toList(),
        substitutes: state.substitutes.map((p) => p.toMap()).toList(),
        likes: 0,
        power: state.lineupPower,
        commentsCount: 0,
        createdAt: DateTime.now(),
      );

      await _lineupRepository.saveLineup(lineup);

      final post = PostModel(
        id: _uuid.v4(),
        userId: user.uid,
        username: user.email ?? 'Taraftar',
        title: 'Benim ${state.selectedFormation} (${state.selectedPhilosophy}) Kadrom',
        content: 'Yeni kadromu kurdum! Güç: ${state.lineupPower}. Sen de gel kadronu kur!',
        category: 'Kadro',
        likes: 0,
        commentsCount: 0,
        lineupId: lineupId,
        createdAt: DateTime.now(),
      );

      await _postRepository.createLineupPost(post: post, lineupId: lineupId);

      await GamificationService().awardXp(
        userId: user.uid,
        amount: GamificationService.xpLineupShared,
        reason: 'Kadro paylaştığın için',
        eventType: 'lineup_shared',
        sourceType: 'lineup',
        sourceId: lineupId,
      );

      state = state.copyWith(isSaving: false, successMessage: '✨ Kadron başarıyla akışta paylaşıldı! +15 XP');
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Paylaşım Hatası: $e');
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null, aiReport: null);
  }
}

final lineupControllerProvider = StateNotifierProvider<LineupNotifier, LineupBuilderState>((ref) {
  return LineupNotifier();
});

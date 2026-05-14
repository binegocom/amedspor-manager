import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../domain/models/training_drill.dart';

class TrainingState {
  final List<PlayerModel> players;
  final bool isLoading;
  final String? error;
  final Map<String, PlayerModel> pendingUpdates;

  TrainingState({
    required this.players,
    this.isLoading = false,
    this.error,
    required this.pendingUpdates,
  });

  TrainingState copyWith({
    List<PlayerModel>? players,
    bool? isLoading,
    String? error,
    Map<String, PlayerModel>? pendingUpdates,
  }) {
    return TrainingState(
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Hataları tek seferlik göstermek için bazen null bırakılabilir veya saklanabilir
      pendingUpdates: pendingUpdates ?? this.pendingUpdates,
    );
  }
}

class TrainingNotifier extends StateNotifier<TrainingState> {
  TrainingNotifier() : super(TrainingState(players: [], pendingUpdates: {})) {
    loadPlayers();
  }

  final PlayerRepository _playerRepository = PlayerRepository();
  StreamSubscription? _subscription;

  void loadPlayers() {
    final userId = authService.currentUser?.uid;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);

    _subscription?.cancel();
    _subscription = _playerRepository.watchActivePlayers(ownerId: userId).listen(
      (players) {
        // Lokal olarak bekleyen mutasyonları koruyarak listeyi birleştir
        final mergedPlayers = players.map((p) {
          return state.pendingUpdates[p.id] ?? p;
        }).toList();

        // Rating'e göre sırala (en güçlüler üstte)
        mergedPlayers.sort((a, b) => b.rating.compareTo(a.rating));

        state = state.copyWith(players: mergedPlayers, isLoading: false);
      },
      onError: (err) {
        state = state.copyWith(error: err.toString(), isLoading: false);
      },
    );
  }

  void trainPlayer(PlayerModel player, TrainingDrill drill) {
    // Kondisyon kontrolü
    if (player.fitness <= 10) {
      state = state.copyWith(error: '${player.name} çok yorgun! Antrenman yapabilmesi için dinlenmesi gerekiyor.');
      return;
    }

    PlayerModel updated = player;
    switch (drill) {
      case TrainingDrill.shooting:
        updated = player.copyWith(
          shooting: (player.shooting + 2).clamp(0, 99),
          fitness: (player.fitness - 5).clamp(0, 100),
        );
        break;
      case TrainingDrill.passing:
        updated = player.copyWith(
          passing: (player.passing + 2).clamp(0, 99),
          fitness: (player.fitness - 3).clamp(0, 100),
        );
        break;
      case TrainingDrill.defending:
        updated = player.copyWith(
          defending: (player.defending + 2).clamp(0, 99),
          fitness: (player.fitness - 4).clamp(0, 100),
        );
        break;
      case TrainingDrill.dribbling:
        updated = player.copyWith(
          dribbling: (player.dribbling + 2).clamp(0, 99),
          fitness: (player.fitness - 3).clamp(0, 100),
        );
        break;
      case TrainingDrill.positioning:
        updated = player.copyWith(
          positioning: (player.positioning + 2).clamp(0, 99),
          fitness: (player.fitness - 2).clamp(0, 100),
        );
        break;
      case TrainingDrill.composure:
        updated = player.copyWith(
          composure: (player.composure + 2).clamp(0, 99),
          fitness: (player.fitness - 2).clamp(0, 100),
        );
        break;
    }

    // OVR Güncellemesi
    updated = updated.copyWith(rating: updated.calculateRating());

    final newPending = Map<String, PlayerModel>.from(state.pendingUpdates);
    newPending[updated.id] = updated;

    final newPlayers = state.players.map((p) => p.id == updated.id ? updated : p).toList();

    state = state.copyWith(players: newPlayers, pendingUpdates: newPending, error: null);
  }

  Future<void> syncBatchToFirestore() async {
    if (state.pendingUpdates.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true);
      final batch = FirebaseFirestore.instance.batch();

      for (final player in state.pendingUpdates.values) {
        final docRef = FirebaseFirestore.instance.collection('players').doc(player.id);
        batch.update(docRef, player.toMap());
      }

      await batch.commit();

      state = state.copyWith(pendingUpdates: {}, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Eşitleme hatası: $e', isLoading: false);
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final trainingControllerProvider = StateNotifierProvider<TrainingNotifier, TrainingState>((ref) {
  return TrainingNotifier();
});

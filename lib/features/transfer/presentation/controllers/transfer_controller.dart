import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/club_model.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class EraPlayer {
  final String season;
  final String name;
  final String position;
  final int rating;
  final int price;
  final int? pointsCost;
  final bool isLegendary;

  const EraPlayer(
    this.season,
    this.name,
    this.position,
    this.rating,
    this.price, {
    this.pointsCost,
    this.isLegendary = false,
  });
}

class TransferMarketState {
  final List<EraPlayer> allPlayers;
  final Set<String> purchasedNames;
  final String selectedSeasonFilter;
  final int userPoints;
  final bool isProcessing;
  final String? error;
  final String? successMessage;
  final bool isAdPlaying;
  final int adTimeLeft;

  TransferMarketState({
    required this.allPlayers,
    required this.purchasedNames,
    required this.selectedSeasonFilter,
    this.userPoints = 0,
    this.isProcessing = false,
    this.error,
    this.successMessage,
    this.isAdPlaying = false,
    this.adTimeLeft = 0,
  });

  TransferMarketState copyWith({
    List<EraPlayer>? allPlayers,
    Set<String>? purchasedNames,
    String? selectedSeasonFilter,
    int? userPoints,
    bool? isProcessing,
    String? error,
    String? successMessage,
    bool? isAdPlaying,
    int? adTimeLeft,
  }) {
    return TransferMarketState(
      allPlayers: allPlayers ?? this.allPlayers,
      purchasedNames: purchasedNames ?? this.purchasedNames,
      selectedSeasonFilter: selectedSeasonFilter ?? this.selectedSeasonFilter,
      userPoints: userPoints ?? this.userPoints,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      successMessage: successMessage,
      isAdPlaying: isAdPlaying ?? this.isAdPlaying,
      adTimeLeft: adTimeLeft ?? this.adTimeLeft,
    );
  }
}

class TransferNotifier extends StateNotifier<TransferMarketState> {
  TransferNotifier() : super(_createInitialState()) {
    fetchUserPoints();
    _loadPurchasedPlayers();
  }

  final ClubRepository _clubRepo = ClubRepository();
  final PlayerRepository _playerRepo = PlayerRepository();
  Timer? _adTimer;

  static TransferMarketState _createInitialState() {
    const eraPlayers = [
      EraPlayer('2020-2021', 'Sinan Akaydın', 'FWD', 74, 150000),
      EraPlayer('2020-2021', 'Yusuf Yağmur', 'MID', 72, 120000),
      EraPlayer('2020-2021', 'Cerem Talha Dinçer', 'MID', 73, 130000),
      EraPlayer('2020-2021', 'Üstün Bilgi', 'FWD', 75, 160000),

      EraPlayer('2021-2022', 'Mervan Çelik', 'FWD', 76, 180000),
      EraPlayer('2021-2022', 'Muhlis İstemi', 'MID', 74, 140000),
      EraPlayer('2021-2022', 'Kutay Yokuşlu', 'DEF', 73, 135000),
      EraPlayer('2021-2022', 'Okan Deniz', 'FWD', 77, 200000),

      EraPlayer('2022-2023', 'Berk İsmail Ünsal', 'FWD', 79, 300000),
      EraPlayer('2022-2023', 'Mehmet Alaeddinoğlu', 'MID', 78, 280000),
      EraPlayer('2022-2023', 'Ömer Bozan', 'MID', 77, 260000),
      EraPlayer('2022-2023', 'Serkan Odabaşoğlu', 'MID', 76, 250000),

      EraPlayer('2023-2024', 'Çekdar Orhan', 'MID', 84, 600000),
      EraPlayer('2023-2024', 'Mert Çapar', 'FWD', 83, 550000),
      EraPlayer('2023-2024', 'Veli Çetin', 'DEF', 82, 500000),
      EraPlayer('2023-2024', 'Taner Gümüş', 'MID', 81, 450000),
      EraPlayer('2023-2024', 'Uğur Adem Gezer', 'DEF', 80, 420000),
      EraPlayer('2023-2024', 'Aykut Özer', 'GK', 81, 460000),
      EraPlayer('2023-2024', 'Batuhan Tur', 'DEF', 79, 400000),

      EraPlayer('2024-2025', 'Adama Traoré', 'MID', 86, 900000),
      EraPlayer('2024-2025', 'Max Gradel', 'FWD', 87, 950000),
      EraPlayer('2024-2025', 'Britt Assombalonga', 'FWD', 85, 850000),
      EraPlayer('2024-2025', 'Bruno Lourenço', 'MID', 84, 800000),
      EraPlayer('2024-2025', 'Ömer Bayram', 'DEF', 83, 750000),
      EraPlayer('2024-2025', 'Nicolas Nkoulou', 'DEF', 85, 820000),
      EraPlayer('2024-2025', 'Kristijan Lovrić', 'FWD', 84, 780000),

      EraPlayer('2025-2026', 'Azad Diyar (Altyapı)', 'MID', 80, 350000),
      EraPlayer('2025-2026', 'Baran Heval', 'FWD', 82, 400000),
      EraPlayer('2025-2026', 'Rojhat Dicle', 'DEF', 81, 380000),

      EraPlayer('Efsaneler', 'Deniz Naki', 'FWD', 88, 0, pointsCost: 2500, isLegendary: true),
      EraPlayer('Efsaneler', 'Şehmus Özer', 'FWD', 90, 0, pointsCost: 3000, isLegendary: true),
      EraPlayer('Efsaneler', 'Mansur Çalar', 'MID', 85, 0, pointsCost: 2000, isLegendary: true),
    ];

    return TransferMarketState(
      allPlayers: eraPlayers,
      purchasedNames: {},
      selectedSeasonFilter: 'Tümü',
    );
  }

  // Cost-efficiency: Tek seferlik veri çekimi, dinleme yok!
  Future<void> fetchUserPoints() async {
    final userId = authService.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await firestoreService.users.doc(userId).get();
      if (doc.exists) {
        state = state.copyWith(userPoints: doc.data()?['points'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadPurchasedPlayers() async {
    final ownerId = authService.currentUser?.uid;
    if (ownerId == null) return;

    try {
      final snap = await firestoreService.players.where('ownerId', isEqualTo: ownerId).get();
      final purchased = snap.docs.map((d) => d.data()['name'] as String).toSet();
      state = state.copyWith(purchasedNames: purchased);
    } catch (_) {}
  }

  void setSeasonFilter(String season) {
    state = state.copyWith(selectedSeasonFilter: season);
  }

  Future<void> _injectPlayerToRoster(EraPlayer ep) async {
    final ownerId = authService.currentUser?.uid;

    final newPlayer = PlayerModel(
      id: 'era_${ep.season}_${DateTime.now().microsecondsSinceEpoch}',
      ownerId: ownerId,
      name: ep.name,
      position: ep.position,
      number: 10 + state.purchasedNames.length,
      rating: ep.rating,
      active: true,
      age: ep.isLegendary ? 29 : 25,
      shooting: ep.position == 'FWD' ? ep.rating + 5 : ep.rating,
      defending: ep.position == 'MID' ? ep.rating - 5 : ep.rating,
      passing: ep.rating + 2,
    );

    await _playerRepo.createPlayer(newPlayer);
    
    final pSet = Set<String>.from(state.purchasedNames);
    pSet.add(ep.name);
    state = state.copyWith(purchasedNames: pSet);
  }

  Future<void> buyNormalPlayer(ClubModel club, EraPlayer ep) async {
    if (state.isProcessing || state.purchasedNames.contains(ep.name)) return;

    if (club.cash < ep.price) {
      state = state.copyWith(error: 'Yetersiz bütçe! Bu transfer için ${ep.price - club.cash} ₺ daha gerekiyor.');
      return;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      await _clubRepo.updateClub(club.copyWith(cash: club.cash - ep.price));
      await _injectPlayerToRoster(ep);
      state = state.copyWith(
        isProcessing: false,
        successMessage: '${ep.name} kulübümüze katıldı! Bütçeden ${ep.price} ₺ düşüldü.',
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: 'Transfer başarısız: $e');
    }
  }

  Future<void> buyLegendaryWithPoints(EraPlayer ep) async {
    final cost = ep.pointsCost ?? 2000;
    if (state.userPoints < cost) {
      state = state.copyWith(error: 'Yetersiz Taraftar Puanı (DP)! Mevcut: ${state.userPoints} DP / Gereken: $cost DP.');
      return;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        // Kontrollü yerel bakiye düşümü ve toplu senkronizasyon
        final newPoints = state.userPoints - cost;
        state = state.copyWith(userPoints: newPoints);

        await firestoreService.users.doc(userId).update({
          'points': FieldValue.increment(-cost),
        });
      }
      await _injectPlayerToRoster(ep);

      state = state.copyWith(
        isProcessing: false,
        successMessage: '🌟 EFSANE TRANSFER: ${ep.name} kadroya katıldı! $cost DP harcandı.',
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: 'Hata: $e');
    }
  }

  void startAdSimulation(EraPlayer ep) {
    state = state.copyWith(isAdPlaying: true, adTimeLeft: 4, error: null);

    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final nextTime = state.adTimeLeft - 1;
      if (nextTime <= 0) {
        timer.cancel();
        state = state.copyWith(isAdPlaying: false, isProcessing: true);

        try {
          await _injectPlayerToRoster(ep);
          state = state.copyWith(
            isProcessing: false,
            successMessage: '📺 Sponsor Reklamı tamamlandı! ${ep.name} bedelsiz olarak kadronuza eklendi.',
          );
        } catch (e) {
          state = state.copyWith(isProcessing: false, error: 'Reklam ödülü hatası: $e');
        }
      } else {
        state = state.copyWith(adTimeLeft: nextTime);
      }
    });
  }

  void cancelAdSimulation() {
    _adTimer?.cancel();
    state = state.copyWith(isAdPlaying: false, adTimeLeft: 0);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }
}

final transferControllerProvider = StateNotifierProvider<TransferNotifier, TransferMarketState>((ref) {
  return TransferNotifier();
});

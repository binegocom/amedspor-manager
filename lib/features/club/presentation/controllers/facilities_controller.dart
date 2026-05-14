import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/club_model.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class FacilitiesState {
  final int userPoints;
  final bool isProcessing;
  final String? error;
  final String? successMessage;
  final bool isAdSpeedupPlaying;
  final int adSpeedupTimeLeft;

  FacilitiesState({
    this.userPoints = 0,
    this.isProcessing = false,
    this.error,
    this.successMessage,
    this.isAdSpeedupPlaying = false,
    this.adSpeedupTimeLeft = 0,
  });

  FacilitiesState copyWith({
    int? userPoints,
    bool? isProcessing,
    String? error,
    String? successMessage,
    bool? isAdSpeedupPlaying,
    int? adSpeedupTimeLeft,
  }) {
    return FacilitiesState(
      userPoints: userPoints ?? this.userPoints,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      successMessage: successMessage,
      isAdSpeedupPlaying: isAdSpeedupPlaying ?? this.isAdSpeedupPlaying,
      adSpeedupTimeLeft: adSpeedupTimeLeft ?? this.adSpeedupTimeLeft,
    );
  }
}

class FacilitiesNotifier extends StateNotifier<FacilitiesState> {
  FacilitiesNotifier() : super(FacilitiesState()) {
    fetchUserPoints();
  }

  Timer? _adTimer;

  // Cache-first fetch, gereksiz okuma/yazma döngüsü yok
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

  int getDpCostForLevel(int nextLevel) {
    if (nextLevel < 5) return 0;
    if (nextLevel == 5) return 500;
    if (nextLevel == 6) return 1000;
    return 1500;
  }

  int getConstructionSecondsForLevel(int nextLevel) {
    if (nextLevel <= 3) return 0;
    if (nextLevel == 4) return 60;
    if (nextLevel == 5) return 120;
    return 180;
  }

  Future<void> startUpgrade(ClubModel club, String type) async {
    if (club.activeConstructionType != null) {
      state = state.copyWith(error: '⚠️ Aynı anda sadece bir tesis inşa edilebilir! Önce mevcut inşaatı tamamlayın veya hızlandırın.');
      return;
    }

    if (state.isProcessing) return;

    int cost = 0;
    String facilityName = '';
    int currentLevel = 0;

    switch (type) {
      case 'stadium':
        currentLevel = club.stadiumLevel;
        cost = 5000 * currentLevel;
        facilityName = 'Stadyum';
      case 'training':
        currentLevel = club.trainingLevel;
        cost = 3000 * currentLevel;
        facilityName = 'Antrenman Merkezi';
      case 'medical':
        currentLevel = club.medicalLevel;
        cost = 4000 * currentLevel;
        facilityName = 'Sağlık Merkezi';
      case 'academy':
        currentLevel = club.youthAcademyLevel;
        cost = 3500 * currentLevel;
        facilityName = 'Altyapı Akademisi';
      default:
        return;
    }

    final nextLevel = currentLevel + 1;
    final dpCost = getDpCostForLevel(nextLevel);
    final buildDurationSeconds = getConstructionSecondsForLevel(nextLevel);

    if (club.cash < cost) {
      state = state.copyWith(error: 'Yetersiz Bütçe! $facilityName yükseltmesi için ${cost - club.cash} ₺ daha gerekiyor.');
      return;
    }

    if (dpCost > 0 && state.userPoints < dpCost) {
      state = state.copyWith(error: 'Yetersiz Taraftar Puanı (DP)! İmece usulü destek için $dpCost DP gerekiyor. Mevcut: ${state.userPoints} DP.');
      return;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Optimistic update for UI responsiveness
      if (dpCost > 0) {
        state = state.copyWith(userPoints: state.userPoints - dpCost);
      }

      // Güvenli Server-Authoritative Cloud Function Çağrısı
      final callable = FirebaseFunctions.instance.httpsCallable('upgradeClubFacility');
      final resp = await callable.call({
        'clubId': club.id,
        'facilityType': type,
        'isInstantUnlock': false,
        'completeExisting': false,
      });

      final data = resp.data as Map<String, dynamic>;
      final isInstant = data['isInstant'] == true;

      if (!isInstant) {
        state = state.copyWith(
          isProcessing: false,
          successMessage: '🏗️ $facilityName inşaatı başladı! Tamamlanma süresi: ${buildDurationSeconds ~/ 60} dk.',
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          successMessage: '✨ $facilityName anında Seviye $nextLevel olarak hizmete açıldı!',
        );
      }

      fetchUserPoints();
    } catch (e) {
      // Hata durumunda puanı geri al
      fetchUserPoints();
      state = state.copyWith(isProcessing: false, error: 'İnşaat hatası: $e');
    }
  }

  Future<void> completeActiveConstructionInstantly(ClubModel club) async {
    final type = club.activeConstructionType;
    final targetLevel = club.activeConstructionTargetLevel;
    if (type == null || targetLevel == null) return;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Güvenli Server-Authoritative Cloud Function Çağrısı
      final callable = FirebaseFunctions.instance.httpsCallable('upgradeClubFacility');
      await callable.call({
        'clubId': club.id,
        'completeExisting': true,
      });

      state = state.copyWith(
        isProcessing: false,
        successMessage: '🎉 İnşaat tamamlandı! Tesis başarıyla Seviye $targetLevel seviyesine yükseltildi.',
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: 'Tamamlama hatası: $e');
    }
  }

  void startAdSpeedupSimulation(ClubModel club) {
    state = state.copyWith(isAdSpeedupPlaying: true, adSpeedupTimeLeft: 4, error: null);

    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final nextTime = state.adSpeedupTimeLeft - 1;
      if (nextTime <= 0) {
        timer.cancel();
        state = state.copyWith(isAdSpeedupPlaying: false);
        await completeActiveConstructionInstantly(club);
      } else {
        state = state.copyWith(adSpeedupTimeLeft: nextTime);
      }
    });
  }

  void cancelAdSpeedupSimulation() {
    _adTimer?.cancel();
    state = state.copyWith(isAdSpeedupPlaying: false, adSpeedupTimeLeft: 0);
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

final facilitiesControllerProvider = StateNotifierProvider<FacilitiesNotifier, FacilitiesState>((ref) {
  return FacilitiesNotifier();
});

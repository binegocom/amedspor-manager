import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/club_repository.dart';

class SponsorItem {
  final String name;
  final int weeklyPay;
  final int winBonus;
  final String timeLeft;
  final int durationWeeks;
  final bool isActive;

  SponsorItem({
    required this.name,
    required this.weeklyPay,
    required this.winBonus,
    required this.timeLeft,
    this.durationWeeks = 0,
    this.isActive = false,
  });

  SponsorItem copyWith({
    String? name,
    int? weeklyPay,
    int? winBonus,
    String? timeLeft,
    int? durationWeeks,
    bool? isActive,
  }) {
    return SponsorItem(
      name: name ?? this.name,
      weeklyPay: weeklyPay ?? this.weeklyPay,
      winBonus: winBonus ?? this.winBonus,
      timeLeft: timeLeft ?? this.timeLeft,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SponsorshipState {
  final List<SponsorItem> activeSponsors;
  final List<SponsorItem> availableOffers;
  final Set<String> signedSponsorNames;
  final bool isProcessing;
  final String? error;
  final String? successMessage;

  SponsorshipState({
    required this.activeSponsors,
    required this.availableOffers,
    required this.signedSponsorNames,
    this.isProcessing = false,
    this.error,
    this.successMessage,
  });

  SponsorshipState copyWith({
    List<SponsorItem>? activeSponsors,
    List<SponsorItem>? availableOffers,
    Set<String>? signedSponsorNames,
    bool? isProcessing,
    String? error,
    String? successMessage,
  }) {
    return SponsorshipState(
      activeSponsors: activeSponsors ?? this.activeSponsors,
      availableOffers: availableOffers ?? this.availableOffers,
      signedSponsorNames: signedSponsorNames ?? this.signedSponsorNames,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      successMessage: successMessage,
    );
  }
}

class SponsorshipNotifier extends StateNotifier<SponsorshipState> {
  SponsorshipNotifier() : super(_createInitialState());

  final ClubRepository _clubRepo = ClubRepository();

  static SponsorshipState _createInitialState() {
    final active = [
      SponsorItem(
        name: 'DİYARBAKIR TİCARET ODASI',
        weeklyPay: 15000,
        winBonus: 5000,
        timeLeft: '2 Hafta',
        isActive: true,
      ),
    ];

    final offers = [
      SponsorItem(
        name: 'AZAD PETROL',
        weeklyPay: 20000,
        winBonus: 2500,
        timeLeft: '4 Hafta',
        durationWeeks: 4,
      ),
      SponsorItem(
        name: 'SUR İNŞAAT',
        weeklyPay: 12000,
        winBonus: 8000,
        timeLeft: '8 Hafta',
        durationWeeks: 8,
      ),
    ];

    return SponsorshipState(
      activeSponsors: active,
      availableOffers: offers,
      signedSponsorNames: {},
    );
  }

  Future<void> signSponsor(ClubModel club, SponsorItem offer) async {
    if (state.isProcessing || state.signedSponsorNames.contains(offer.name)) return;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // İlk hafta ödemesini imza parası olarak anında kasaya ekle
      await _clubRepo.updateClub(club.copyWith(cash: club.cash + offer.weeklyPay));

      final updatedNames = Set<String>.from(state.signedSponsorNames)..add(offer.name);
      
      // Tekliflerden kaldırıp aktif listesine ekle
      final remainingOffers = state.availableOffers.where((o) => o.name != offer.name).toList();
      final newActive = List<SponsorItem>.from(state.activeSponsors)..add(
        offer.copyWith(isActive: true, timeLeft: 'Yeni İmzalandı'),
      );

      state = state.copyWith(
        isProcessing: false,
        signedSponsorNames: updatedNames,
        availableOffers: remainingOffers,
        activeSponsors: newActive,
        successMessage: '${offer.name} ile anlaşma imzalandı! Kasanıza anında ${offer.weeklyPay} ₺ eklendi.',
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: 'Sponsorluk imzalanamadı: $e');
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final sponsorshipControllerProvider = StateNotifierProvider<SponsorshipNotifier, SponsorshipState>((ref) {
  return SponsorshipNotifier();
});

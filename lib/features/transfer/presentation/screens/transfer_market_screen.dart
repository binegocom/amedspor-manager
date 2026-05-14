import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_card.dart';
import '../controllers/transfer_controller.dart';

class TransferMarketScreen extends ConsumerStatefulWidget {
  const TransferMarketScreen({super.key});

  @override
  ConsumerState<TransferMarketScreen> createState() =>
      _TransferMarketScreenState();
}

class _TransferMarketScreenState extends ConsumerState<TransferMarketScreen> {
  BuildContext? _adDialogContext;

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(currentClubStreamProvider);
    final state = ref.watch(transferControllerProvider);
    final notifier = ref.read(transferControllerProvider.notifier);

    // Mesaj/Hata ve Dinamik Reklam Modal Yönetimi
    ref.listen<TransferMarketState>(transferControllerProvider, (
      previous,
      next,
    ) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryRed,
            content: Text(next.error!),
          ),
        );
        notifier.clearMessages();
      }

      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Text(next.successMessage!),
          ),
        );
        notifier.clearMessages();
      }

      // Reklam Simülasyonu Modal Yönetimi
      if (next.isAdPlaying && (previous?.isAdPlaying != true)) {
        _showAdModal(context, notifier);
      } else if (!next.isAdPlaying && (previous?.isAdPlaying == true)) {
        if (_adDialogContext != null && _adDialogContext!.mounted) {
          Navigator.pop(_adDialogContext!);
          _adDialogContext = null;
        }
      }
    });

    final filteredEras = state.selectedSeasonFilter == 'Tümü'
        ? state.allPlayers
        : state.allPlayers
              .where((p) => p.season == state.selectedSeasonFilter)
              .toList();

    final seasons = [
      'Tümü',
      '2020-2021',
      '2021-2022',
      '2022-2023',
      '2023-2024',
      '2024-2025',
      '2025-2026',
      'Efsaneler',
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('TRANSFER PAZARI', style: AppTextStyles.h3),
        actions: [
          // Optimize Edilmiş DP Göstergesi (Cache-first)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${state.userPoints} DP',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: clubAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Hata: $err',
            style: const TextStyle(color: AppColors.primaryRed),
          ),
        ),
        data: (club) {
          if (club == null) {
            return const Center(
              child: Text(
                'Kulüp bilgisi bulunamadı.',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          return Column(
            children: [
              // Bilgilendirme Banner'ı
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryRed,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Efsanevi oyuncuları kadronuza katmak için Taraftar Puanı (DP) biriktirebilir veya Ödüllü Sponsor Reklamlarını izleyebilirsiniz.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sezon Filtre Çubuğu
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: seasons.length,
                  itemBuilder: (context, index) {
                    final season = seasons[index];
                    final isSelected = season == state.selectedSeasonFilter;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(season),
                        selected: isSelected,
                        onSelected: (val) => notifier.setSeasonFilter(season),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primaryRed,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.muted,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Kürate Edilmiş Havuz
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  itemCount: filteredEras.length,
                  itemBuilder: (context, index) {
                    final ep = filteredEras[index];
                    return _buildMarketItem(context, club, ep, state, notifier);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMarketItem(
    BuildContext context,
    ClubModel club,
    EraPlayer ep,
    TransferMarketState state,
    TransferNotifier notifier,
  ) {
    final isPurchased = state.purchasedNames.contains(ep.name);

    Color posColor = AppColors.primaryGreen;
    switch (ep.position) {
      case 'FWD':
        posColor = AppColors.primaryRed;
        break;
      case 'MID':
        posColor = Colors.blue;
        break;
      case 'DEF':
        posColor = AppColors.primaryGreen;
        break;
      default:
        posColor = AppColors.gold;
        break;
    }

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: isPurchased ? Colors.black45 : AppColors.surface,
      child: Opacity(
        opacity: isPurchased ? 0.6 : 1.0,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ep.isLegendary
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : posColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ep.isLegendary
                      ? AppColors.gold
                      : posColor.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: ep.isLegendary
                    ? const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.gold,
                        size: 24,
                      )
                    : Text(
                        ep.position,
                        style: TextStyle(
                          color: posColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ep.name,
                    style: TextStyle(
                      color: ep.isLegendary ? AppColors.gold : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ep.isLegendary
                              ? AppColors.gold.withValues(alpha: 0.2)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ep.season,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Genel Güç: ${ep.rating}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ep.isLegendary)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${ep.pointsCost} DP',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '${ep.price} ₺',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 84,
                  child: AppButton(
                    text: isPurchased
                        ? 'KADRODA'
                        : (ep.isLegendary ? 'ÖZEL' : 'AL'),
                    height: 32,
                    color: isPurchased
                        ? AppColors.muted
                        : (ep.isLegendary
                              ? AppColors.gold
                              : AppColors.primaryGreen),
                    textColor: ep.isLegendary && !isPurchased
                        ? Colors.black
                        : Colors.white,
                    isLoading: state.isProcessing && !isPurchased,
                    onTap: () {
                      if (isPurchased) return;
                      if (ep.isLegendary) {
                        _showLegendaryTransferOptions(context, ep, notifier);
                      } else {
                        notifier.buyNormalPlayer(club, ep);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLegendaryTransferOptions(
    BuildContext context,
    EraPlayer ep,
    TransferNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${ep.name} Transferi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Güç: ${ep.rating} OVR',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Efsane oyuncular yüksek kulüp sadakati ve Taraftar Puanı gerektirir. Transferi gerçekleştirmek için bir yöntem seçin:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: '💰 ${ep.pointsCost} DP Harca',
              type: AppButtonType.primary,
              height: 42,
              onTap: () {
                Navigator.pop(ctx);
                notifier.buyLegendaryWithPoints(ep);
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              text: '📺 Sponsor Reklamı İzle (Ücretsiz)',
              color: Colors.blue.shade600,
              height: 42,
              onTap: () {
                Navigator.pop(ctx);
                notifier.startAdSimulation(ep);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdModal(BuildContext context, TransferNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _adDialogContext = dialogCtx;
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            notifier.cancelAdSimulation();
          },
          child: Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(transferControllerProvider);
              return AlertDialog(
                backgroundColor: const Color(0xFF121212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.gold, width: 2),
                ),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.ondemand_video_rounded,
                          color: AppColors.gold,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'ÖDÜLLÜ SPONSOR REKLAMI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.primaryRed,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Amedspor Store Destek Reklamı\nLütfen bekleyin...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${state.adTimeLeft} sn',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.adTimeLeft > 0
                          ? 'Reklamı izleyerek efsaneyi kulübe kazandırıyorsunuz.'
                          : '✅ Reklam Tamamlandı!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

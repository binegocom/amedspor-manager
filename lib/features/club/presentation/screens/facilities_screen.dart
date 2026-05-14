import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_card.dart';
import '../controllers/facilities_controller.dart';

class FacilitiesScreen extends ConsumerStatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  ConsumerState<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends ConsumerState<FacilitiesScreen> {
  BuildContext? _adDialogContext;

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final state = ref.watch(facilitiesControllerProvider);
    final notifier = ref.read(facilitiesControllerProvider.notifier);
    final clubAsync = ref.watch(currentClubStreamProvider);

    // Mesaj ve Reklam Modalı Yönetimi
    ref.listen<FacilitiesState>(facilitiesControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.primaryRed, content: Text(next.error!)),
        );
        notifier.clearMessages();
      }

      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.primaryGreen, content: Text(next.successMessage!)),
        );
        notifier.clearMessages();
      }

      // Reklam Hızlandırıcı Modal Yönetimi
      if (next.isAdSpeedupPlaying && (previous?.isAdSpeedupPlaying != true)) {
        _showAdModal(context, notifier);
      } else if (!next.isAdSpeedupPlaying && (previous?.isAdSpeedupPlaying == true)) {
        if (_adDialogContext != null && _adDialogContext!.mounted) {
          Navigator.pop(_adDialogContext!);
          _adDialogContext = null;
        }
      }
    });

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          title: const Text('KULÜP TESİSLERİ', style: AppTextStyles.h3),
        ),
        body: const Center(
          child: Text('Giriş yapılması gerekiyor', style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('KULÜP TESİSLERİ', style: AppTextStyles.h3),
        actions: [
          // Optimize Edilmiş DP Göstergesi
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
                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${state.userPoints} DP', 
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: clubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        error: (err, stack) => Center(child: Text('Hata oluştu: $err', style: const TextStyle(color: AppColors.primaryRed))),
        data: (club) {
          if (club == null) {
            return const Center(child: Text('Kulüp verisi bulunamadı', style: TextStyle(color: AppColors.muted)));
          }

          final activeType = club.activeConstructionType;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Bakiye Özeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('KULÜP KASASI:', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${club.cash} ₺', style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Aktif İnşaat Banner'ı
              if (activeType != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade900.withValues(alpha: 0.3), Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade700, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '🏗️ YÜKSELTME DEVAM EDİYOR (${activeType.toUpperCase()})',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Sayaç İzolasyonu: Sadece bu alt widget saniyelik bazda setState tetikler!
                      _ConstructionCountdownBuilder(
                        club: club,
                        notifier: notifier,
                        state: state,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Stadyum
              _buildFacilityCard(
                club: club,
                type: 'stadium',
                title: 'Stadyum',
                description: 'Daha fazla bilet geliri ve taraftar desteği sağlar.',
                level: club.stadiumLevel,
                icon: Icons.stadium_rounded,
                baseCost: 5000,
                gameplayBuff: '+%${club.stadiumLevel * 2} İç Saha Seyirci Desteği & Simülasyon Moral Artışı',
                state: state,
                notifier: notifier,
              ),
              const SizedBox(height: 16),

              // Antrenman Merkezi
              _buildFacilityCard(
                club: club,
                type: 'training',
                title: 'Antrenman Merkezi',
                description: 'Antrenmanlarda daha fazla gelişim puanı kazandırır.',
                level: club.trainingLevel,
                icon: Icons.fitness_center_rounded,
                baseCost: 3000,
                gameplayBuff: club.trainingLevel >= 5
                    ? '✨ Altyapıdan Ücretsiz Genç Yetenek Keşfi (Scout) Aktif!'
                    : 'Altyapı Scout yeteneği için Seviye 5 gerekli',
                state: state,
                notifier: notifier,
              ),
              const SizedBox(height: 16),

              // Sağlık Merkezi
              _buildFacilityCard(
                club: club,
                type: 'medical',
                title: 'Sağlık Merkezi',
                description: 'Oyuncuların kondisyonu daha hızlı toparlanır.',
                level: club.medicalLevel,
                icon: Icons.medical_services_rounded,
                baseCost: 4000,
                gameplayBuff: '+%${club.medicalLevel * 3} Kondisyon Yenilenme Hızı & Yaşlanma Geciktirici Etki',
                state: state,
                notifier: notifier,
              ),
              const SizedBox(height: 16),

              // Altyapı Akademisi
              _buildFacilityCard(
                club: club,
                type: 'academy',
                title: 'Altyapı Akademisi',
                description: 'Geleceğin yıldız adaylarını yetiştirir ve keşfeder.',
                level: club.youthAcademyLevel,
                icon: Icons.school_rounded,
                baseCost: 3500,
                gameplayBuff: '+%${club.youthAcademyLevel * 5} Genç Yetenek Başlangıç Reytingi & Yıldız Çıkma Şansı',
                state: state,
                notifier: notifier,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFacilityCard({
    required ClubModel club,
    required String type,
    required String title,
    required String description,
    required int level,
    required IconData icon,
    required int baseCost,
    required String gameplayBuff,
    required FacilitiesState state,
    required FacilitiesNotifier notifier,
  }) {
    final nextLevel = level + 1;
    final cost = baseCost * level;
    final dpCost = notifier.getDpCostForLevel(nextLevel);
    final buildSeconds = notifier.getConstructionSecondsForLevel(nextLevel);

    Color tierBgColor = Colors.brown.withValues(alpha: 0.12);
    Color tierBorderColor = Colors.brown.shade700;
    String tierName = '🥉 Yerel Tesis';

    if (level >= 7) {
      tierBgColor = AppColors.gold.withValues(alpha: 0.12);
      tierBorderColor = AppColors.gold;
      tierName = '🥇 Ultra Lüks Kompleks';
    } else if (level >= 4) {
      tierBgColor = Colors.blueGrey.withValues(alpha: 0.18);
      tierBorderColor = Colors.blueGrey.shade400;
      tierName = '🥈 Modern Tesis';
    }

    final isThisUnderConstruction = club.activeConstructionType == type;
    final isAnyConstructionActive = club.activeConstructionType != null;

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          color: tierBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tierBorderColor.withValues(alpha: 0.4), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tierBorderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tierBorderColor),
                  ),
                  child: Icon(icon, color: tierBorderColor != Colors.brown.shade700 ? tierBorderColor : Colors.orangeAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('Seviye $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                            child: Text(tierName, style: TextStyle(color: tierBorderColor != Colors.brown.shade700 ? tierBorderColor : Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGreen, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(gameplayBuff, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (isThisUnderConstruction) ...[
              const Center(
                child: Text(
                  '🏗️ BU TESİS ŞU AN YÜKSELTİLİYOR',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SONRAKİ: SEVİYE $nextLevel', style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$cost ₺', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      if (dpCost > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 12),
                            const SizedBox(width: 2),
                            Text('+ $dpCost DP İmece', style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      if (buildSeconds > 0)
                        Text('⏱️ İnşaat: ${buildSeconds ~/ 60} dk', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                    ],
                  ),
                  SizedBox(
                    width: 110,
                    child: AppButton(
                      text: buildSeconds > 0 ? 'İNŞA ET' : 'YÜKSELT',
                      height: 34,
                      color: isAnyConstructionActive ? AppColors.muted : AppColors.primaryGreen,
                      isLoading: state.isProcessing && !isAnyConstructionActive,
                      onTap: () => notifier.startUpgrade(club, type),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAdModal(BuildContext context, FacilitiesNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _adDialogContext = dialogCtx;
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            notifier.cancelAdSpeedupSimulation();
          },
          child: Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(facilitiesControllerProvider);
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
                        Icon(Icons.bolt_rounded, color: AppColors.gold, size: 28),
                        SizedBox(width: 10),
                        Text('İNŞAAT HIZLANDIRICI REKLAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 150,
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
                              CircularProgressIndicator(color: AppColors.primaryRed),
                              SizedBox(height: 16),
                              Text(
                                'Sponsor Videosu Oynatılıyor...\nİnşaat süreniz sıfırlanacak.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                              child: Text('${state.adSpeedupTimeLeft} sn', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.adSpeedupTimeLeft > 0 ? 'Reklamı izleyerek tesis inşasını anında bitiriyorsunuz.' : '✅ Reklam Tamamlandı!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
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

// Tamamen izole edilmiş, saniyelik çizimleri ana sayfaya yansıtmayan bağımsız Ticker widget'ı
class _ConstructionCountdownBuilder extends StatefulWidget {
  final ClubModel club;
  final FacilitiesNotifier notifier;
  final FacilitiesState state;

  const _ConstructionCountdownBuilder({
    required this.club,
    required this.notifier,
    required this.state,
  });

  @override
  State<_ConstructionCountdownBuilder> createState() => _ConstructionCountdownBuilderState();
}

class _ConstructionCountdownBuilderState extends State<_ConstructionCountdownBuilder> {
  Timer? _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _ConstructionCountdownBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.club.constructionEndsAt != oldWidget.club.constructionEndsAt) {
      _calculateRemaining();
      _startTimer();
    }
  }

  void _calculateRemaining() {
    final endsAt = widget.club.constructionEndsAt;
    if (endsAt == null) {
      _remaining = 0;
    } else {
      _remaining = endsAt.difference(DateTime.now()).inSeconds;
      if (_remaining < 0) _remaining = 0;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remaining <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final endsAt = widget.club.constructionEndsAt;
      if (endsAt == null) {
        timer.cancel();
        setState(() => _remaining = 0);
        return;
      }

      final left = endsAt.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining = left);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= 0) {
      return AppButton(
        text: '✨ İNŞAAT TAMAMLANDI (AÇ)',
        type: AppButtonType.primary,
        height: 36,
        isLoading: widget.state.isProcessing,
        onTap: () => widget.notifier.completeActiveConstructionInstantly(widget.club),
      );
    }

    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Text('Kalan Süre: $timeStr', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
        const Spacer(),
        SizedBox(
          width: 140,
          child: AppButton(
            text: '📺 HIZLANDIR',
            color: Colors.blue.shade600,
            height: 32,
            isLoading: widget.state.isProcessing,
            onTap: () => widget.notifier.startAdSpeedupSimulation(widget.club),
          ),
        ),
      ],
    );
  }
}

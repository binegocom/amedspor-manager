import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/models/legend_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class MuseumScreen extends ConsumerStatefulWidget {
  const MuseumScreen({super.key});

  @override
  ConsumerState<MuseumScreen> createState() => _MuseumScreenState();
}

class _MuseumScreenState extends ConsumerState<MuseumScreen> {
  final Set<String> _unlockedIds = {'1', '3'}; // Varsayılan açık efsaneler
  bool _isProcessing = false;
  String? _unlockingLegendId;

  Future<void> _unlockLegend(
    BuildContext context,
    ClubModel club,
    LegendModel legend,
  ) async {
    if (_isProcessing || _unlockedIds.contains(legend.id)) return;

    const int tokenCost = 5;

    if (club.tokens < tokenCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text(
            'Yetersiz Token! Kilidi açmak için $tokenCost Token gerekiyor (Mevcut: ${club.tokens}).',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _unlockingLegendId = legend.id;
    });

    try {
      final clubRepo = ClubRepository();

      // Token eksilt ve İtibar Puanını kalıcı olarak +2 artır
      await clubRepo.updateClub(
        club.copyWith(
          tokens: club.tokens - tokenCost,
          reputation: club.reputation + 2,
        ),
      );

      setState(() {
        _unlockedIds.add(legend.id);
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text(
            '✨ ${legend.name} destanı kulüp tarihine yazıldı! Kalıcı İtibar Puanınız +2 arttı.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Kilit açılamadı: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _unlockingLegendId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(currentClubStreamProvider);

    final baseLegends = [
      LegendModel(
        id: '1',
        name: 'Deniz Naki',
        role: 'Unutulmaz Forvet',
        rating: 92,
        imageUrl: '',
        story:
            'Amedspor ruhunun sahadaki en büyük temsilcilerinden. Sahadaki hırsı ve attığı unutulmaz gollerle taraftarın gönlüne taht kurdu.',
        isUnlocked: true,
      ),
      LegendModel(
        id: '2',
        name: 'Şehmus Özer',
        role: 'Efsane Kaptan',
        rating: 95,
        imageUrl: '',
        story:
            'Kaptan, lider ve her zaman kalbimizde. Takımın bitmeyen azmi ve sahadaki ruhuydu. Ebediyen yaşayacak.',
        isUnlocked: false,
      ),
      LegendModel(
        id: '3',
        name: 'Mansur Çalar',
        role: 'Orta Saha Dinamosu',
        rating: 89,
        imageUrl: '',
        story:
            'Yıllarca formayı terleten, pes etmeyen destansı karakter. Orta alandaki sertliği ve bitmeyen enerjisiyle bir ikon.',
        isUnlocked: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('EFSANELER MÜZESİ', style: AppTextStyles.h3),
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

          return CustomScrollView(
            slivers: [
              // Token ve İtibar Puanı Özeti
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'MEVCUT TOKEN:',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${club.tokens} 🪙',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'KULÜP İTİBAR PUANI (REP):',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${club.reputation} ⭐',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'TARİHE GEÇEN DESTANLAR',
                    style: AppTextStyles.h3,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final legend = baseLegends[index];
                    final isUnlocked = _unlockedIds.contains(legend.id);
                    final isThisLoading =
                        _isProcessing && _unlockingLegendId == legend.id;

                    return _buildLegendCard(
                      context,
                      club,
                      legend,
                      isUnlocked,
                      isThisLoading,
                    );
                  }, childCount: baseLegends.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendCard(
    BuildContext context,
    ClubModel club,
    LegendModel legend,
    bool isUnlocked,
    bool isLoadingThis,
  ) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      backgroundColor: isUnlocked ? AppColors.surface : Colors.black45,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.6,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.gold.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.gold,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        legend.name,
                        style: AppTextStyles.h3.copyWith(color: AppColors.gold),
                      ),
                      Text(
                        legend.role,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        legend.story,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                        maxLines: isUnlocked ? 6 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  const Icon(Icons.lock_rounded, color: AppColors.muted),
              ],
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 16),
              AppButton(
                text: 'KİLİDİ AÇ (5 Token)',
                color: AppColors.gold,
                isLoading: isLoadingThis,
                onTap: () => _unlockLegend(context, club, legend),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

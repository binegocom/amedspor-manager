import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/youth_player_model.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/youth_repository.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class _KurdishNameGenerator {
  static const List<String> firstNames = [
    'Azad', 'Rojhat', 'Şiyar', 'Kawa', 'Zana', 'Heval', 'Berxwedan', 
    'Agit', 'Kendal', 'Cigerxwîn', 'Mazlum', 'Diyar', 'Mirhan', 'Arjîn', 
    'Bager', 'Botan', 'Çiyager', 'Demhat', 'Dicle', 'Fırat', 'Welat', 
    'Yılmaz', 'Zagros', 'Serhat', 'Xebat', 'Dilşad', 'Roni', 'Jiyan', 
    'Ronahî', 'Mem', 'Alan', 'Baran', 'Bedirhan', 'Ciwan', 'Devrim', 
    'Dilovan', 'Ferhat', 'Hogir', 'Kamuran', 'Merdan', 'Neçirvan', 
    'Rodi', 'Serdar', 'Şahin', 'Şerif', 'Tirêj', 'Şervan', 'Rizgar', 
    'Zerdeşt', 'Goran', 'Bawer', 'Rezan', 'Dijvar', 'Siyabend', 'Robîn', 
    'Zinar', 'Karker', 'Serkan', 'Kahraman', 'Xemgîn', 'Çetin', 'Brûsk', 
    'Zanyar', 'Pêşeng', 'Agir', 'Sîdar', 'Bîndar', 'Mîr', 'Renas', 'Yekta'
  ];

  static const List<String> regionalTitles = [
    'Amedî', 'Botan', 'Cizîrî', 'Kurdî', 'Zaza', 'Soran', 'Serhedî', 
    'Berwarî', 'Hekarî', 'Mukrî', 'Lorî', 'Xoybûn', 'Dêrsimî', 'Mêrdînî', 
    'Rihayî', 'Pirsûsî', 'Farqînî', 'Semsûrî', 'Gimgimî', 'Agirî', 
    'Silemanî', 'Efrînî', 'Kobanî', 'Qamişlî', 'Zaxoyî', 'Hewlêrî'
  ];

  static String generate() {
    final random = Random();
    final first = firstNames[random.nextInt(firstNames.length)];
    final title = regionalTitles[random.nextInt(regionalTitles.length)];
    if (random.nextDouble() < 0.7) {
      return '$first $title';
    } else {
      return first;
    }
  }

  static String generateUnique(List<YouthPlayerModel> existing) {
    final existingNames = existing.map((e) => e.name).toSet();
    for (int i = 0; i < 50; i++) {
      final candidate = generate();
      if (!existingNames.contains(candidate)) {
        return candidate;
      }
    }
    return '${generate()} ${Random().nextInt(89) + 10}';
  }
}

class _ScoutRegion {
  final String name;
  final String subtitle;
  final String iconStr;
  final String preferredPosition;
  final String flavorTemplate;

  const _ScoutRegion(this.name, this.subtitle, this.iconStr, this.preferredPosition, this.flavorTemplate);
}

const List<_ScoutRegion> _regions = [
  _ScoutRegion(
    'Amed / Sur', 
    'Teknik & Oyun Zekası Yüksek Yetenekler', 
    '🏰', 
    'MID',
    "Amed'in Hançepek mahallesinde dar sokaklarda top koştururken keşfedildi. Amedspor kimliğini yüreğinde taşıyor."
  ),
  _ScoutRegion(
    'Botan / Cizre', 
    'Dayanıklı & Mücadeleci Savaşçılar', 
    '⛰️', 
    'DEF',
    "Botan'ın sarp dağlarında edindiği bitmeyen ciğeri ve direnciyle tanınıyor. Pes etmeyen gerçek bir savaşçı."
  ),
  _ScoutRegion(
    'Serhed / Wan', 
    'Güçlü & Bitirici Hücum Silahları', 
    '❄️', 
    'FWD',
    "Serhed bölgesinin dondurucu soğuklarında çelik gibi bir iradeyle yoğruldu. Sahada soğukkanlı duruşuyla güven veriyor."
  ),
  _ScoutRegion(
    'Dêrsim / Munzur', 
    'Çevik & Refleksleri Kuvvetli Duvarlar', 
    '🌊', 
    'GK',
    "Dêrsim'in asi sularında büyüyen çevikliğiyle kalesinde ve savunmasında etten bir duvar örüyor."
  ),
];

class AcademyScreen extends ConsumerStatefulWidget {
  const AcademyScreen({super.key});

  @override
  ConsumerState<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends ConsumerState<AcademyScreen> {
  bool _isScouting = false;
  bool _isWatchingAd = false;
  bool _isUpgradingFacility = false;
  String? _scoutStatusMessage;
  String? _promotingPlayerId;
  String? _trainingPlayerId;
  int _selectedRegionIndex = 0;

  // 1. Reklam İzleme & Sponsor Modülü
  Future<void> _watchSponsorAd(BuildContext context, ClubModel club) async {
    if (_isWatchingAd) return;

    setState(() => _isWatchingAd = true);

    // Kısa bir reklam simülasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.blueAccent,
        content: Text('📺 Sponsor Reklamı oynatılıyor... "Jiyan Holding Amedspor\'a Başarılar Diler!"'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final clubRepo = ClubRepository();
      final reward = 300;
      await clubRepo.updateClub(club.copyWith(cash: club.cash + reward));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text('🎁 Reklam tamamlandı! Kulüp kasasına +$reward ₺ sponsor desteği eklendi.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primaryRed, content: Text('Sponsor hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _isWatchingAd = false);
    }
  }

  // 2. Akademi Tesis Seviyesini Geliştirme
  Future<void> _upgradeAcademyFacility(BuildContext context, ClubModel club) async {
    if (_isUpgradingFacility) return;

    final currentLevel = club.youthAcademyLevel;
    if (currentLevel >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akademi Tesisi zaten maksimum seviyede!')),
      );
      return;
    }

    final cost = currentLevel * 1000;
    if (club.cash < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Yetersiz Kasa! Tesis gelişimi için $cost ₺ gerekiyor.'),
        ),
      );
      return;
    }

    setState(() => _isUpgradingFacility = true);

    try {
      final clubRepo = ClubRepository();
      await clubRepo.updateClub(club.copyWith(
        cash: club.cash - cost,
        youthAcademyLevel: currentLevel + 1,
      ));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.gold,
          content: Text('🏰 Akademi Tesisi Seviye ${currentLevel + 1} oldu! Daha yetenekli oyuncular ve verimli idmanlar açıldı.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primaryRed, content: Text('Tesis gelişim hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpgradingFacility = false);
    }
  }

  // 3. Gözlemci Süreci
  Future<void> _handleScouting(BuildContext context, String clubId, ClubModel club, List<YouthPlayerModel> existingPlayers) async {
    if (_isScouting) return;

    const scoutCost = 500;
    if (club.cash < scoutCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Yetersiz Kasa! Gözlemci göndermek için 500 ₺ gerekiyor.'),
        ),
      );
      return;
    }

    setState(() {
      _isScouting = true;
      _scoutStatusMessage = "🔍 Gözlemci yola çıktı...";
    });

    try {
      final clubRepo = ClubRepository();
      await clubRepo.updateClub(club.copyWith(cash: club.cash - scoutCost));

      final region = _regions[_selectedRegionIndex];
      final int level = club.youthAcademyLevel;
      
      // Tesis seviyesi yüksekse gözlemci daha hızlı tarama yapar!
      final delayMs = 2000 - (level * 200);

      setState(() {
        _scoutStatusMessage = "🔍 ${region.name.split(' / ').first} mahalleleri ve toprak sahaları taranıyor...";
      });
      await Future.delayed(Duration(milliseconds: delayMs));

      if (!mounted) return;
      setState(() {
        _scoutStatusMessage = "⚽ Yerel yeteneklerle deneme maçları yapılıyor...";
      });
      await Future.delayed(Duration(milliseconds: delayMs));

      if (!mounted) return;
      setState(() {
        _scoutStatusMessage = "✍️ Amedspor değerlerine bağlı yetenek ikna ediliyor...";
      });
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      final youthRepo = YouthRepository();
      final fullName = _KurdishNameGenerator.generateUnique(existingPlayers);
      final isPreferred = Random().nextDouble() < 0.7;
      final positions = ['FWD', 'MID', 'DEF', 'GK'];
      final finalPos = isPreferred ? region.preferredPosition : positions[Random().nextInt(positions.length)];

      // Tesis seviyesi, yeteneğin potansiyelini ve başlangıç reytingini doğrudan yükseltir!
      final baseOvr = 40 + (level * 2);
      final newPlayer = YouthPlayerModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fullName,
        age: 15 + Random().nextInt(3),
        position: finalPos,
        potentialRating: 78 + (level * 2) + Random().nextInt(12),
        currentRating: baseOvr + Random().nextInt(12),
        scoutedAt: DateTime.now(),
        isReadyForPromotion: false,
        region: region.name.split(' / ').first,
        flavorText: region.flavorTemplate,
      );

      await youthRepo.addYouthPlayer(clubId, newPlayer);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text('✨ Gözlemci döndü! Yeni yetenek ${newPlayer.name} akademiye katıldı.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primaryRed, content: Text('Gözlemci hatası: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScouting = false;
          _scoutStatusMessage = null;
        });
      }
    }
  }

  // 4. Özel İdman Yaptır
  Future<void> _trainPlayer(BuildContext context, String clubId, ClubModel club, YouthPlayerModel player) async {
    if (_trainingPlayerId != null) return;

    const trainCost = 150;
    if (club.cash < trainCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Yetersiz Kasa! Özel idman için 150 ₺ gerekiyor.'),
        ),
      );
      return;
    }

    setState(() => _trainingPlayerId = player.id);

    try {
      final clubRepo = ClubRepository();
      await clubRepo.updateClub(club.copyWith(cash: club.cash - trainCost));

      // Tesis seviyesi yüksekse idman verimliliği artar!
      final levelBonus = club.youthAcademyLevel;
      final gain = 2 + levelBonus + Random().nextInt(4);
      final newRating = (player.currentRating + gain).clamp(0, player.potentialRating);
      
      final isReady = newRating >= (player.potentialRating - 5) || newRating >= 66;

      final updatedPlayer = player.copyWith(
        currentRating: newRating,
        isReadyForPromotion: isReady || player.isReadyForPromotion,
      );

      final youthRepo = YouthRepository();
      await youthRepo.updateYouthPlayer(clubId, updatedPlayer);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.gold,
          content: Text('⚡ İdman tamamlandı! ${player.name} +$gain OVR kazandı. (-150 ₺)'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primaryRed, content: Text('İdman hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _trainingPlayerId = null);
    }
  }

  // 5. A Takıma Yükselt
  Future<void> _promotePlayer(BuildContext context, String clubId, YouthPlayerModel youth) async {
    if (_promotingPlayerId != null) return;

    setState(() => _promotingPlayerId = youth.id);

    try {
      final playerRepo = PlayerRepository();
      final youthRepo = YouthRepository();

      final seniorPlayer = PlayerModel(
        id: youth.id,
        ownerId: clubId,
        name: youth.name,
        position: youth.position,
        number: 10 + Random().nextInt(89),
        rating: youth.currentRating,
        active: true,
        age: youth.age,
        shooting: youth.position == 'FWD' ? youth.currentRating + 10 : youth.currentRating,
        defending: youth.position == 'DEF' ? youth.currentRating + 10 : youth.currentRating,
        passing: youth.position == 'MID' ? youth.currentRating + 10 : youth.currentRating,
      );

      await playerRepo.createPlayer(seniorPlayer);
      await youthRepo.removeYouthPlayer(clubId, youth.id);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text('🚀 ${youth.name} profesyonel sözleşmeye imza atıp A Takıma yükseldi!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primaryRed, content: Text('Yükseltme başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _promotingPlayerId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final clubAsync = ref.watch(currentClubStreamProvider);
    final youthPlayersAsync = ref.watch(youthPlayersStreamProvider);

    final club = clubAsync.valueOrNull;
    final players = youthPlayersAsync.valueOrNull ?? [];

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          title: const Text("PROFESYONEL AKADEMİ MERKEZİ", style: AppTextStyles.h3),
        ),
        body: const Center(child: Text('Giriş yapılması gerekiyor', style: TextStyle(color: AppColors.muted))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text("PROFESYONEL AKADEMİ MERKEZİ", style: AppTextStyles.h3),
      ),
      body: clubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: AppColors.primaryRed))),
        data: (_) => CustomScrollView(
          slivers: [
            // Dinamik Sponsor Reklam Alanı (Her özellikte reklam projesi)
            if (club != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: PremiumCard(
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.ondemand_video_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  Text('SPONSOR REKLAMI', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text('• Jiyan Holding', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reklam izleyerek kulüp bütçesine anında destek olun.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: AppButton(
                            text: 'İZLE (+300₺)',
                            height: 36,
                            color: Colors.blueAccent,
                            isLoading: _isWatchingAd,
                            onTap: () => _watchSponsorAd(context, club),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Kasa Durumu ve Akademi Tesis Seviyesi Paneli
            if (club != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: PremiumCard(
                    backgroundColor: AppColors.card,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('KULÜP KASASI:', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('${club.cash} ₺', style: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 6),
                        // Tesis Seviyesi
                        Row(
                          children: [
                            const Icon(Icons.domain_rounded, color: AppColors.gold, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    children: [
                                      const Text('Akademi Tesis Seviyesi:', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(5, (i) => Icon(
                                          i < club.youthAcademyLevel ? Icons.star_rounded : Icons.star_border_rounded,
                                          color: AppColors.gold,
                                          size: 14,
                                        )),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Seviye ${club.youthAcademyLevel}/5 • İdman Bonusu: +${club.youthAcademyLevel} OVR',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (club.youthAcademyLevel < 5) ...[
                          const SizedBox(height: 10),
                          AppButton(
                            text: '🏰 TESİSİ GELİŞTİR (${club.youthAcademyLevel * 1000} ₺)',
                            height: 38,
                            type: AppButtonType.secondary,
                            isLoading: _isUpgradingFacility,
                            onTap: () => _upgradeAcademyFacility(context, club),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // Profesyonel Gözlemci Havuzu Kartı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: PremiumCard(
                  backgroundColor: AppColors.card,
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.public_rounded, color: AppColors.primaryGreen, size: 22),
                          SizedBox(width: 8),
                          Text('GÖZLEMCİ GÖREV BÖLGESİ', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bölge Seçimi
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _regions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final reg = _regions[idx];
                            final isSelected = _selectedRegionIndex == idx;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedRegionIndex = idx),
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.2) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? AppColors.primaryGreen : Colors.white10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${reg.iconStr} ${reg.name}',
                                      style: TextStyle(color: isSelected ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tercih: ${reg.preferredPosition}',
                                      style: TextStyle(color: isSelected ? Colors.white : AppColors.muted, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          _regions[_selectedRegionIndex].subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Dinamik Durum Mesajı
                      if (_scoutStatusMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _scoutStatusMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      AppButton(
                        text: _isScouting ? 'GÖZLEMCİ YOLDA...' : '🔍 GÖZLEMCİ GÖNDER (500 ₺)',
                        height: 46,
                        isLoading: _isScouting,
                        onTap: club == null ? null : () => _handleScouting(context, user.uid, club, players),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('GENÇ YETENEKLER HAVUZU', style: AppTextStyles.h3),
              ),
            ),

            if (players.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'Henüz altyapıda keşfedilmiş bir yetenek yok.\nYukarıdan otantik bir bölge seçip gözlemci gönderin!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final player = players[index];
                    final isPromotingThis = _promotingPlayerId == player.id;
                    final isTrainingThis = _trainingPlayerId == player.id;

                    return _ProfessionalYouthPlayerCard(
                      player: player,
                      club: club,
                      isPromoting: isPromotingThis,
                      isTraining: isTrainingThis,
                      onPromote: () => _promotePlayer(context, user.uid, player),
                      onTrain: club == null ? null : () => _trainPlayer(context, user.uid, club, player),
                    );
                  }, childCount: players.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalYouthPlayerCard extends StatelessWidget {
  final YouthPlayerModel player;
  final ClubModel? club;
  final bool isPromoting;
  final bool isTraining;
  final VoidCallback onPromote;
  final VoidCallback? onTrain;

  const _ProfessionalYouthPlayerCard({
    required this.player,
    required this.club,
    required this.isPromoting,
    required this.isTraining,
    required this.onPromote,
    required this.onTrain,
  });

  @override
  Widget build(BuildContext context) {
    Color posColor = AppColors.primaryGreen;
    switch (player.position) {
      case 'FWD': posColor = AppColors.primaryRed; break;
      case 'MID': posColor = Colors.blue; break;
      case 'DEF': posColor = AppColors.primaryGreen; break;
      default: posColor = AppColors.gold; break;
    }

    final double progress = (player.currentRating / player.potentialRating).clamp(0.0, 1.0);

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      backgroundColor: AppColors.surface,
      border: Border.all(color: player.isReadyForPromotion ? AppColors.gold : Colors.white12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Reyting Kutusu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: posColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${player.currentRating}',
                      style: TextStyle(color: player.isReadyForPromotion ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('OVR', style: TextStyle(color: AppColors.muted, fontSize: 8)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // İsim ve Detaylar (Esnek Wrap Mimarisi)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        if (player.region != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              player.region!,
                              style: const TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text('${player.position} • Yaş: ${player.age}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                            const SizedBox(width: 2),
                            Text('Potansiyel: ${player.potentialRating}', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Flavor Text
          if (player.flavorText != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: AppColors.muted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.flavorText!,
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    player.isReadyForPromotion ? '✨ A Takım İçin Tamamen Hazır!' : 'Gelişim Durumu',
                    style: TextStyle(color: player.isReadyForPromotion ? AppColors.gold : AppColors.muted, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.darkBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(player.isReadyForPromotion ? AppColors.gold : posColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          // Aksiyon Butonları
          Row(
            children: [
              if (!player.isReadyForPromotion) ...[
                Expanded(
                  child: AppButton(
                    text: '⚡ İDMAN (150 ₺)',
                    type: AppButtonType.secondary,
                    height: 42,
                    isLoading: isTraining,
                    onTap: onTrain,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppButton(
                  text: player.isReadyForPromotion ? '🚀 A TAKIMA AL' : 'ZORLA YÜKSELT',
                  color: player.isReadyForPromotion ? AppColors.gold : AppColors.primaryGreen,
                  textColor: player.isReadyForPromotion ? Colors.black : Colors.white,
                  height: 42,
                  isLoading: isPromoting,
                  onTap: onPromote,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

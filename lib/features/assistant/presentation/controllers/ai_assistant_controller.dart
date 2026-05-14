import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/club_model.dart';
import '../../../match_simulation/domain/services/match_sound_service.dart';
import 'ai_assistant_state.dart';

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantController, AiAssistantState>((ref) {
  return AiAssistantController();
});

class AiAssistantController extends StateNotifier<AiAssistantState> {
  AiAssistantController() : super(const AiAssistantState());

  Timer? _typingTimer;
  final _random = Random();

  void setCategory(String category) {
    if (state.isLoading) return;
    state = state.copyWith(
      selectedCategory: category,
      generatedResponse: '',
      displayedText: '',
      isTypingCompleted: false,
      error: null,
    );
  }

  Future<void> generateAdvice(ClubModel? club) async {
    if (state.isLoading) return;

    _typingTimer?.cancel();
    state = state.copyWith(
      isLoading: true,
      generatedResponse: '',
      displayedText: '',
      isTypingCompleted: false,
      error: null,
    );

    // İsteğin işlenmeye başlaması anında ince bir düdük SFX uyarısı
    try {
      MatchSoundService().playWhistle();
    } catch (_) {}

    // LLM / Genkit Gecikmesi Simülasyonu
    await Future.delayed(const Duration(milliseconds: 1200));

    final fullResponse = _buildContextAwareResponse(club, state.selectedCategory);

    state = state.copyWith(
      isLoading: false,
      generatedResponse: fullResponse,
    );

    _startTypingEffect(fullResponse);
  }

  String _buildContextAwareResponse(ClubModel? club, String category) {
    final clubName = club?.name ?? 'Amedspor';
    final fans = club?.fans ?? 500;
    final cash = club?.cash ?? 10000;
    final stadiumLvl = club?.stadiumLevel ?? 1;
    final academyLvl = club?.youthAcademyLevel ?? 1;

    switch (category) {
      case 'Taktik':
        final pool = [
          '⚡ $clubName için Kritik Taktik Raporu:\nTakımımızın itibar seviyesi ve taraftar coşkusu ($fans taraftar) hücum presine çok uygun. Rakiplerin kanat zaaflarını değerlendirmek için 4-3-3 diziliminde bekleri ileri çıkartmalıyız. Agresif pres maçın ilk 30 dakikasında skor getirecektir.',
          '🛡️ Savunma ve Geçiş Oyunu Analizi:\nStadyum seviyemiz (Seviye $stadiumLvl) ev sahibi avantajımızı maksimize ediyor. Derbi maçlarında orta sahayı kalabalık tutup kontra ataklarla rakip savunmanın dengesini bozmalıyız. İkinci bölgede kazanılan toplar kilit rol oynayacak.',
          '🔥 Amedspor Oyun Felsefesi Tavsiyesi:\nKısa paslarla oyunu kurmak ve topa sahip olma oranını %60 üzerine çekmek ana hedefimiz olmalı. Özellikle iç saha maçlarında taraftar baskısıyla rakibi bunaltacak bir ön alan imece presi kurgulamalıyız.',
        ];
        return pool[_random.nextInt(pool.length)];

      case 'Basın Açıklaması':
        final pool = [
          '📰 Yerel ve Ulusal Basın Bildirisi:\n"Biz sadece bir futbol kulübü değil, milyonların umudu ve tutkusuyuz. Bugün sahaya çıkacak her oyuncumuz armanın ağırlığını ve arkasındaki $fans taraftarın inancını yüreğinde hissediyor. Sahadan zaferle ayrılacağız!"',
          '🎙️ Maç Öncesi Menajer Demeci:\n"Takımımızın hazırlıkları harika gidiyor. Mevcut bütçemiz ve tesis yatırımlarımızla geleceğin Amedspor\'unu inşa ediyoruz. Taraftarımız rahat olsun, sahada basmadık yer bırakmayan, mücadeleci bir takım izleteceğiz."',
          '🔥 Derbi Ateşi Basın Toplantısı:\n"Rakiplerimizin kim olduğuyla ilgilenmiyoruz. Biz kendi oyunumuza odaklandık. Amedspor sahaya her zaman kazanmak için çıkar. Taraftarımızın desteğiyle bu engeli de aşacağız."',
        ];
        return pool[_random.nextInt(pool.length)];

      case 'Finans':
        final advice = cash < 25000
            ? '⚠️ Finansal Uyarı: Kasamızdaki nakit ($cash ₺) kritik seviyelerde. Acil sponsorluk anlaşmaları imzalamalı veya yüksek maliyetli transferlerden kaçınmalıyız. Öncelik rezervleri güçlendirmek olmalı.'
            : '📈 Yatırım Tavsiyesi: Bütçemiz oldukça güçlü ($cash ₺). Bu kaynağı doğrudan Stadyum kapasitesine veya Altyapı Akademisine aktararak kalıcı gelir kalemleri oluşturabiliriz.';
        return '💰 Kulüp Finansal Zeka Analizi:\n$advice\nSponsorluk modülünü ziyaret ederek aktif teklifleri incelemeniz kulübün geleceği için hayati önem taşıyor.';

      case 'Akademi':
        return '🌱 Gençlik Akademisi Stratejisi:\nMevcut akademi seviyemiz (Seviye $academyLvl), genç yeteneklerin potansiyelini doğrudan etkiliyor. Gözlemcilerimizi bölgedeki amatör kümelere yönlendirerek reytingi yüksek cevherler bulabiliriz. Unutmayın, geleceğin efsaneleri bu topraklardan çıkacak!';

      default:
        return 'Analiz tamamlandı. Kulübünüz için en uygun strateji devreye alındı.';
    }
  }

  void _startTypingEffect(String text) {
    final words = text.split(' ');
    int currentIndex = 0;
    String currentDisplay = '';

    _typingTimer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
      if (currentIndex < words.length) {
        currentDisplay += (currentIndex == 0 ? '' : ' ') + words[currentIndex];
        state = state.copyWith(displayedText: currentDisplay);
        currentIndex++;
      } else {
        timer.cancel();
        state = state.copyWith(isTypingCompleted: true);
        // Yazma bitince heyecanlı bir gol/sevinç SFX geri bildirimi
        try {
          MatchSoundService().playGoal();
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
}

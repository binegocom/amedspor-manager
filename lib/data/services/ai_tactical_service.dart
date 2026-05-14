import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './firebase/firebase_providers.dart';
import '../repositories/user_repository.dart';

class AiTacticalService {
  static const int tokenCostXp = 250;
  final _userRepo = UserRepository();

  /// Kullanıcının o güne ait kalan analiz hakkını getirir.
  Future<int> getRemainingTokens() async {
    final user = authService.currentUser;
    if (user == null) return 0;

    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final dateKey = 'ai_token_date_${user.uid}';
    final countKey = 'ai_token_count_${user.uid}';

    final storedDate = prefs.getString(dateKey);
    if (storedDate != todayStr) {
      // Yeni gün, hakkı 1 yap ve kaydet
      await prefs.setString(dateKey, todayStr);
      await prefs.setInt(countKey, 1);
      return 1;
    }

    return prefs.getInt(countKey) ?? 0;
  }

  /// Token harcar (Eğer varsa). Başarılıysa true döner.
  Future<bool> consumeToken() async {
    final user = authService.currentUser;
    if (user == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final countKey = 'ai_token_count_${user.uid}';
    final current = prefs.getInt(countKey) ?? 0;

    if (current > 0) {
      await prefs.setInt(countKey, current - 1);
      return true;
    }
    return false;
  }

  /// XP harcayarak yeni 1 AI Danışmanlık Jetonu satın alır.
  Future<bool> buyTokenWithXp() async {
    final user = authService.currentUser;
    if (user == null) return false;

    try {
      final appUser = await _userRepo.getUser(user.uid);
      if (appUser == null || appUser.xp < tokenCostXp) {
        return false; // Yetersiz XP
      }

      // Firestore'dan XP düş
      await firestoreService.users.doc(user.uid).update({
        'xp': FieldValue.increment(-tokenCostXp),
      });

      // Yerel token sayısını artır
      final prefs = await SharedPreferences.getInstance();
      final countKey = 'ai_token_count_${user.uid}';
      final current = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, current + 1);

      return true;
    } catch (e) {
      debugPrint('Token satın alma hatası: $e');
      return false;
    }
  }

  /// Diziliş ve ortalama güce göre Yapay Zeka Taktiksel Sentez Raporu üretir.
  Future<String> synthesizeAdvice(String formation, int teamPower, String? captain) async {
    // Gelecekte doğrudan Gemini API/Genkit eklenecek altyapı. 
    // Sıfır maliyet ve anında akıllı yanıt için uzman kurallar motoru:
    await Future.delayed(const Duration(milliseconds: 1200)); // AI düşünme efekti

    final buffer = StringBuffer();
    buffer.writeln('🤖 **Amedspor AI Taktiksel Sentez Raporu**\n');

    // Güç analizi
    if (teamPower < 50) {
      buffer.writeln('⚠️ **Genel Kadro Derinliği:** Mevcut kadro kalitesi zorlu lig maçları için yetersiz görünüyor. Antrenman modülüyle form durumlarını yükseltmeli veya rotasyon yapmalısınız.');
    } else if (teamPower < 75) {
      buffer.writeln('⚡ **Kadro Potansiyeli:** Dengeli ve mücadeleci bir 11 kurdunuz. Takım kimyası sahada belirleyici olacaktır.');
    } else {
      buffer.writeln('🌟 **Elit Kadro:** Şampiyonluk hamuru olan, üst düzey bir ilk 11. Rakibe sahayı dar edecek güce sahipsiniz.');
    }

    buffer.writeln('\n📋 **Diziliş İpuçları ($formation):**');
    switch (formation) {
      case '4-3-3':
        buffer.writeln('• *Hücum:* Kanat forvetlerin merkeze katılarak santrfora alan açmalı.\n• *Defans:* Orta sahadaki tek ön liberonun savunma arasına girerek stoperleri yedeklemesi kritik.');
        break;
      case '3-5-2':
        buffer.writeln('• *Kanatlar:* Çift yönlü oynayan kanat beklerinizin kondisyonu maçın kaderini belirleyecek. Yorulduklarında erken değişiklik şart.\n• *Merkez:* Orta sahada sayısal üstünlüğünüz var, topa sahip olma oyununu tercih edin.');
        break;
      case '4-2-3-1':
        buffer.writeln('• *Denge:* Çift ön libero savunmayı sağlama alırken, 10 numara pozisyonundaki oyuncunun kilit pasları kilidi açacaktır.');
        break;
      case '4-4-2':
        buffer.writeln('• *Klasik Düzen:* Forvet ikilisinin birbirini tamamlaması (biri hedef adam, diğeri gezici) pozisyon zenginliği yaratır.');
        break;
      default:
        buffer.writeln('• Mevcut dizilişte bloklar arası mesafeyi dar tutarak takım savunmasından taviz vermemeye özen gösterin.');
    }

    if (captain != null && captain.isNotEmpty) {
      buffer.writeln('\n👑 **Kaptanlık Etkisi:** $captain pazubandın getirdiği sorumlulukla sahadaki mental direnci artırıyor.');
    } else {
      buffer.writeln('\n⚠️ **Kaptan Eksikliği:** Sahada liderlik yapacak bir Kaptan belirlemediniz. Bu durum kritik anlarda moral kırılmalarına yol açabilir.');
    }

    buffer.writeln('\n💡 *Tavsiye:* Maçın ilk 30 dakikasında rakip analizi yaparak gerekirse talimatları anında güncelleyin.');

    return buffer.toString();
  }
}

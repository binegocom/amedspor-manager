class BadWordsFilter {
  // Genişletilmiş ve Güçlendirilmiş Türkçe & İngilizce Küfür/Hakaret Sözlüğü
  static const List<String> _badWords = [
    // Türkçe Yoğun Küfür ve Hakaretler
    'aptal', 'salak', 'gerizekalı', 'şerefsiz', 'amk', 'aq', 'siktir', 'pezevenk',
    'orospu', 'piç', 'yavşak', 'amcık', 'göt', 'ibne', 'kahpe', 'puşt', 'gavat',
    'dallama', 'dangalak', 'hıyar', 'öküz', 'it', 'köpek', 'veled', 'veledizina',
    'sürtük', 'yarrak', 'yarak', 'sik', 'sikerim', 'siktiğim', 'sokuk', 'lavuk',
    'kancık', 'kaltak', 'zibidi', 'zina', 'mal', 'cibilliyetsiz', 'haysiyetsiz',
    // İngilizce Küfürler
    'stupid', 'idiot', 'fool', 'dumb', 'moron', 'retard', 'fuck', 'shit',
    'bitch', 'asshole', 'bastard', 'dick', 'pussy', 'cock', 'fucker',
    'fucking', 'motherfucker', 'cunt', 'slut', 'whore', 'wanker', 'prick',
    // Yaygın Sosyal Medya Kısaltmaları ve Leet Varyasyonları
    'amq', 'mk', 'sg', 'sktr', 'oc', 'oç', 'pic', 'yavsak', 'serefsiz', 'ibn',
    'g0t', 's1k', 'p1c', '0r0spu', 'amkoc', 'amcik',
  ];

  // Hızlı arama için Set yapısına dönüştürülmüş sözlük
  static final Set<String> _badWordSet = Set<String>.from(
    _badWords.map((word) => word.toLowerCase().trim()),
  );

  /// Metni Leet-speak karakterlerinden arındırır, boşluk ve sembolleri siler,
  /// tekrarlayan harfleri teke indirerek gizlenmiş küfürleri açığa çıkarır.
  /// Örn: "s.i.k.t.i.r" -> "siktir", "sssaaaalllaaakkk" -> "salak", "a_m_k" -> "amk"
  static String normalizeText(String text) {
    if (text.isEmpty) return '';

    // 1. Küçük harfe çevir
    String s = text.toLowerCase();

    // 2. Leet-speak harf/rakam dönüşümleri
    final leetMap = {
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '0': 'o',
      '5': 's',
      '@': 'a',
      '\$': 's',
    };
    leetMap.forEach((key, val) {
      s = s.replaceAll(key, val);
    });

    // 3. Boşlukları, sembolleri ve noktalama işaretlerini tamamen sil
    // Sadece Türkçe ve İngilizce harfler kalsın
    s = s.replaceAll(RegExp(r'[^a-zçğıöşü]'), '');

    // 4. Arka arkaya tekrarlayan harfleri teke düşür (Deduplication)
    if (s.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.write(s[0]);
    for (int i = 1; i < s.length; i++) {
      if (s[i] != s[i - 1]) {
        buffer.write(s[i]);
      }
    }

    return buffer.toString();
  }

  /// Metnin doğrudan veya gizlenmiş bir küfür/hakaret içerip içermediğini denetler.
  static bool containsBadWords(String text) {
    if (text.isEmpty) return false;

    // 1. Orijinal metnin doğrudan küçük harfli kontrolü (Cümle içi tam eşleşmeler için)
    final lowerText = text.toLowerCase();
    for (final word in _badWordSet) {
      if (lowerText.contains(word)) {
        return true;
      }
    }

    // 2. Gelişmiş Atlatma Motoru (Sanitized & Normalized) Taraması
    // Boşluklar, noktalar ve tekrar eden harfler silinmiş sıkıştırılmış hal üzerinde arama
    final normalized = normalizeText(text);
    for (final word in _badWordSet) {
      // Küfür kökünün normalize edilmiş metnin içinde geçip geçmediğine bakıyoruz
      if (normalized.contains(word)) {
        return true;
      }
    }

    return false;
  }

  /// Küfürlü kelimeleri yıldızlar (*) ile maskeler.
  static String sanitize(String text) {
    if (text.isEmpty) return text;

    String result = text;
    for (final word in _badWordSet) {
      final regex = RegExp(word, caseSensitive: false);
      result = result.replaceAll(regex, '*' * word.length);
    }
    return result;
  }
}

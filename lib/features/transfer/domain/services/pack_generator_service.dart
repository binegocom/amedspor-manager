import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../../data/models/player_model.dart';

enum PackType { standard, silver, gold }

class PackGeneratorService {
  final Random _rng = Random();
  final Uuid _uuid = const Uuid();

  static const List<String> _firstNames = [
    'Ali', 'Ahmet', 'Mehmet', 'Can', 'Deniz', 'Emre', 'Berke', 'Arda',
    'Ozan', 'Burak', 'Hakan', 'Cem', 'Volkan', 'Efe', 'Tolga', 'Okan'
  ];

  static const List<String> _lastNames = [
    'Yılmaz', 'Kaya', 'Demir', 'Çelik', 'Şahin', 'Yıldız', 'Öztürk', 'Aydın',
    'Özdemir', 'Arslan', 'Doğan', 'Kılıç', 'Aslan', 'Çetin', 'Kara'
  ];

  static const List<String> _positions = ['GK', 'DEF', 'MID', 'FWD'];

  PlayerModel openPack({required PackType type, required String ownerId}) {
    int minRating;
    int maxRating;
    int stars;

    switch (type) {
      case PackType.standard:
        minRating = 50;
        maxRating = 70;
        stars = 1;
        break;
      case PackType.silver:
        minRating = 65;
        maxRating = 80;
        stars = _rng.nextBool() ? 2 : 3;
        break;
      case PackType.gold:
        minRating = 78;
        maxRating = 95;
        stars = _rng.nextDouble() > 0.7 ? 5 : 4;
        break;
    }

    final rating = minRating + _rng.nextInt(maxRating - minRating + 1);
    final position = _positions[_rng.nextInt(_positions.length)];
    
    final firstName = _firstNames[_rng.nextInt(_firstNames.length)];
    final lastName = _lastNames[_rng.nextInt(_lastNames.length)];
    final name = '$firstName $lastName';
    
    final number = 1 + _rng.nextInt(99);

    // İstatistikleri rating etrafında rastgele dağıt
    int randomStat() => (rating - 5 + _rng.nextInt(11)).clamp(30, 99);

    final shooting = position == 'FWD' ? randomStat() + 10 : randomStat();
    final passing = position == 'MID' ? randomStat() + 10 : randomStat();
    final defending = (position == 'DEF' || position == 'GK') ? randomStat() + 10 : randomStat();
    final dribbling = randomStat();
    final positioning = randomStat();
    final composure = randomStat();

    return PlayerModel(
      id: _uuid.v4(),
      ownerId: ownerId,
      name: name,
      position: position,
      number: number,
      rating: rating,
      active: true,
      stars: stars,
      age: 18 + _rng.nextInt(15), // 18-32 yaş
      shooting: shooting.clamp(30, 99),
      passing: passing.clamp(30, 99),
      defending: defending.clamp(30, 99),
      dribbling: dribbling.clamp(30, 99),
      positioning: positioning.clamp(30, 99),
      composure: composure.clamp(30, 99),
      marketValue: rating * 1500, // Basit değer hesabı
    );
  }
}

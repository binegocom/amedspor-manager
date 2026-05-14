/// Maç olay türleri.
enum MatchEventType {
  kickoff,     // Santra
  goal,        // Gol
  shot,        // Şut
  save,        // Kurtarış
  tackle,      // Müdahale
  foul,        // Faul
  yellowCard,  // Sarı kart
  redCard,     // Kırmızı kart
  corner,      // Korner
  throwIn,     // Taç
  freeKick,    // Serbest vuruş
  penalty,     // Penaltı
  offside,     // Ofsayt
  goalKick,    // Kale vuruşu
  injury,      // Sakatlık
  substitution,// Oyuncu değişikliği
  boost,       // Menajer desteği (Meşale vb.)
  fulltime,    // Maç sonu
}

/// Maç sırasında gerçekleşen bir olayı temsil eder.
class MatchEvent {
  final int minute;
  final MatchEventType type;
  final String description;
  final int teamId;
  final int? playerId;

  MatchEvent({
    required this.minute,
    required this.type,
    required this.description,
    required this.teamId,
    this.playerId,
  });
}

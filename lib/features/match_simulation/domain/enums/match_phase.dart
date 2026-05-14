/// Maç fazları — motorun o anki durumunu belirler.
enum MatchPhase {
  kickoff, // Santra / başlangıç
  attacking, // Hücum
  defending, // Savunma
  transition, // Geçiş (top el değiştirdi)
  looseBall, // Top boşta
  shot, // Şut anı
  goal, // Gol anı (kısa duraklama)
  corner, // Korner
  throwIn, // Taç atışı
  freeKick, // Serbest vuruş
  penalty, // Penaltı
  offside, // Ofsayt
  foul, // Faul
  halftime, // Devre arası
  extraTime, // Uzatma devresi
  penaltyShootout, // Penaltı atışları
  finished, // Maç bitti
}

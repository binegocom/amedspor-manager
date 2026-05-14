/// Antrenman türleri
enum TrainingDrill {
  shooting('Şut', 'shooting'),
  passing('Pas', 'passing'),
  defending('Savunma', 'defending'),
  dribbling('Top Sürüşü', 'dribbling'),
  positioning('Pozisyon', 'positioning'),
  composure('Sakinlik', 'composure');

  const TrainingDrill(this.displayName, this.skillName);

  final String displayName;
  final String skillName;
}
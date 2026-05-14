enum TacticalPreset {
  defensive,
  balanced,
  attacking,
}

extension TacticalPresetLabel on TacticalPreset {
  String get label {
    switch (this) {
      case TacticalPreset.defensive:
        return 'Defansif';
      case TacticalPreset.balanced:
        return 'Dengeli';
      case TacticalPreset.attacking:
        return 'Ofansif';
    }
  }
}

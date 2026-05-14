import 'package:audioplayers/audioplayers.dart';

/// Maç simülasyonu için ses efektleri servisi.
class MatchSoundService {
  static final MatchSoundService _instance = MatchSoundService._internal();
  factory MatchSoundService() => _instance;
  MatchSoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Gol sesi çal.
  Future<void> playGoal() async {
    await _player.play(AssetSource('sounds/goal.mp3'));
  }

  /// Düdük sesi çal (kart veya faul için).
  Future<void> playWhistle() async {
    await _player.play(AssetSource('sounds/whistle.mp3'));
  }

  /// Maç bitiş düdüğü çal.
  Future<void> playFinalWhistle() async {
    await _player.play(AssetSource('sounds/final_whistle.mp3'));
  }

  void dispose() {
    _player.dispose();
  }
}

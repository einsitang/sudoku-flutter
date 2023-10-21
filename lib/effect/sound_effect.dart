import 'package:just_audio/just_audio.dart';

/// this class define sound effect
class SoundEffect {
  static bool _init = false;

  static final AudioPlayer _wrongAudio = new AudioPlayer();
  static final AudioPlayer _victoryAudio = new AudioPlayer();
  static final AudioPlayer _gameOverAudio = new AudioPlayer();
  // show user tips sound effect
  static final AudioPlayer _answerTipAudio = new AudioPlayer();

  static init() async {
    if (!_init) {
      await _wrongAudio.setAsset("assets/audio/wrong_tip.mp3");
      await _victoryAudio.setAsset("assets/audio/victory_tip.mp3");
      await _gameOverAudio.setAsset("assets/audio/gameover_tip.mp3");
      await _answerTipAudio.setAsset("assets/audio/answer_tip.mp3");
    }
    _init = true;
  }

  static stuffError() async {
    if (!_init) {
      await init();
    }
    await _wrongAudio.seek(Duration.zero);
    await _wrongAudio.play();
    return;
  }

  static solveVictory() async {
    if (!_init) {
      await init();
    }
    await _victoryAudio.seek(Duration.zero);
    await _victoryAudio.play();
  }

  static gameOver() async {
    if (!_init) {
      await init();
    }
    await _gameOverAudio.seek(Duration.zero);
    await _gameOverAudio.play();
  }

  static answerTips() async {
    if (!_init) {
      await init();
    }
    await _answerTipAudio.seek(Duration.zero);
    await _answerTipAudio.play();
  }
}

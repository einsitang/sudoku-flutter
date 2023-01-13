import 'package:just_audio/just_audio.dart';

/// this class define input sound
class InputSoundEffect {
  static bool _init = false;

  static AudioPlayer _wrongAudio = new AudioPlayer();

  static init() async {
    if (!_init) {
      await _wrongAudio.setAsset("assets/audio/wrong_tip.mp3");
    }
    _init = true;
  }

  static tipWrongSound() async {
    if(!_init){
      await init();
    }
    await _wrongAudio.seek(Duration.zero);
    await _wrongAudio.play();
    return;
  }
}

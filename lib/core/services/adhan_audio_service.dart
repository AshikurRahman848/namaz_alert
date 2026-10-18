import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AdhanAudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  static Future<void> playAdhan() async {
    try {
      await _player.stop();
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/adhan.mp3'));
      isPlayingNotifier.value = true;

      _player.onPlayerComplete.listen((_) {
        isPlayingNotifier.value = false;
      });
    } catch (e) {
      debugPrint('AdhanAudioService play error: $e');
    }
  }

  static Future<void> stopAdhan() async {
    try {
      await _player.stop();
      isPlayingNotifier.value = false;
    } catch (e) {
      debugPrint('AdhanAudioService stop error: $e');
    }
  }

  static Future<void> togglePlay() async {
    if (isPlayingNotifier.value) {
      await stopAdhan();
    } else {
      await playAdhan();
    }
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';

class AdhanAudioService {
  static final AudioPlayer _player = AudioPlayer();
  static const MethodChannel _audioChannel = MethodChannel('namaz_alert/audio');
  static final ValueNotifier<bool> isPlayingNotifier =
      ValueNotifier<bool>(false);

  static Future<void> setVolume({required int volumePercent}) async {
    final percent = volumePercent.clamp(0, 100);
    await GetStorage().write(AppConstants.keyAdhanVolume, percent);
    await _player.setVolume(percent / 100);
    try {
      await _audioChannel.invokeMethod<void>(
        'setAdhanVolume',
        {'percent': percent},
      );
    } catch (e) {
      debugPrint('Android Adhan volume error: $e');
    }
  }

  static Future<void> playAdhan({int? volumePercent}) async {
    try {
      final storedVolume =
          GetStorage().read(AppConstants.keyAdhanVolume) as int?;
      final percent = (volumePercent ?? storedVolume ?? 100).clamp(0, 100);

      await _player.stop();
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
      await _player.setVolume(percent / 100);
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

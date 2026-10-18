import 'dart:async';
import 'dart:html' as html;

class PlatformAudioPlayer {
  static html.AudioElement? _activeAudio;
  static int _currentPlayToken = 0;
  static StreamSubscription? _endedSubscription;

  static void stop() {
    _currentPlayToken++;
    try {
      _endedSubscription?.cancel();
      _endedSubscription = null;
      if (_activeAudio != null) {
        _activeAudio!.pause();
        _activeAudio = null;
      }
    } catch (_) {}
  }

  static Future<bool> playAudio(
    String url, {
    String? text,
    double? speechRate,
    double? volume,
    double? pitch,
    void Function()? onFinished,
  }) async {
    try {
      stop();
      final playToken = ++_currentPlayToken;

      String targetUrl = url;
      try {
        final loc = html.window.location;
        if (loc.hostname != null &&
            loc.hostname!.isNotEmpty &&
            loc.hostname != 'localhost' &&
            loc.hostname != '127.0.0.1') {
          targetUrl = url.replaceAll('localhost', loc.hostname!);
        }
      } catch (_) {}

      final baseRate = (speechRate != null && speechRate > 0) ? speechRate.clamp(0.5, 2.0) : 0.9;
      final effectiveVol = (volume != null) ? volume.clamp(0.0, 1.0) : 1.0;

      // Tạo Audio element mới cho mỗi lần phát để tránh lỗi "interrupted by load" của Chrome
      final audio = html.AudioElement(targetUrl);
      _activeAudio = audio;
      audio.playbackRate = baseRate;
      audio.volume = effectiveVol;

      _endedSubscription = audio.onEnded.listen((_) {
        if (playToken == _currentPlayToken) {
          onFinished?.call();
        }
      });

      audio.onError.listen((_) {
        // Nếu URL bị lỗi thì kết thúc lượt phát
        if (playToken == _currentPlayToken) {
          onFinished?.call();
        }
      });

      await audio.play();
      return true;
    } catch (_) {
      return false;
    }
  }
}

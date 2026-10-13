import 'dart:async';
import 'dart:html' as html;

class PlatformAudioPlayer {
  static html.AudioElement? _singletonAudio;
  static int _currentPlayToken = 0;
  static StreamSubscription? _endedSubscription;
  static StreamSubscription? _canPlaySubscription;
  static StreamSubscription? _playSubscription;

  static void stop() {
    _currentPlayToken++;
    try {
      _endedSubscription?.cancel();
      _endedSubscription = null;
      _canPlaySubscription?.cancel();
      _canPlaySubscription = null;
      _playSubscription?.cancel();
      _playSubscription = null;

      if (_singletonAudio != null) {
        _singletonAudio!.pause();
        _singletonAudio!.removeAttribute('src');
        _singletonAudio!.load();
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
      // 1. Dừng ngay lập tức âm thanh trước đó và tăng token để huỷ callback cũ
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

      _singletonAudio ??= html.AudioElement();

      final audio = _singletonAudio!;
      audio.autoplay = false;

      // 1. Tính toán Tốc độ đọc (speechRate 0.5x -> 2.0x, mặc định 0.9x)
      final baseRate = (speechRate != null && speechRate > 0) ? speechRate.clamp(0.5, 2.0) : 0.9;

      // 2. Tính toán Cao độ (pitch 0.5 -> 1.5, mặc định 1.0)
      // Khi pitch khác 1.0 (Trầm ấm 0.85 hoặc Trong trẻo 1.15), ta kết hợp preservesPitch = false
      // để thay đổi tần số dao động âm sắc tự nhiên của giọng Chị Google
      final p = pitch ?? 1.0;
      double effectiveRate = baseRate;

      if ((p - 1.0).abs() > 0.03) {
        effectiveRate = (baseRate * p).clamp(0.5, 2.0);
        try {
          (audio as dynamic).preservesPitch = false;
          (audio as dynamic).mozPreservesPitch = false;
          (audio as dynamic).webkitPreservesPitch = false;
        } catch (_) {}
      } else {
        try {
          (audio as dynamic).preservesPitch = true;
          (audio as dynamic).mozPreservesPitch = true;
          (audio as dynamic).webkitPreservesPitch = true;
        } catch (_) {}
      }

      // 3. Tính toán Âm lượng (volume 0.0 -> 1.0)
      final effectiveVol = (volume != null) ? volume.clamp(0.0, 1.0) : 1.0;

      // Cài đặt defaultPlaybackRate và volume trước khi gán URL
      audio.defaultPlaybackRate = effectiveRate;
      audio.playbackRate = effectiveRate;
      audio.volume = effectiveVol;

      void applyAcoustics() {
        try {
          audio.playbackRate = effectiveRate;
          audio.volume = effectiveVol;
          if ((p - 1.0).abs() > 0.03) {
            (audio as dynamic).preservesPitch = false;
            (audio as dynamic).mozPreservesPitch = false;
            (audio as dynamic).webkitPreservesPitch = false;
          } else {
            (audio as dynamic).preservesPitch = true;
            (audio as dynamic).mozPreservesPitch = true;
            (audio as dynamic).webkitPreservesPitch = true;
          }
        } catch (_) {}
      }

      // Đăng ký sự kiện khi âm thanh kết thúc
      _endedSubscription = audio.onEnded.listen((_) {
        if (playToken == _currentPlayToken) {
          onFinished?.call();
        }
      });

      // Chrome thường reset playbackRate về 1.0 khi load xong metadata, ta đảm bảo re-apply
      _canPlaySubscription = audio.onCanPlay.listen((_) {
        if (playToken == _currentPlayToken) {
          applyAcoustics();
        }
      });

      _playSubscription = audio.onPlay.listen((_) {
        if (playToken == _currentPlayToken) {
          applyAcoustics();
        }
      });

      // 2. Thử phát từ backend proxy
      try {
        audio.src = targetUrl;
        audio.load();
        applyAcoustics();
        await audio.play();
        applyAcoustics();
        return true;
      } catch (_) {
        if (playToken != _currentPlayToken) return false;
      }

      // 3. Dự phòng: Phát trực tiếp Google Translate TTS
      if (text != null && text.isNotEmpty) {
        try {
          final directGoogleUrl =
              'https://translate.google.com/translate_tts?ie=UTF-8&tl=vi&client=tw-ob&q=${Uri.encodeComponent(text)}';
          audio.src = directGoogleUrl;
          audio.load();
          applyAcoustics();
          await audio.play();
          applyAcoustics();
          return true;
        } catch (_) {
          return false;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}

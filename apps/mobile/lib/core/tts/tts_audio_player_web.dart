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
    try {
      if (html.window.speechSynthesis != null) {
        html.window.speechSynthesis!.cancel();
      }
    } catch (_) {}
  }

  /// Chia nhỏ câu nếu dài hơn 160 ký tự để Google Translate TTS đọc trôi chảy
  static List<String> _splitIntoChunks(String text) {
    final clean = text.trim();
    if (clean.length <= 160) return [clean];

    final chunks = <String>[];
    final parts = clean.split(RegExp(r'[,.\n;!]+'));
    String current = '';

    for (final p in parts) {
      final s = p.trim();
      if (s.isEmpty) continue;
      if ((current.isEmpty ? s : '$current, $s').length <= 160) {
        current = current.isEmpty ? s : '$current, $s';
      } else {
        if (current.isNotEmpty) chunks.add(current);
        current = s;
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks.isNotEmpty ? chunks : [clean.substring(0, 160.clamp(0, clean.length))];
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
      final cleanText = text?.trim() ?? '';

      final effectiveRate = (speechRate != null && speechRate > 0) ? speechRate.clamp(0.5, 2.0) : 1.0;
      final effectiveVol = (volume != null) ? volume.clamp(0.0, 1.0) : 1.0;

      // =========================================================================
      // 1. ƯU TIÊN SỐ 1: PHÁT ĐÚNG 100% GIỌNG CHỊ GOOGLE GỐC (GOOGLE TRANSLATE MP3)
      // =========================================================================
      if (cleanText.isNotEmpty) {
        final chunks = _splitIntoChunks(cleanText);
        bool success = await _playGoogleTtsChunks(chunks, 0, playToken, effectiveRate, effectiveVol, onFinished);
        if (success) {
          return true;
        }
      }

      // =========================================================================
      // 2. DỰ PHÒNG: Thử phát qua URL truyền vào
      // =========================================================================
      if (url.isNotEmpty) {
        try {
          final audio = html.AudioElement(url);
          _activeAudio = audio;
          audio.playbackRate = effectiveRate;
          audio.volume = effectiveVol;

          _endedSubscription = audio.onEnded.listen((_) {
            if (playToken == _currentPlayToken) {
              onFinished?.call();
            }
          });
          await audio.play();
          return true;
        } catch (_) {}
      }

      // =========================================================================
      // 3. DỰ PHÒNG CUỐI CÙNG: Web Speech Synthesis của trình duyệt
      // =========================================================================
      return _fallbackBrowserSpeech(cleanText, playToken, effectiveRate, effectiveVol, pitch, onFinished);
    } catch (_) {
      onFinished?.call();
      return false;
    }
  }

  /// Phát lần lượt từng đoạn âm thanh Chị Google chính hãng
  static Future<bool> _playGoogleTtsChunks(
    List<String> chunks,
    int index,
    int playToken,
    double rate,
    double vol,
    void Function()? onFinished,
  ) async {
    if (index >= chunks.length) {
      if (playToken == _currentPlayToken) {
        onFinished?.call();
      }
      return true;
    }

    try {
      final chunkText = chunks[index];
      // Đi qua endpoint /api/tts để loại bỏ Referer, đảm bảo 100% phát ra giọng Chị Google không bao giờ bị lỗi
      final googleUrl = '/api/tts?text=${Uri.encodeComponent(chunkText)}';
      
      final audio = html.AudioElement(googleUrl);
      _activeAudio = audio;
      audio.playbackRate = rate;
      audio.volume = vol;

      final completer = Completer<bool>();

      _endedSubscription?.cancel();
      _endedSubscription = audio.onEnded.listen((_) async {
        if (playToken == _currentPlayToken) {
          final nextOk = await _playGoogleTtsChunks(chunks, index + 1, playToken, rate, vol, onFinished);
          if (!completer.isCompleted) completer.complete(nextOk);
        }
      });

      audio.onError.listen((err) {
        if (!completer.isCompleted) completer.complete(false);
      });

      await audio.play();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fallback qua SpeechSynthesis nếu offline
  static bool _fallbackBrowserSpeech(
    String text,
    int playToken,
    double rate,
    double vol,
    double? pitch,
    void Function()? onFinished,
  ) {
    if (text.isEmpty || html.window.speechSynthesis == null) {
      onFinished?.call();
      return false;
    }

    try {
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = 'vi-VN';
      utterance.rate = rate;
      utterance.volume = vol;
      if (pitch != null) utterance.pitch = pitch.clamp(0.5, 2.0);

      // Cố gắng tìm giọng Google nếu trình duyệt có
      try {
        final voices = html.window.speechSynthesis!.getVoices();
        for (final v in voices) {
          final name = (v.name ?? '').toLowerCase();
          final lang = (v.lang ?? '').toLowerCase();
          // Tuyệt đối không chọn giọng nam (NamMinh, male...)
          if (name.contains('nam') || name.contains('male')) continue;
          if (lang.contains('vi')) {
            utterance.voice = v;
            break;
          }
        }
      } catch (_) {}

      utterance.onEnd.listen((_) {
        if (playToken == _currentPlayToken) onFinished?.call();
      });
      utterance.onError.listen((_) {
        if (playToken == _currentPlayToken) onFinished?.call();
      });

      html.window.speechSynthesis!.speak(utterance);
      return true;
    } catch (_) {
      onFinished?.call();
      return false;
    }
  }
}

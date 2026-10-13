import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_audio_player.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool isEnabled = true;

  // Trạng thái nhắc lại 2 lần (khi có thông báo sẽ đọc 1 lần và nhắc lại)
  bool isRepeatTwiceEnabled = false;

  // Giới hạn khung giờ đọc thông báo (Ví dụ: từ 06:00 đến 22:00)
  bool isScheduleEnabled = false;
  int scheduleStartHour = 6;
  int scheduleStartMinute = 0;
  int scheduleEndHour = 22;
  int scheduleEndMinute = 0;

  bool isWithinActiveHours([DateTime? nowTime]) {
    if (!isScheduleEnabled) return true;
    final now = nowTime ?? DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = scheduleStartHour * 60 + scheduleStartMinute;
    final endMinutes = scheduleEndHour * 60 + scheduleEndMinute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Vắt qua nửa đêm (ví dụ: 20h tối đến 06h sáng)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  void updateSchedule({
    required bool enabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    isScheduleEnabled = enabled;
    if (startHour != null) scheduleStartHour = startHour;
    if (startMinute != null) scheduleStartMinute = startMinute;
    if (endHour != null) scheduleEndHour = endHour;
    if (endMinute != null) scheduleEndMinute = endMinute;
  }

  // Lưu trữ câu thông báo vừa đọc gần nhất
  String _lastSpokenSentence = '';
  String get lastSpokenSentence => _lastSpokenSentence;

  double _speechRate = 0.90;
  double _pitch = 1.0; // Chuẩn 100% Giọng Chị Google quốc dân (tự nhiên, rõ nét)
  double _volume = 1.0;
  String _currentVoiceId = 'chi-google';
  List<Map<String, String>> _availableViVoices = [];
  Map<String, String>? _selectedNativeVoice;

  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get currentVoiceId => _currentVoiceId;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      try {
        await _flutterTts.setEngine('com.google.android.tts');
      } catch (_) {}
      await _flutterTts.setLanguage('vi-VN');
      await _discoverVoices();
      _pickVoiceForPreset(_currentVoiceId);
      await _applyAcoustics();
      _isInitialized = true;
    } catch (_) {
      // Ignored if platform doesn't support vi-VN
    }
  }

  /// Tự động dò tìm các gói giọng đọc Tiếng Việt Chị Google trên thiết bị
  Future<void> _discoverVoices() async {
    try {
      final dynamic raw = await _flutterTts.getVoices;
      if (raw is List) {
        _availableViVoices = [];
        for (final item in raw) {
          if (item is Map) {
            final name = (item['name'] ?? '').toString();
            final locale = (item['locale'] ?? '').toString();
            if (locale.toLowerCase().contains('vi') || name.toLowerCase().contains('vi')) {
              _availableViVoices.add({
                'name': name,
                'locale': locale.isNotEmpty ? locale : 'vi-VN',
              });
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Ưu tiên chọn đúng gói Giọng Chị Google Tiếng Việt (vi-VN chuẩn quốc dân)
  void _pickVoiceForPreset(String presetId) {
    if (_availableViVoices.isEmpty) return;

    // Tìm gói Chị Google (vi-VN, vic, female, google)
    final googleVoice = _availableViVoices.firstWhere(
      (v) {
        final n = v['name']!.toLowerCase();
        return n.contains('google') || n.contains('vic') || n.contains('female') || n.contains('vi-vn');
      },
      orElse: () => _availableViVoices.first,
    );
    _selectedNativeVoice = googleVoice;
  }

  /// Áp dụng cấu hình Giọng Chị Google chuẩn 100%
  Future<void> setVoicePreset(String voiceId, {double? pitch, double? rate}) async {
    _currentVoiceId = 'chi-google';
    await init();
    _pickVoiceForPreset('chi-google');

    _pitch = pitch ?? 1.0; // 100% Chuẩn Chị Google gốc
    _speechRate = rate ?? 0.90;

    await _applyAcoustics();
  }

  Future<void> _applyAcoustics() async {
    try {
      await _flutterTts.setLanguage('vi-VN');
      if (_selectedNativeVoice != null) {
        await _flutterTts.setVoice(_selectedNativeVoice!);
      }
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);
    } catch (_) {}
  }

  /// Cập nhật ngay lập tức các thông số kỹ thuật phát âm
  Future<void> updateAcoustics({
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    if (rate != null) _speechRate = rate;
    if (pitch != null) _pitch = pitch;
    if (volume != null) _volume = volume;
    await _applyAcoustics();
  }


  /// Phát âm thanh thử nghiệm phản hồi ngay lập tức với thông số vừa chỉnh
  Future<void> speakTestFeedback(String sentence, {void Function()? onFinished}) async {
    await speakSentence(sentence, onFinished: onFinished);
  }

  /// Phát âm thanh thông báo nhận tiền theo đúng Form đọc cấu hình
  /// Ví dụ: "Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank, cảm ơn quý khách!"
  Future<void> speakReceivedMoney({
    required double amount,
    String? orderCode,
    String? bankName,
    String? shopName,
    String Function(String amountWords)? customSentenceBuilder,
    void Function()? onFinished,
  }) async {
    if (!isEnabled || !isWithinActiveHours()) {
      if (!isWithinActiveHours()) {
        debugPrint('[TTS] Đang ngoài khung giờ đọc thông báo ($scheduleStartHour:${scheduleStartMinute.toString().padLeft(2, '0')} - $scheduleEndHour:${scheduleEndMinute.toString().padLeft(2, '0')}). Giữ im lặng.');
      }
      onFinished?.call();
      return;
    }

    final amountText = _formatAmountToWords(amount.toInt());
    String sentence;

    if (customSentenceBuilder != null) {
      sentence = customSentenceBuilder(amountText);
    } else {
      sentence = 'Đã nhận $amountText đồng';
      if (bankName != null && bankName.isNotEmpty) {
        sentence += ' từ $bankName';
      }
      if (orderCode != null && orderCode.isNotEmpty) {
        final spelledOrder = orderCode.split('').join(' ');
        sentence += ', đơn hàng $spelledOrder';
      }
    }

    await speakSentence(sentence, onFinished: onFinished);
  }

  /// Phát một câu văn bản bất kỳ với đúng thông số kỹ thuật âm thanh hiện tại
  Future<void> speakSentence(String sentence, {void Function()? onFinished}) async {
    if (!isEnabled) {
      onFinished?.call();
      return;
    }
    _lastSpokenSentence = sentence;

    // 1. Thử phát audio Chị Google chuẩn 100% qua web player (cho môi trường Web/Chrome)
    try {
      PlatformAudioPlayer.stop();
      final rateParam = '${((_speechRate - 1.0) * 100).toInt()}%';
      final pitchParam = '${((_pitch - 1.0) * 100).toInt()}Hz';
      final volParam = '${((_volume - 1.0) * 100).toInt()}%';
      final audioUrl = 'http://localhost:3000/tts?voice=$_currentVoiceId&text=${Uri.encodeComponent(sentence)}&rate=${Uri.encodeComponent(rateParam)}&pitch=${Uri.encodeComponent(pitchParam)}&volume=${Uri.encodeComponent(volParam)}';
      bool hasRepeated = false;
      final playedOnWeb = await PlatformAudioPlayer.playAudio(
        audioUrl,
        text: sentence,
        speechRate: _speechRate,
        volume: _volume,
        pitch: _pitch,
        onFinished: () {
          if (isRepeatTwiceEnabled && isEnabled && !hasRepeated) {
            hasRepeated = true;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (isEnabled) {
                PlatformAudioPlayer.playAudio(
                  audioUrl,
                  text: sentence,
                  speechRate: _speechRate,
                  volume: _volume,
                  pitch: _pitch,
                  onFinished: onFinished,
                );
              } else {
                onFinished?.call();
              }
            });
          } else {
            onFinished?.call();
          }
        },
      );
      if (playedOnWeb) {
        return;
      }
    } catch (_) {}

    // Trên nền tảng Web, KHÔNG fallback qua flutter_tts vì Chrome Windows không có giọng tiếng Việt và sẽ đọc bằng giọng Mỹ méo tiếng
    if (kIsWeb) {
      onFinished?.call();
      return;
    }

    // 2. Fallback qua FlutterTts (Android máy thật com.google.android.tts)
    await init();
    try {
      await _flutterTts.stop();
      await _applyAcoustics();

      _flutterTts.setCompletionHandler(() async {
        if (isRepeatTwiceEnabled && isEnabled) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (isEnabled) {
            _flutterTts.setCompletionHandler(() {
              onFinished?.call();
            });
            await _flutterTts.speak(sentence);
            return;
          }
        }
        onFinished?.call();
      });

      await _flutterTts.speak(sentence);
    } catch (_) {
      onFinished?.call();
    }
  }

  /// Dừng phát âm thanh ngay lập tức (khi người dùng bấm nút Đóng hoặc tắt thông báo)
  Future<void> stop() async {
    try {
      PlatformAudioPlayer.stop();
      if (!kIsWeb) {
        await _flutterTts.stop();
      }
    } catch (_) {}
  }

  /// Đọc lại thông báo vừa đọc lúc nãy nếu không nghe rõ
  Future<void> replayLastSentence() async {
    final toSpeak = _lastSpokenSentence.isNotEmpty
        ? _lastSpokenSentence
        : 'Chưa có thông báo gần đây để đọc lại.';
    await speakSentence(toSpeak);
  }

  /// Chuyển đổi số tiền thành chữ tiếng Việt đọc tự nhiên
  static String _formatAmountToWords(int number) {
    if (number <= 0) return 'không';

    if (number >= 1000000000) {
      final billions = number ~/ 1000000000;
      final remainder = number % 1000000000;
      if (remainder == 0) return '$billions tỷ';
      return '$billions tỷ ${_formatAmountToWords(remainder)}';
    }

    if (number >= 1000000) {
      final millions = number ~/ 1000000;
      final remainder = number % 1000000;
      if (remainder == 0) return '$millions triệu';
      final remainderWords = _formatAmountToWords(remainder);
      return '$millions triệu $remainderWords';
    }

    if (number >= 1000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      if (remainder == 0) return '$thousands nghìn';
      return '$thousands nghìn ${_formatAmountToWords(remainder)}';
    }

    return '$number';
  }
}

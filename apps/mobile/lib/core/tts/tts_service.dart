import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tts_audio_player.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool isEnabled = true;

  // Trạng thái nhắc lại 2 lần (khi có thông báo sẽ đọc 1 lần và nhắc lại)
  bool isRepeatTwiceEnabled = false;

  Future<void> setRepeatTwice(bool value) async {
    isRepeatTwiceEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autobank_tts_repeat_twice', value);
    } catch (_) {}
  }

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

  Future<void> loadScheduleSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isScheduleEnabled = prefs.getBool('autobank_tts_schedule_enabled') ?? false;
      scheduleStartHour = prefs.getInt('autobank_tts_schedule_start_hour') ?? 6;
      scheduleStartMinute = prefs.getInt('autobank_tts_schedule_start_minute') ?? 0;
      scheduleEndHour = prefs.getInt('autobank_tts_schedule_end_hour') ?? 22;
      scheduleEndMinute = prefs.getInt('autobank_tts_schedule_end_minute') ?? 0;
      isRepeatTwiceEnabled = prefs.getBool('autobank_tts_repeat_twice') ?? false;

      // Đọc và khôi phục chính xác tốc độ, cao độ, âm lượng từ cài đặt người dùng
      if (prefs.containsKey('autobank_tts_speech_rate')) {
        _speechRate = prefs.getDouble('autobank_tts_speech_rate') ?? _speechRate;
      }
      if (prefs.containsKey('autobank_tts_pitch')) {
        _pitch = prefs.getDouble('autobank_tts_pitch') ?? _pitch;
      }
      if (prefs.containsKey('autobank_tts_volume')) {
        _volume = prefs.getDouble('autobank_tts_volume') ?? _volume;
      }
      if (prefs.containsKey('autobank_tts_credit_enabled')) {
        isCreditReadEnabled = prefs.getBool('autobank_tts_credit_enabled') ?? true;
      }
      if (prefs.containsKey('autobank_tts_debit_enabled')) {
        isDebitReadEnabled = prefs.getBool('autobank_tts_debit_enabled') ?? true;
      }
    } catch (_) {}
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

    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('autobank_tts_schedule_enabled', isScheduleEnabled);
        prefs.setInt('autobank_tts_schedule_start_hour', scheduleStartHour);
        prefs.setInt('autobank_tts_schedule_start_minute', scheduleStartMinute);
        prefs.setInt('autobank_tts_schedule_end_hour', scheduleEndHour);
        prefs.setInt('autobank_tts_schedule_end_minute', scheduleEndMinute);
      });
    } catch (_) {}
  }

  // Lưu trữ câu thông báo biến động ngân hàng vừa đọc gần nhất (chỉ lưu giao dịch thực tế)
  String _lastBankTransactionSentence = '';
  String get lastBankTransactionSentence => _lastBankTransactionSentence;
  String _lastSpokenSentence = '';
  String get lastSpokenSentence => _lastBankTransactionSentence.isNotEmpty ? _lastBankTransactionSentence : _lastSpokenSentence;

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
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;
    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('autobank_tts_repeat_twice')) {
          isRepeatTwiceEnabled = prefs.getBool('autobank_tts_repeat_twice') ?? false;
        }
      } catch (_) {}
      await loadScheduleSettings();

      if (!kIsWeb) {
        // 1. Cài đặt ngôn ngữ Tiếng Việt chuẩn
        try {
          await _flutterTts.setLanguage('vi-VN');
        } catch (_) {
          try {
            await _flutterTts.setLanguage('vi');
          } catch (_) {}
        }

        // 2. Dò tìm và ưu tiên Google Speech Services nếu hỗ trợ Tiếng Việt
        try {
          final engines = await _flutterTts.getEngines;
          if (engines is List && engines.contains('com.google.android.tts')) {
            await _flutterTts.setEngine('com.google.android.tts');
            final isViAvailable = await _flutterTts.isLanguageAvailable('vi-VN');
            if (isViAvailable != 1 && isViAvailable != true) {
              debugPrint('[TTS] com.google.android.tts chưa tải gói vi-VN, khôi phục engine mặc định');
              await _flutterTts.getDefaultEngine;
            } else {
              debugPrint('[TTS] Đã kích hoạt engine Google Text-to-Speech chuẩn');
            }
          }
        } catch (e) {
          debugPrint('[TTS] Engine setup notice: $e');
        }

        // 3. Queue mode = QUEUE_FLUSH (0) để ngắt âm cũ và phát ngay khi có thông báo mới
        try {
          await _flutterTts.setQueueMode(0);
        } catch (_) {}

        // 4. Tuyệt đối dùng awaitSpeakCompletion(false) để không bị khóa cứng luồng Dart
        try {
          await _flutterTts.awaitSpeakCompletion(false);
        } catch (_) {}

        try {
          await _discoverVoices();
          _pickVoiceForPreset(_currentVoiceId);
          await _applyAcoustics();
        } catch (_) {}
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[TTS] init error: $e');
    } finally {
      _isInitializing = false;
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

    // Khóa cứng tìm gói Chị Google Nữ (loại bỏ triệt để giọng nam)
    final googleVoice = _availableViVoices.firstWhere(
      (v) {
        final n = v['name']!.toLowerCase();
        if (n.contains('male') || n.contains('nam')) return false;
        return n.contains('google') || n.contains('vic') || n.contains('female') || n.contains('vi-vn');
      },
      orElse: () => _availableViVoices.firstWhere(
        (v) => !v['name']!.toLowerCase().contains('nam') && !v['name']!.toLowerCase().contains('male'),
        orElse: () => _availableViVoices.first,
      ),
    );
    _selectedNativeVoice = googleVoice;
  }

  /// Áp dụng cấu hình Giọng Chị Google chuẩn 100%
  Future<void> setVoicePreset(String voiceId, {double? pitch, double? rate}) async {
    _currentVoiceId = 'chi-google';
    await init();
    _pickVoiceForPreset('chi-google');

    _pitch = pitch ?? _pitch;
    _speechRate = rate ?? _speechRate;

    await _applyAcoustics();
  }

  Future<void> _applyAcoustics() async {
    if (kIsWeb) return;
    try {
      await _flutterTts.setLanguage('vi-VN');
      if (_selectedNativeVoice != null) {
        try {
          await _flutterTts.setVoice(_selectedNativeVoice!);
        } catch (_) {}
      }
      // Trên Android, flutter_tts chuẩn hóa 0.5 là tốc độ tự nhiên chuẩn 1.0x
      final androidRate = (_speechRate * 0.55).clamp(0.35, 0.85);
      await _flutterTts.setSpeechRate(androidRate);
      await _flutterTts.setPitch(_pitch.clamp(0.5, 2.0));
      await _flutterTts.setVolume(_volume.clamp(0.1, 1.0));
    } catch (e) {
      debugPrint('[TTS] _applyAcoustics error: $e');
    }
  }

  /// Cập nhật ngay lập tức các thông số kỹ thuật phát âm và lưu bền vững
  Future<void> updateAcoustics({
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    if (rate != null) _speechRate = rate;
    if (pitch != null) _pitch = pitch;
    if (volume != null) _volume = volume;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('autobank_tts_speech_rate', _speechRate);
      await prefs.setDouble('autobank_tts_pitch', _pitch);
      await prefs.setDouble('autobank_tts_volume', _volume);
    } catch (_) {}
    await _applyAcoustics();
  }

  /// Phát âm thanh thử nghiệm phản hồi ngay lập tức với thông số vừa chỉnh (không lưu đè vào câu thông báo ngân hàng)
  Future<void> speakTestFeedback(String sentence, {void Function()? onFinished}) async {
    await speakSentence(sentence, onFinished: onFinished, isBankTransaction: false, bypassChecks: true);
  }

  // Bật/tắt đọc riêng biệt cho 2 loại: Nhận tiền (Credit) và Chuyển đi (Debit)
  bool isCreditReadEnabled = true;
  bool isDebitReadEnabled = true;

  Future<void> setCreditEnabled(bool value) async {
    isCreditReadEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autobank_tts_credit_enabled', value);
    } catch (_) {}
  }

  Future<void> setDebitEnabled(bool value) async {
    isDebitReadEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autobank_tts_debit_enabled', value);
    } catch (_) {}
  }

  /// Callback tạo câu đọc chuẩn theo Form kịch bản cấu hình người dùng (Nhận tiền)
  String Function({required String amountWords, String? bankName, String? shopOrOrder})? globalSentenceBuilder;

  /// Callback tạo câu đọc chuẩn theo Form kịch bản cấu hình người dùng (Chuyển đi)
  String Function({required String amountWords, String? bankName, String? shopOrOrder})? globalDebitSentenceBuilder;

  /// Phát âm thanh thông báo nhận tiền theo đúng Form đọc cấu hình
  /// Ví dụ: "Đã nhận hai trăm năm mươi nghìn đồng từ Techcombank, cảm ơn quý khách!"
  Future<void> speakReceivedMoney({
    required double amount,
    String? orderCode,
    String? bankName,
    String? shopName,
    String Function(String amountWords)? customSentenceBuilder,
    void Function()? onFinished,
    bool bypassChecks = false,
  }) async {
    if (!bypassChecks && (!isEnabled || !isCreditReadEnabled || !isWithinActiveHours())) {
      if (!isWithinActiveHours()) {
        debugPrint('[TTS] Đang ngoài khung giờ đọc thông báo ($scheduleStartHour:${scheduleStartMinute.toString().padLeft(2, '0')} - $scheduleEndHour:${scheduleEndMinute.toString().padLeft(2, '0')}). Giữ im lặng.');
      }
      onFinished?.call();
      return;
    }

    final amountText = formatAmountToWords(amount.toInt());
    String sentence;

    final cleanBank = (bankName != null && bankName.isNotEmpty && bankName != 'OTHER_BANK') ? bankName : null;
    final cleanOrder = (orderCode != null && orderCode.isNotEmpty) ? orderCode : null;

    if (customSentenceBuilder != null) {
      sentence = customSentenceBuilder(amountText);
    } else if (globalSentenceBuilder != null) {
      sentence = globalSentenceBuilder!(
        amountWords: amountText,
        bankName: cleanBank,
        shopOrOrder: cleanOrder != null ? 'đơn hàng ${cleanOrder.split('').join(' ')}' : (shopName ?? ''),
      );
    } else {
      sentence = 'Đã nhận $amountText đồng';
      if (cleanBank != null) {
        sentence += ' từ $cleanBank';
      }
      if (cleanOrder != null) {
        final spelledOrder = cleanOrder.split('').join(' ');
        sentence += ', đơn hàng $spelledOrder';
      }
    }

    _lastBankTransactionSentence = sentence;
    await speakSentence(sentence, onFinished: onFinished, isBankTransaction: true, bypassChecks: bypassChecks);
  }

  /// Phát âm thanh thông báo trừ tiền (tiền ra / chi tiêu) theo đúng Form cấu hình chuyển đi
  Future<void> speakDebitMoney({
    required double amount,
    String? orderCode,
    String? bankName,
    String Function(String amountWords)? customSentenceBuilder,
    void Function()? onFinished,
    bool bypassChecks = false,
  }) async {
    if (!bypassChecks && (!isEnabled || !isDebitReadEnabled || !isWithinActiveHours())) {
      if (!isWithinActiveHours()) {
        debugPrint('[TTS] Đang ngoài khung giờ đọc thông báo ($scheduleStartHour:${scheduleStartMinute.toString().padLeft(2, '0')} - $scheduleEndHour:${scheduleEndMinute.toString().padLeft(2, '0')}). Giữ im lặng.');
      }
      onFinished?.call();
      return;
    }

    final amountText = formatAmountToWords(amount.toInt());
    String sentence;

    final cleanBank = (bankName != null && bankName.isNotEmpty && bankName != 'OTHER_BANK') ? bankName : null;
    final cleanOrder = (orderCode != null && orderCode.isNotEmpty) ? orderCode : null;

    if (customSentenceBuilder != null) {
      sentence = customSentenceBuilder(amountText);
    } else if (globalDebitSentenceBuilder != null) {
      sentence = globalDebitSentenceBuilder!(
        amountWords: amountText,
        bankName: cleanBank,
        shopOrOrder: cleanOrder != null ? 'mã ${cleanOrder.split('').join(' ')}' : '',
      );
    } else {
      sentence = 'Đã chuyển $amountText đồng';
      if (cleanBank != null) {
        sentence += ' qua $cleanBank';
      }
      if (cleanOrder != null) {
        final spelledOrder = cleanOrder.split('').join(' ');
        sentence += ', mã $spelledOrder';
      }
    }

    _lastBankTransactionSentence = sentence;
    await speakSentence(sentence, onFinished: onFinished, isBankTransaction: true, bypassChecks: bypassChecks);
  }

  /// Phát một câu văn bản bất kỳ với đúng thông số kỹ thuật âm thanh hiện tại
  Future<void> speakSentence(String sentence, {void Function()? onFinished, bool isBankTransaction = false, bool bypassChecks = false}) async {
    if (!isEnabled && !bypassChecks) {
      onFinished?.call();
      return;
    }
    _lastSpokenSentence = sentence;
    if (isBankTransaction) {
      _lastBankTransactionSentence = sentence;
    }

    // Làm sạch emoji biểu tượng (như chuông 🔔, icon) để audio engine đọc trơn tru
    final cleanSentence = sentence.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '').trim();

    // 1. Thử phát audio Chị Google chuẩn 100% qua web player (cho môi trường Web/Chrome)
    try {
      PlatformAudioPlayer.stop();
      final audioUrl = 'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=vi&q=${Uri.encodeComponent(cleanSentence)}';
      bool hasRepeated = false;
      final playedOnWeb = await PlatformAudioPlayer.playAudio(
        audioUrl,
        text: cleanSentence,
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

      final repeatTimes = (isRepeatTwiceEnabled && isBankTransaction) ? 2 : 1;
      for (int i = 0; i < repeatTimes; i++) {
        if (!isEnabled && !bypassChecks) break;
        if (i > 0) {
          final delayMs = (cleanSentence.length * 85).clamp(2500, 6000);
          await Future.delayed(Duration(milliseconds: delayMs));
          if (!isEnabled && !bypassChecks) break;
        }
        await _flutterTts.speak(cleanSentence).timeout(
          const Duration(seconds: 5),
          onTimeout: () => 0,
        );
        debugPrint('[TTS Android] speak called | sentence: $cleanSentence');
      }
      onFinished?.call();
    } catch (e) {
      debugPrint('[TTS Android] speak error: $e');
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

  /// Đọc lại thông báo ngân hàng vừa nhận về gần nhất
  Future<void> replayLastSentence() async {
    final toSpeak = _lastBankTransactionSentence.isNotEmpty
        ? _lastBankTransactionSentence
        : 'Chưa có thông báo nhận tiền mới từ ngân hàng để đọc lại.';
    await speakSentence(toSpeak, isBankTransaction: true);
  }

  /// Chuyển đổi số tiền thành chữ tiếng Việt đọc tự nhiên
  static String formatAmountToWords(int number) {
    if (number <= 0) return 'không';

    if (number >= 1000000000) {
      final billions = number ~/ 1000000000;
      final remainder = number % 1000000000;
      if (remainder == 0) return '$billions tỷ';
      return '$billions tỷ ${formatAmountToWords(remainder)}';
    }

    if (number >= 1000000) {
      final millions = number ~/ 1000000;
      final remainder = number % 1000000;
      if (remainder == 0) return '$millions triệu';
      final remainderWords = formatAmountToWords(remainder);
      return '$millions triệu $remainderWords';
    }

    if (number >= 1000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      if (remainder == 0) return '$thousands nghìn';
      return '$thousands nghìn ${formatAmountToWords(remainder)}';
    }

    return '$number';
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/tts/tts_service.dart';

/// Thông tin 7 cấu hình giọng đọc chuẩn
class VoicePreset {
  final String id;
  final String name;
  final String region;
  final String desc;
  final String avatar;
  final double defaultPitch;
  final double defaultRate;
  final bool isFree; // Chỉ giọng nu-bac là mặc định miễn phí cho gói dùng thử

  const VoicePreset({
    required this.id,
    required this.name,
    required this.region,
    required this.desc,
    required this.avatar,
    this.defaultPitch = 1.0,
    this.defaultRate = 0.9,
    this.isFree = false,
  });
}

/// Khối thành phần trong Form đọc duy nhất
class SentenceBlockItem {
  final String id;
  final String title;
  final String sample;
  final IconData icon;
  bool isEnabled;

  SentenceBlockItem({
    required this.id,
    required this.title,
    required this.sample,
    required this.icon,
    this.isEnabled = true,
  });

  SentenceBlockItem copyWith({bool? isEnabled}) {
    return SentenceBlockItem(
      id: id,
      title: title,
      sample: sample,
      icon: icon,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Mẫu kịch bản đọc sẵn (Presets)
class ReadingPreset {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final List<String> blockOrder;
  final List<String> enabledBlocks;

  const ReadingPreset({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.blockOrder,
    required this.enabledBlocks,
  });
}

class VoiceSettingsProvider extends ChangeNotifier {
  // Giọng Chị Google chuẩn 100% duy nhất của hệ thống
  static const List<VoicePreset> availablePresets = [
    VoicePreset(
      id: 'chi-google',
      name: 'Giọng đọc chuẩn',
      region: 'Việt Nam (Quốc Dân)',
      desc: 'Giọng đọc chuẩn to rõ, tự nhiên, chính xác từng số tiền',
      avatar: '🔊 Giọng chuẩn',
      defaultPitch: 1.0,
      defaultRate: 0.90,
      isFree: true,
    ),
  ];

  // Danh sách kịch bản mẫu
  static const List<ReadingPreset> readingPresets = [
    ReadingPreset(
      id: 'BANK_STANDARD',
      name: 'Chuẩn Ngân Hàng',
      desc: 'Chuông ting + Tiền tố + Số tiền + Ngân hàng',
      icon: Icons.account_balance_rounded,
      blockOrder: ['bell', 'prefix', 'amount', 'bank'],
      enabledBlocks: ['bell', 'prefix', 'amount', 'bank'],
    ),
    ReadingPreset(
      id: 'STORE_POLITE',
      name: 'Lịch Sự & Bán Hàng',
      desc: 'Chuông ting + Số tiền + Tên quán + Lời cảm ơn',
      icon: Icons.storefront_rounded,
      blockOrder: ['bell', 'prefix', 'amount', 'shopOrOrder', 'suffix'],
      enabledBlocks: ['bell', 'prefix', 'amount', 'shopOrOrder', 'suffix'],
    ),
    ReadingPreset(
      id: 'FAST_RUSH',
      name: 'Siêu Nhanh Giờ Cao Điểm',
      desc: 'Đã nhận + Số tiền (ngắn gọn, chống ùn tắc quầy)',
      icon: Icons.bolt_rounded,
      blockOrder: ['prefix', 'amount'],
      enabledBlocks: ['prefix', 'amount'],
    ),
    ReadingPreset(
      id: 'FULL_RECONCILE',
      name: 'Đối Soát Chi Tiết',
      desc: 'Đầy đủ chuông, số tiền, ngân hàng, mã đơn hàng',
      icon: Icons.receipt_long_rounded,
      blockOrder: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder'],
      enabledBlocks: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder'],
    ),
    ReadingPreset(
      id: 'CUSTOM_BUILDER',
      name: 'Tự Do Sắp Xếp',
      desc: 'Tùy chỉnh thứ tự và bật/tắt mọi thành phần theo ý bạn',
      icon: Icons.tune_rounded,
      blockOrder: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder', 'suffix'],
      enabledBlocks: ['bell', 'prefix', 'amount', 'bank'],
    ),
  ];

  // Trạng thái cấu hình giọng - 100% Chị Google
  String _selectedVoiceId = 'chi-google';
  double _speechRate = 0.90;
  double _pitch = 1.0;
  double _volume = 1.0;
  bool _isPlayingSample = false;

  // Cấu hình Form đọc duy nhất & các khối thành phần
  String _activePresetId = 'BANK_STANDARD';
  String _prefixWord = 'Đã nhận';
  String _suffixWord = 'Cảm ơn quý khách!';
  
  // Tùy chọn chi tiết cách đọc các thành phần
  String _amountStyle = 'dong'; // 'dong', 'vnd', 'compact', 'short_k'
  String _bankStyle = 'tu';     // 'tu' (từ...), 'qua' (qua...), 'vao' (vào tài khoản...), 'ten' (chỉ tên)
  String _shopStyle = 'don';    // 'don' (đơn hàng...), 'quan' (tại quán...), 'khach' (khách thanh toán...)

  // Thứ tự các khối thành phần có thể sắp xếp
  late List<SentenceBlockItem> _blocks;

  final FlutterTts _tts = FlutterTts();

  // Getters
  String get selectedVoiceId => _selectedVoiceId;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  bool get isPlayingSample => _isPlayingSample;
  String get activePresetId => _activePresetId;
  String get prefixWord => _prefixWord;
  String get suffixWord => _suffixWord;
  String get amountStyle => _amountStyle;
  String get bankStyle => _bankStyle;
  String get shopStyle => _shopStyle;
  List<SentenceBlockItem> get blocks => List.unmodifiable(_blocks);

  VoicePreset get currentPreset =>
      availablePresets.firstWhere((p) => p.id == _selectedVoiceId, orElse: () => availablePresets[0]);

  // Backward compatibility getters
  bool get readBankName => isBlockEnabled('bank');
  bool get readOrderCode => isBlockEnabled('shopOrOrder');
  bool get playChime => isBlockEnabled('bell');

  VoiceSettingsProvider() {
    _initBlocks();
    _initTts();
  }

  void _initBlocks() {
    _blocks = [
      SentenceBlockItem(
        id: 'bell',
        title: 'Âm chuông Ting-Ting',
        sample: 'Ting-Ting',
        icon: Icons.notifications_active_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'prefix',
        title: 'Lời chào / Tiền tố',
        sample: 'Đã nhận',
        icon: Icons.record_voice_over_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'amount',
        title: 'Số tiền thanh toán',
        sample: '250.000 đồng',
        icon: Icons.payments_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'bank',
        title: 'Tên ngân hàng nhận',
        sample: 'từ Techcombank',
        icon: Icons.account_balance_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'shopOrOrder',
        title: 'Tên quán / Mã đơn',
        sample: 'đơn hàng D H 1 0 5 8',
        icon: Icons.storefront_rounded,
        isEnabled: false,
      ),
      SentenceBlockItem(
        id: 'suffix',
        title: 'Lời cảm ơn / Hậu tố',
        sample: 'Cảm ơn quý khách!',
        icon: Icons.favorite_rounded,
        isEnabled: false,
      ),
    ];
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('vi-VN');
      await _applyTtsSettings();
    } catch (_) {}
  }

  Future<void> _applyTtsSettings() async {
    try {
      await TtsService().setVoicePreset(
        _selectedVoiceId,
        pitch: _pitch,
        rate: _speechRate,
      );
      await TtsService().updateAcoustics(
        rate: _speechRate,
        pitch: _pitch,
        volume: _volume,
      );
    } catch (_) {}
  }

  /// Giọng Chị Google chuẩn 100% mở khóa miễn phí cho tất cả tài khoản
  bool isVoiceUnlocked(String voiceId, {required bool isPaidAccount}) {
    return true;
  }

  /// Chọn giọng nói
  Future<void> selectVoice(String voiceId) async {
    if (_selectedVoiceId == voiceId) return;
    _selectedVoiceId = voiceId;
    final preset = currentPreset;
    _pitch = preset.defaultPitch;
    _speechRate = preset.defaultRate;
    await TtsService().setVoicePreset(voiceId, pitch: _pitch, rate: _speechRate);
    await _applyTtsSettings();
    notifyListeners();
  }

  /// Điều chỉnh tốc độ đọc (có tùy chọn phát âm thanh phản hồi ngay lập tức)
  Future<void> setSpeechRate(double rate, {bool testAudio = false}) async {
    _speechRate = rate;
    await _applyTtsSettings();
    notifyListeners();
    if (testAudio) {
      final ratePercent = (rate * 100).toInt();
      await TtsService().speakTestFeedback('Tốc độ đọc $ratePercent phần trăm');
    }
  }

  /// Điều chỉnh cao độ (Pitch) (có tùy chọn phát âm thanh phản hồi ngay lập tức)
  Future<void> setPitch(double val, {bool testAudio = false}) async {
    _pitch = val;
    await _applyTtsSettings();
    notifyListeners();
    if (testAudio) {
      final pitchPercent = (val * 100).toInt();
      await TtsService().speakTestFeedback('Cao độ giọng $pitchPercent phần trăm');
    }
  }

  /// Điều chỉnh âm lượng (có tùy chọn phát âm thanh phản hồi ngay lập tức)
  Future<void> setVolume(double val, {bool testAudio = false}) async {
    _volume = val;
    await _applyTtsSettings();
    notifyListeners();
    if (testAudio) {
      final volPercent = (val * 100).toInt();
      await TtsService().speakTestFeedback('Âm lượng $volPercent phần trăm');
    }
  }

  /// Cập nhật phong cách đọc số tiền: 'dong', 'vnd', 'compact', 'short_k'
  void setAmountStyle(String style) {
    _amountStyle = style;
    notifyListeners();
  }

  /// Cập nhật phong cách đọc ngân hàng: 'tu', 'qua', 'vao', 'ten'
  void setBankStyle(String style) {
    _bankStyle = style;
    notifyListeners();
  }

  /// Cập nhật phong cách đọc quán / mã đơn: 'don', 'quan', 'khach'
  void setShopStyle(String style) {
    _shopStyle = style;
    notifyListeners();
  }

  /// Khôi phục toàn bộ cài đặt âm thanh về chuẩn tối ưu ban đầu
  Future<void> resetToDefaults() async {
    final preset = currentPreset;
    _pitch = preset.defaultPitch;
    _speechRate = preset.defaultRate;
    _volume = 1.0;
    _amountStyle = 'dong';
    _bankStyle = 'tu';
    _shopStyle = 'don';
    await _applyTtsSettings();
    notifyListeners();
  }

  /// Bật / tắt 1 khối trong Form đọc
  void toggleBlock(String blockId) {
    // Không cho tắt số tiền vì đây là thông tin bắt buộc
    if (blockId == 'amount') return;
    final idx = _blocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      _blocks[idx].isEnabled = !_blocks[idx].isEnabled;
      _activePresetId = 'CUSTOM_BUILDER';
      notifyListeners();
    }
  }

  bool isBlockEnabled(String blockId) {
    final found = _blocks.firstWhere((b) => b.id == blockId, orElse: () => _blocks[0]);
    return found.isEnabled;
  }

  /// Sắp xếp di chuyển vị trí khối lên trên
  void moveBlockUp(int index) {
    if (index > 0 && index < _blocks.length) {
      final item = _blocks.removeAt(index);
      _blocks.insert(index - 1, item);
      _activePresetId = 'CUSTOM_BUILDER';
      notifyListeners();
    }
  }

  /// Sắp xếp di chuyển vị trí khối xuống dưới
  void moveBlockDown(int index) {
    if (index >= 0 && index < _blocks.length - 1) {
      final item = _blocks.removeAt(index);
      _blocks.insert(index + 1, item);
      _activePresetId = 'CUSTOM_BUILDER';
      notifyListeners();
    }
  }

  /// Kéo thả đổi vị trí khối
  void reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _blocks.removeAt(oldIndex);
    _blocks.insert(newIndex, item);
    _activePresetId = 'CUSTOM_BUILDER';
    notifyListeners();
  }

  /// Áp dụng kịch bản mẫu
  void applyReadingPreset(String presetId) {
    final preset = readingPresets.firstWhere((p) => p.id == presetId, orElse: () => readingPresets[0]);
    _activePresetId = presetId;

    // Sắp xếp lại thứ tự các blocks theo preset
    final List<SentenceBlockItem> reordered = [];
    for (final blockId in preset.blockOrder) {
      final found = _blocks.firstWhere((b) => b.id == blockId, orElse: () => _blocks[0]);
      found.isEnabled = preset.enabledBlocks.contains(blockId);
      reordered.add(found);
    }
    // Đưa các khối còn lại vào cuối với trạng thái tắt
    for (final b in _blocks) {
      if (!reordered.any((item) => item.id == b.id)) {
        b.isEnabled = false;
        reordered.add(b);
      }
    }
    _blocks = reordered;
    notifyListeners();
  }

  /// Cập nhật câu chào / tiền tố
  void setPrefixWord(String text) {
    _prefixWord = text;
    notifyListeners();
  }

  /// Cập nhật lời cảm ơn / hậu tố
  void setSuffixWord(String text) {
    _suffixWord = text;
    notifyListeners();
  }

  // Tương thích ngược với các switch cũ
  void toggleReadBankName(bool val) {
    final idx = _blocks.indexWhere((b) => b.id == 'bank');
    if (idx != -1) {
      _blocks[idx].isEnabled = val;
      notifyListeners();
    }
  }

  void toggleReadOrderCode(bool val) {
    final idx = _blocks.indexWhere((b) => b.id == 'shopOrOrder');
    if (idx != -1) {
      _blocks[idx].isEnabled = val;
      notifyListeners();
    }
  }

  void togglePlayChime(bool val) {
    final idx = _blocks.indexWhere((b) => b.id == 'bell');
    if (idx != -1) {
      _blocks[idx].isEnabled = val;
      notifyListeners();
    }
  }

  /// TẠO CÂU ĐỌC THEO FORM CHUẨN DUY NHẤT VÀ THỨ TỰ CÁC KHỐI ĐÃ CẤU HÌNH
  String generateSentence({
    required String amountWords,
    String? bankName = 'Techcombank',
    String? shopOrOrder = 'đơn hàng D H 1 0 5 8',
  }) {
    final List<Map<String, String>> blockParts = [];

    for (final block in _blocks) {
      if (!block.isEnabled) continue;

      switch (block.id) {
        case 'bell':
          blockParts.add({'type': 'bell', 'text': 'Ting!'});
          break;
        case 'prefix':
          if (_prefixWord.isNotEmpty) {
            blockParts.add({'type': 'prefix', 'text': _prefixWord.trim()});
          }
          break;
        case 'amount':
          String amt = amountWords.replaceAll(' đồng', '').trim();
          String finalAmt;
          if (_amountStyle == 'dong') {
            finalAmt = '$amt đồng';
          } else if (_amountStyle == 'vnd') {
            finalAmt = '$amt V N Đ';
          } else if (_amountStyle == 'compact' || _amountStyle == 'short_k') {
            finalAmt = amt;
          } else {
            finalAmt = '$amt đồng';
          }
          blockParts.add({'type': 'amount', 'text': finalAmt});
          break;
        case 'bank':
          if (bankName != null && bankName.isNotEmpty) {
            String bText;
            if (_bankStyle == 'tu') {
              bText = 'từ $bankName';
            } else if (_bankStyle == 'qua') {
              bText = 'qua $bankName';
            } else if (_bankStyle == 'vao') {
              bText = 'vào tài khoản $bankName';
            } else {
              bText = bankName;
            }
            blockParts.add({'type': 'bank', 'text': bText});
          }
          break;
        case 'shopOrOrder':
          if (shopOrOrder != null && shopOrOrder.isNotEmpty) {
            String sText;
            if (_shopStyle == 'don') {
              sText = shopOrOrder;
            } else if (_shopStyle == 'quan') {
              sText = 'tại quán';
            } else if (_shopStyle == 'khach') {
              sText = 'khách thanh toán';
            } else {
              sText = shopOrOrder;
            }
            blockParts.add({'type': 'shopOrOrder', 'text': sText});
          }
          break;
        case 'suffix':
          if (_suffixWord.isNotEmpty && _suffixWord != 'Không đọc lời cảm ơn') {
            blockParts.add({'type': 'suffix', 'text': _suffixWord.trim()});
          }
          break;
      }
    }

    if (blockParts.isEmpty) {
      return 'Đã nhận $amountWords đồng';
    }

    String result = '';
    for (int i = 0; i < blockParts.length; i++) {
      final part = blockParts[i];
      final type = part['type']!;
      final text = part['text']!;

      if (result.isEmpty) {
        result = text;
      } else {
        if (result.endsWith('!')) {
          result = '$result $text';
        } else if (type == 'bank' || type == 'shopOrOrder' || type == 'suffix') {
          // Các khối ngân hàng, đơn hàng, và đặc biệt là HẬU TỐ (lời cảm ơn) LUÔN thêm dấu phẩy trước để ngắt nhịp đọc hay hơn
          result = '$result, $text';
        } else if (type == 'amount' && result.endsWith(',')) {
          result = '$result $text';
        } else {
          result = '$result $text';
        }
      }
    }

    return result.replaceAll(RegExp(r'\s+,'), ',').replaceAll(RegExp(r',+'), ',');
  }

  /// Lấy câu đọc hoàn chỉnh trực quan để hiển thị trên UI Xem Trước
  String getLivePreviewSentence(String sampleAmountLabel) {
    final List<Map<String, String>> blockParts = [];

    for (final block in _blocks) {
      if (!block.isEnabled) continue;

      switch (block.id) {
        case 'bell':
          blockParts.add({'type': 'bell', 'text': '🔔 Ting!'});
          break;
        case 'prefix':
          if (_prefixWord.isNotEmpty) {
            blockParts.add({'type': 'prefix', 'text': _prefixWord.trim()});
          }
          break;
        case 'amount':
          String amtLabel;
          if (_amountStyle == 'vnd') {
            amtLabel = '$sampleAmountLabel VNĐ';
          } else if (_amountStyle == 'compact' || _amountStyle == 'short_k') {
            amtLabel = sampleAmountLabel.replaceAll(' ₫', '');
          } else {
            amtLabel = sampleAmountLabel;
          }
          blockParts.add({'type': 'amount', 'text': amtLabel});
          break;
        case 'bank':
          String bText;
          if (_bankStyle == 'tu') {
            bText = 'từ Techcombank';
          } else if (_bankStyle == 'qua') {
            bText = 'qua Techcombank';
          } else if (_bankStyle == 'vao') {
            bText = 'vào tài khoản Techcombank';
          } else {
            bText = 'Techcombank';
          }
          blockParts.add({'type': 'bank', 'text': bText});
          break;
        case 'shopOrOrder':
          String sText;
          if (_shopStyle == 'quan') {
            sText = 'tại quán';
          } else if (_shopStyle == 'khach') {
            sText = 'khách thanh toán';
          } else {
            sText = 'đơn hàng D H 1 0 5 8';
          }
          blockParts.add({'type': 'shopOrOrder', 'text': sText});
          break;
        case 'suffix':
          if (_suffixWord.isNotEmpty && _suffixWord != 'Không đọc lời cảm ơn') {
            blockParts.add({'type': 'suffix', 'text': _suffixWord.trim()});
          }
          break;
      }
    }

    if (blockParts.isEmpty) {
      return 'Đã nhận $sampleAmountLabel';
    }

    String result = '';
    for (int i = 0; i < blockParts.length; i++) {
      final part = blockParts[i];
      final type = part['type']!;
      final text = part['text']!;

      if (result.isEmpty) {
        result = text;
      } else {
        if (result.endsWith('!')) {
          result = '$result $text';
        } else if (type == 'bank' || type == 'shopOrOrder' || type == 'suffix') {
          result = '$result, $text';
        } else {
          result = '$result $text';
        }
      }
    }

    return result.replaceAll(RegExp(r'\s+,'), ',').replaceAll(RegExp(r',+'), ',');
  }

  /// Phát thử câu đọc theo đúng Form và cấu hình giọng hiện tại
  Future<void> playSample({String sampleAmount = 'hai trăm năm mươi nghìn đồng'}) async {
    if (_isPlayingSample) {
      await stop();
      return;
    }

    _isPlayingSample = true;
    notifyListeners();

    try {
      await stop();
      await _applyTtsSettings();

      final sentence = generateSentence(
        amountWords: sampleAmount,
        bankName: 'Techcombank',
        shopOrOrder: 'đơn hàng D H 1 0 5 8',
      );

      _isPlayingSample = true;
      notifyListeners();

      await TtsService().speakSentence(
        sentence,
        onFinished: () {
          _isPlayingSample = false;
          notifyListeners();
        },
      );
    } catch (_) {
      _isPlayingSample = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await TtsService().stop();
    _isPlayingSample = false;
    notifyListeners();
  }

  /// Đồng bộ cấu hình giọng đọc lên Backend SQL
  Future<void> syncConfigToBackend(String email) async {
    try {
      final uri = Uri.parse('http://localhost:3000/api/tts/user-config');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'voiceId': _selectedVoiceId,
          'speechRate': _speechRate,
          'pitch': _pitch,
          'volume': _volume,
          'templateId': _activePresetId,
          'prefixWord': _prefixWord,
          'suffixWord': _suffixWord,
          'amountStyle': _amountStyle,
          'bankStyle': _bankStyle,
          'shopStyle': _shopStyle,
          'blocksOrder': _blocks.map((b) => b.id).toList(),
          'enabledBlocks': _blocks.where((b) => b.isEnabled).map((b) => b.id).toList(),
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}


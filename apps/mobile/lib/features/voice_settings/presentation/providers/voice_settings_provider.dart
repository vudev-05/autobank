import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../notification_listener/presentation/notification_service.dart';

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

  // Danh sách kịch bản mẫu: NHẬN TIỀN (Credit)
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

  // Danh sách kịch bản mẫu: CHUYỂN ĐI / TRỪ TIỀN (Debit)
  static const List<ReadingPreset> debitReadingPresets = [
    ReadingPreset(
      id: 'DEBIT_STANDARD',
      name: 'Chuẩn Chuyển Tiền',
      desc: 'Chuông ting + Tiền tố + Số tiền + Ngân hàng',
      icon: Icons.send_rounded,
      blockOrder: ['bell', 'prefix', 'amount', 'bank'],
      enabledBlocks: ['bell', 'prefix', 'amount', 'bank'],
    ),
    ReadingPreset(
      id: 'DEBIT_FAST',
      name: 'Siêu Nhanh Rút Gọn',
      desc: 'Đã chuyển + Số tiền (tối giản, dứt khoát)',
      icon: Icons.bolt_rounded,
      blockOrder: ['prefix', 'amount'],
      enabledBlocks: ['prefix', 'amount'],
    ),
    ReadingPreset(
      id: 'DEBIT_EXPENSE',
      name: 'Chi Tiêu Mua Sắm',
      desc: 'Thanh toán thành công + Số tiền + Mã đơn + Lời kết',
      icon: Icons.shopping_bag_rounded,
      blockOrder: ['bell', 'prefix', 'amount', 'shopOrOrder', 'suffix'],
      enabledBlocks: ['bell', 'prefix', 'amount', 'shopOrOrder', 'suffix'],
    ),
    ReadingPreset(
      id: 'DEBIT_FULL',
      name: 'Đối Soát Chi Tiết',
      desc: 'Đầy đủ chuông, số tiền, ngân hàng, nội dung chi tiết',
      icon: Icons.receipt_long_rounded,
      blockOrder: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder', 'suffix'],
      enabledBlocks: ['bell', 'prefix', 'amount', 'bank', 'shopOrOrder'],
    ),
    ReadingPreset(
      id: 'DEBIT_CUSTOM_BUILDER',
      name: 'Tự Do Sắp Xếp',
      desc: 'Tùy chỉnh thứ tự và bật/tắt mọi thành phần chuyển đi',
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

  // Bật/tắt đọc cho từng loại
  bool _isCreditEnabled = true;
  bool _isDebitEnabled = true;
  bool _isMaxVolumePhone = true; // Kích âm lượng tối đa theo điện thoại

  // Cấu hình Form đọc NHẬN TIỀN (Credit)
  String _activePresetId = 'BANK_STANDARD';
  String _prefixWord = 'Đã nhận';
  String _suffixWord = 'Cảm ơn quý khách!';
  String _amountStyle = 'dong'; // 'dong', 'vnd', 'compact', 'short_k'
  String _bankStyle = 'tu';     // 'tu' (từ...), 'qua' (qua...), 'vao' (vào tài khoản...), 'ten' (chỉ tên)
  String _shopStyle = 'don';    // 'don' (đơn hàng...), 'quan' (tại quán...), 'khach' (khách thanh toán...)
  late List<SentenceBlockItem> _blocks;

  // Cấu hình Form đọc CHUYỂN ĐI (Debit)
  String _debitActivePresetId = 'DEBIT_STANDARD';
  String _debitPrefixWord = 'Đã chuyển';
  String _debitSuffixWord = 'Giao dịch hoàn tất';
  String _debitAmountStyle = 'dong'; // 'dong', 'vnd', 'compact', 'short_k'
  String _debitBankStyle = 'qua';     // 'qua' (qua MBBank), 'tu' (từ MBBank), 'bang' (bằng MBBank), 'ten' (MBBank)
  String _debitShopStyle = 'don';    // 'don' (đơn hàng...), 'nd' (nội dung...), 'cho' (chuyển cho...)
  late List<SentenceBlockItem> _debitBlocks;

  // Getters chung
  String get selectedVoiceId => _selectedVoiceId;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  bool get isPlayingSample => _isPlayingSample;
  bool get isCreditEnabled => _isCreditEnabled;
  bool get isDebitEnabled => _isDebitEnabled;
  bool get isMaxVolumePhone => _isMaxVolumePhone;

  // Getters Nhận tiền (Credit)
  String get activePresetId => _activePresetId;
  String get prefixWord => _prefixWord;
  String get suffixWord => _suffixWord;
  String get amountStyle => _amountStyle;
  String get bankStyle => _bankStyle;
  String get shopStyle => _shopStyle;
  List<SentenceBlockItem> get blocks => List.unmodifiable(_blocks);

  // Getters Chuyển đi (Debit)
  String get debitActivePresetId => _debitActivePresetId;
  String get debitPrefixWord => _debitPrefixWord;
  String get debitSuffixWord => _debitSuffixWord;
  String get debitAmountStyle => _debitAmountStyle;
  String get debitBankStyle => _debitBankStyle;
  String get debitShopStyle => _debitShopStyle;
  List<SentenceBlockItem> get debitBlocks => List.unmodifiable(_debitBlocks);

  VoicePreset get currentPreset =>
      availablePresets.firstWhere((p) => p.id == _selectedVoiceId, orElse: () => availablePresets[0]);

  // Backward compatibility getters
  bool get readBankName => isBlockEnabled('bank');
  bool get readOrderCode => isBlockEnabled('shopOrOrder');
  bool get playChime => isBlockEnabled('bell');

  VoiceSettingsProvider() {
    _initBlocks();
    _bindToTtsService();
    scheduleMicrotask(() => _initTts());
  }

  void _bindToTtsService() {
    TtsService().isCreditReadEnabled = _isCreditEnabled;
    TtsService().isDebitReadEnabled = _isDebitEnabled;

    TtsService().globalSentenceBuilder = ({
      required String amountWords,
      String? bankName,
      String? shopOrOrder,
    }) {
      return generateSentence(
        amountWords: amountWords,
        bankName: bankName,
        shopOrOrder: shopOrOrder,
      );
    };

    TtsService().globalDebitSentenceBuilder = ({
      required String amountWords,
      String? bankName,
      String? shopOrOrder,
    }) {
      return generateDebitSentence(
        amountWords: amountWords,
        bankName: bankName,
        shopOrOrder: shopOrOrder,
      );
    };
  }

  void _initBlocks() {
    // 1. Blocks cho NHẬN TIỀN
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
        title: 'Số tiền nhận được',
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

    // 2. Blocks cho CHUYỂN ĐI
    _debitBlocks = [
      SentenceBlockItem(
        id: 'bell',
        title: 'Âm chuông Ting-Ting',
        sample: 'Ting-Ting',
        icon: Icons.notifications_active_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'prefix',
        title: 'Lời thông báo / Tiền tố',
        sample: 'Đã chuyển',
        icon: Icons.record_voice_over_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'amount',
        title: 'Số tiền chuyển / trừ',
        sample: '150.000 đồng',
        icon: Icons.payments_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'bank',
        title: 'Ngân hàng thực hiện',
        sample: 'qua Techcombank',
        icon: Icons.account_balance_rounded,
        isEnabled: true,
      ),
      SentenceBlockItem(
        id: 'shopOrOrder',
        title: 'Nội dung / Người nhận / Mã GD',
        sample: 'nội dung Mua hàng',
        icon: Icons.receipt_long_rounded,
        isEnabled: false,
      ),
      SentenceBlockItem(
        id: 'suffix',
        title: 'Lời kết / Hậu tố',
        sample: 'Giao dịch hoàn tất',
        icon: Icons.verified_rounded,
        isEnabled: false,
      ),
    ];
  }

  Future<void> _initTts() async {
    try {
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

  /// Bật / Tắt đọc khi nhận tiền (Credit)
  void toggleCreditEnabled(bool val) {
    _isCreditEnabled = val;
    TtsService().isCreditReadEnabled = val;
    notifyListeners();
  }

  /// Bật / Tắt đọc khi chuyển đi (Debit)
  void toggleDebitEnabled(bool val) {
    _isDebitEnabled = val;
    TtsService().isDebitReadEnabled = val;
    notifyListeners();
  }

  /// Khôi phục toàn bộ cài đặt âm thanh về chuẩn tối ưu ban đầu
  Future<void> resetToDefaults() async {
    final preset = currentPreset;
    _pitch = preset.defaultPitch;
    _speechRate = preset.defaultRate;
    _volume = 1.0;

    // Reset Nhận tiền (Credit)
    _isCreditEnabled = true;
    _activePresetId = 'BANK_STANDARD';
    _prefixWord = 'Đã nhận';
    _suffixWord = 'Cảm ơn quý khách!';
    _amountStyle = 'dong';
    _bankStyle = 'tu';
    _shopStyle = 'don';
    _initBlocks();

    // Reset Chuyển đi (Debit)
    _isDebitEnabled = true;
    _debitActivePresetId = 'DEBIT_STANDARD';
    _debitPrefixWord = 'Đã chuyển';
    _debitSuffixWord = 'Giao dịch hoàn tất';
    _debitAmountStyle = 'dong';
    _debitBankStyle = 'qua';
    _debitShopStyle = 'don';

    _bindToTtsService();
    await _applyTtsSettings();
    notifyListeners();
  }

  // ==================== CÁC PHƯƠNG THỨC CHO CHUYỂN ĐI (DEBIT) ====================

  void setDebitPrefixWord(String text) {
    _debitPrefixWord = text;
    notifyListeners();
  }

  void setDebitSuffixWord(String text) {
    _debitSuffixWord = text;
    notifyListeners();
  }

  void setDebitAmountStyle(String style) {
    _debitAmountStyle = style;
    notifyListeners();
  }

  void setDebitBankStyle(String style) {
    _debitBankStyle = style;
    notifyListeners();
  }

  void setDebitShopStyle(String style) {
    _debitShopStyle = style;
    notifyListeners();
  }

  void toggleDebitBlock(String blockId) {
    if (blockId == 'amount') return;
    final idx = _debitBlocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      _debitBlocks[idx].isEnabled = !_debitBlocks[idx].isEnabled;
      _debitActivePresetId = 'DEBIT_CUSTOM_BUILDER';
      notifyListeners();
    }
  }

  bool isDebitBlockEnabled(String blockId) {
    final found = _debitBlocks.firstWhere((b) => b.id == blockId, orElse: () => _debitBlocks[0]);
    return found.isEnabled;
  }

  void moveDebitBlockUp(int index) {
    if (index > 0 && index < _debitBlocks.length) {
      final item = _debitBlocks.removeAt(index);
      _debitBlocks.insert(index - 1, item);
      _debitActivePresetId = 'DEBIT_CUSTOM_BUILDER';
      notifyListeners();
    }
  }

  void moveDebitBlockDown(int index) {
    if (index >= 0 && index < _debitBlocks.length - 1) {
      final item = _debitBlocks.removeAt(index);
      _debitBlocks.insert(index + 1, item);
      _debitActivePresetId = 'DEBIT_CUSTOM_BUILDER';
      notifyListeners();
    }
  }

  void reorderDebitBlocks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _debitBlocks.removeAt(oldIndex);
    _debitBlocks.insert(newIndex, item);
    _debitActivePresetId = 'DEBIT_CUSTOM_BUILDER';
    notifyListeners();
  }

  void applyDebitReadingPreset(String presetId) {
    final preset = debitReadingPresets.firstWhere((p) => p.id == presetId, orElse: () => debitReadingPresets[0]);
    _debitActivePresetId = presetId;

    final List<SentenceBlockItem> reordered = [];
    for (final blockId in preset.blockOrder) {
      final found = _debitBlocks.firstWhere((b) => b.id == blockId, orElse: () => _debitBlocks[0]);
      found.isEnabled = preset.enabledBlocks.contains(blockId);
      reordered.add(found);
    }
    for (final b in _debitBlocks) {
      if (!reordered.any((item) => item.id == b.id)) {
        b.isEnabled = false;
        reordered.add(b);
      }
    }
    _debitBlocks = reordered;
    notifyListeners();
  }

  /// TẠO CÂU ĐỌC CHUYỂN ĐI THEO CẤU HÌNH TAB CHUYỂN ĐI
  String generateDebitSentence({
    required String amountWords,
    String? bankName,
    String? shopOrOrder,
  }) {
    final List<Map<String, String>> blockParts = [];

    for (final block in _debitBlocks) {
      if (!block.isEnabled) continue;

      switch (block.id) {
        case 'bell':
          blockParts.add({'type': 'bell', 'text': 'Ting!'});
          break;
        case 'prefix':
          if (_debitPrefixWord.isNotEmpty) {
            blockParts.add({'type': 'prefix', 'text': _debitPrefixWord.trim()});
          }
          break;
        case 'amount':
          String amt = amountWords.replaceAll(' đồng', '').trim();
          String finalAmt;
          if (_debitAmountStyle == 'dong') {
            finalAmt = '$amt đồng';
          } else if (_debitAmountStyle == 'vnd') {
            finalAmt = '$amt V N Đ';
          } else if (_debitAmountStyle == 'compact' || _debitAmountStyle == 'short_k') {
            finalAmt = amt;
          } else {
            finalAmt = '$amt đồng';
          }
          blockParts.add({'type': 'amount', 'text': finalAmt});
          break;
        case 'bank':
          if (bankName != null && bankName.isNotEmpty) {
            String bText;
            if (_debitBankStyle == 'qua') {
              bText = 'qua $bankName';
            } else if (_debitBankStyle == 'tu') {
              bText = 'từ tài khoản $bankName';
            } else if (_debitBankStyle == 'bang') {
              bText = 'bằng $bankName';
            } else {
              bText = bankName;
            }
            blockParts.add({'type': 'bank', 'text': bText});
          }
          break;
        case 'shopOrOrder':
          if (shopOrOrder != null && shopOrOrder.isNotEmpty) {
            String sText;
            if (_debitShopStyle == 'don') {
              sText = 'cho $shopOrOrder';
            } else if (_debitShopStyle == 'nd') {
              sText = 'nội dung $shopOrOrder';
            } else {
              sText = shopOrOrder;
            }
            blockParts.add({'type': 'shopOrOrder', 'text': sText});
          }
          break;
        case 'suffix':
          if (_debitSuffixWord.isNotEmpty && _debitSuffixWord != 'Không đọc lời kết') {
            blockParts.add({'type': 'suffix', 'text': _debitSuffixWord.trim()});
          }
          break;
      }
    }

    if (blockParts.isEmpty) {
      return 'Đã chuyển $amountWords đồng';
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
        } else if (type == 'amount' && result.endsWith(',')) {
          result = '$result $text';
        } else {
          result = '$result $text';
        }
      }
    }

    return result.replaceAll(RegExp(r'\s+,'), ',').replaceAll(RegExp(r',+'), ',');
  }

  /// Lấy câu đọc hoàn chỉnh trực quan để hiển thị trên UI Xem Trước cho Chuyển Đi
  String getDebitLivePreviewSentence(String sampleAmountLabel) {
    final List<Map<String, String>> blockParts = [];

    for (final block in _debitBlocks) {
      if (!block.isEnabled) continue;

      switch (block.id) {
        case 'bell':
          blockParts.add({'type': 'bell', 'text': '🔔 Ting!'});
          break;
        case 'prefix':
          if (_debitPrefixWord.isNotEmpty) {
            blockParts.add({'type': 'prefix', 'text': _debitPrefixWord.trim()});
          }
          break;
        case 'amount':
          String amtLabel;
          if (_debitAmountStyle == 'vnd') {
            amtLabel = '$sampleAmountLabel VNĐ';
          } else if (_debitAmountStyle == 'compact' || _debitAmountStyle == 'short_k') {
            amtLabel = sampleAmountLabel.replaceAll(' ₫', '');
          } else {
            amtLabel = sampleAmountLabel;
          }
          blockParts.add({'type': 'amount', 'text': amtLabel});
          break;
        case 'bank':
          String bText;
          if (_debitBankStyle == 'qua') {
            bText = 'qua MBBank';
          } else if (_debitBankStyle == 'tu') {
            bText = 'từ tài khoản MBBank';
          } else if (_debitBankStyle == 'bang') {
            bText = 'bằng MBBank';
          } else {
            bText = 'MBBank';
          }
          blockParts.add({'type': 'bank', 'text': bText});
          break;
        case 'shopOrOrder':
          String sText;
          if (_debitShopStyle == 'nd') {
            sText = 'nội dung Mua hàng';
          } else {
            sText = 'cho đơn hàng D H 1 0 5 8';
          }
          blockParts.add({'type': 'shopOrOrder', 'text': sText});
          break;
        case 'suffix':
          if (_debitSuffixWord.isNotEmpty && _debitSuffixWord != 'Không đọc lời kết') {
            blockParts.add({'type': 'suffix', 'text': _debitSuffixWord.trim()});
          }
          break;
      }
    }

    if (blockParts.isEmpty) {
      return 'Đã chuyển $sampleAmountLabel';
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

  /// Phát thử câu đọc Chuyển Đi theo đúng Form và cấu hình giọng hiện tại
  Future<void> playDebitSample({String sampleAmount = 'một trăm năm mươi nghìn đồng'}) async {
    if (_isPlayingSample) {
      await stop();
      return;
    }

    _isPlayingSample = true;
    notifyListeners();

    try {
      await stop();
      await _applyTtsSettings();

      final sentence = generateDebitSentence(
        amountWords: sampleAmount,
        bankName: 'MBBank',
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
    String? bankName,
    String? shopOrOrder,
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
      await _applyTtsSettings();

      final sentence = generateSentence(
        amountWords: sampleAmount,
        bankName: 'Techcombank',
        shopOrOrder: 'đơn hàng D H 1 0 5 8',
      );

      await TtsService().speakSentence(
        sentence,
        bypassChecks: true,
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

  Future<void> setMaxVolumePhone(bool enabled, {String? email}) async {
    _isMaxVolumePhone = enabled;
    if (enabled) {
      _volume = 1.0;
      await NotificationService.ensureMaxVolume();
      await _applyTtsSettings();
    }
    notifyListeners();
    if (email != null && email.isNotEmpty) {
      syncConfigToBackend(email);
    }
  }

  /// Tải cấu hình giọng đọc từ MySQL Database theo tài khoản đăng nhập
  Future<void> loadConfigFromBackend(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || cleanEmail == 'anonymous') return;
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/tts/user-config/$cleanEmail');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'];
          if (data['speechRate'] != null) {
            _speechRate = (data['speechRate'] as num).toDouble();
          }
          if (data['pitch'] != null) {
            _pitch = (data['pitch'] as num).toDouble();
          }
          if (data['volume'] != null) {
            _volume = (data['volume'] as num).toDouble();
          }
          if (data['isMaxVolumePhone'] != null) {
            _isMaxVolumePhone = data['isMaxVolumePhone'] == true;
          }
          if (data['isCreditEnabled'] != null) {
            _isCreditEnabled = data['isCreditEnabled'] == true;
          }
          if (data['isDebitEnabled'] != null) {
            _isDebitEnabled = data['isDebitEnabled'] == true;
          }

          // Cấu hình Nhận tiền (Credit)
          final credit = data['credit'];
          if (credit != null && credit is Map) {
            if (credit['templateId'] != null) _activePresetId = credit['templateId'].toString();
            if (credit['prefixWord'] != null) _prefixWord = credit['prefixWord'].toString();
            if (credit['suffixWord'] != null) _suffixWord = credit['suffixWord'].toString();
            if (credit['amountStyle'] != null) _amountStyle = credit['amountStyle'].toString();
            if (credit['bankStyle'] != null) _bankStyle = credit['bankStyle'].toString();
            if (credit['shopStyle'] != null) _shopStyle = credit['shopStyle'].toString();
            if (credit['blocksOrder'] is List) {
              final List<String> order = List<String>.from(credit['blocksOrder']);
              final List<String> enabled = credit['enabledBlocks'] is List
                  ? List<String>.from(credit['enabledBlocks'])
                  : [];
              final List<SentenceBlockItem> reordered = [];
              for (final bId in order) {
                final found = _blocks.firstWhere((b) => b.id == bId, orElse: () => _blocks[0]);
                found.isEnabled = (bId == 'amount') || enabled.contains(bId);
                reordered.add(found);
              }
              for (final b in _blocks) {
                if (!reordered.any((item) => item.id == b.id)) {
                  b.isEnabled = false;
                  reordered.add(b);
                }
              }
              _blocks = reordered;
            }
          }

          // Cấu hình Chuyển đi (Debit)
          final debit = data['debit'];
          if (debit != null && debit is Map) {
            if (debit['templateId'] != null) _debitActivePresetId = debit['templateId'].toString();
            if (debit['prefixWord'] != null) _debitPrefixWord = debit['prefixWord'].toString();
            if (debit['suffixWord'] != null) _debitSuffixWord = debit['suffixWord'].toString();
            if (debit['amountStyle'] != null) _debitAmountStyle = debit['amountStyle'].toString();
            if (debit['bankStyle'] != null) _debitBankStyle = debit['bankStyle'].toString();
            if (debit['shopStyle'] != null) _debitShopStyle = debit['shopStyle'].toString();
            if (debit['blocksOrder'] is List) {
              final List<String> order = List<String>.from(debit['blocksOrder']);
              final List<String> enabled = debit['enabledBlocks'] is List
                  ? List<String>.from(debit['enabledBlocks'])
                  : [];
              final List<SentenceBlockItem> reordered = [];
              for (final bId in order) {
                final found = _debitBlocks.firstWhere((b) => b.id == bId, orElse: () => _debitBlocks[0]);
                found.isEnabled = (bId == 'amount') || enabled.contains(bId);
                reordered.add(found);
              }
              for (final b in _debitBlocks) {
                if (!reordered.any((item) => item.id == b.id)) {
                  b.isEnabled = false;
                  reordered.add(b);
                }
              }
              _debitBlocks = reordered;
            }
          }

          // Khôi phục Lịch phát loa và Đọc lặp lại x2 lần theo tài khoản
          if (data['isRepeatTwice'] != null) {
            TtsService().setRepeatTwice(data['isRepeatTwice'] == true);
          }
          if (data['schedule'] != null && data['schedule'] is Map) {
            final s = data['schedule'];
            TtsService().updateSchedule(
              enabled: s['enabled'] == true,
              startHour: (s['startHour'] as num?)?.toInt(),
              startMinute: (s['startMinute'] as num?)?.toInt(),
              endHour: (s['endHour'] as num?)?.toInt(),
              endMinute: (s['endMinute'] as num?)?.toInt(),
            );
          }

          _bindToTtsService();
          await _applyTtsSettings();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Đồng bộ cấu hình giọng đọc lên Backend SQL (cả Nhận tiền và Chuyển đi)
  Future<void> syncConfigToBackend(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.isEmpty || cleanEmail == 'anonymous') return;
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/tts/user-config');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'voiceId': _selectedVoiceId,
          'speechRate': _speechRate,
          'pitch': _pitch,
          'volume': _volume,
          'isMaxVolumePhone': _isMaxVolumePhone,
          'isCreditEnabled': _isCreditEnabled,
          'isDebitEnabled': _isDebitEnabled,
          'isRepeatTwice': TtsService().isRepeatTwiceEnabled,
          'schedule': {
            'enabled': TtsService().isScheduleEnabled,
            'startHour': TtsService().scheduleStartHour,
            'startMinute': TtsService().scheduleStartMinute,
            'endHour': TtsService().scheduleEndHour,
            'endMinute': TtsService().scheduleEndMinute,
          },
          // Cấu hình Nhận tiền
          'credit': {
            'templateId': _activePresetId,
            'prefixWord': _prefixWord,
            'suffixWord': _suffixWord,
            'amountStyle': _amountStyle,
            'bankStyle': _bankStyle,
            'shopStyle': _shopStyle,
            'blocksOrder': _blocks.map((b) => b.id).toList(),
            'enabledBlocks': _blocks.where((b) => b.isEnabled).map((b) => b.id).toList(),
          },
          // Cấu hình Chuyển đi
          'debit': {
            'templateId': _debitActivePresetId,
            'prefixWord': _debitPrefixWord,
            'suffixWord': _debitSuffixWord,
            'amountStyle': _debitAmountStyle,
            'bankStyle': _debitBankStyle,
            'shopStyle': _debitShopStyle,
            'blocksOrder': _debitBlocks.map((b) => b.id).toList(),
            'enabledBlocks': _debitBlocks.where((b) => b.isEnabled).map((b) => b.id).toList(),
          },
          // Backward compatibility
          'templateId': _activePresetId,
          'prefixWord': _prefixWord,
          'suffixWord': _suffixWord,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}


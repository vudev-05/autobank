import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../domain/entities/normalized_transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/parsers/transaction_parser_factory.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionLocalDataSource _localDataSource = TransactionLocalDataSource();
  final TransactionRemoteDataSource _remoteDataSource = TransactionRemoteDataSource();
  final TransactionParserFactory _parserFactory = TransactionParserFactory();
  final TtsService _ttsService = TtsService();

  List<NormalizedTransaction> _transactions = [];
  double _todayTotal = 0.0;
  int _todayCount = 0;
  bool _isPermissionGranted = false;
  bool _isLoading = false;
  StreamSubscription? _notificationSubscription;

  // Quản lý Thông báo toàn màn hình & Sáng đèn tín hiệu khi có biến động số dư
  NormalizedTransaction? _activeAlertTransaction;
  bool _isLightStrobeActive = false;

  List<NormalizedTransaction> get transactions => _transactions;
  double get todayTotal => _todayTotal;
  int get todayCount => _todayCount;
  bool get isPermissionGranted => _isPermissionGranted;
  bool get isLoading => _isLoading;
  bool get isTtsEnabled => _ttsService.isEnabled;
  String get lastSpokenSentence => _ttsService.lastSpokenSentence;
  NormalizedTransaction? get activeAlertTransaction => _activeAlertTransaction;
  bool get isLightStrobeActive => _isLightStrobeActive;

  void triggerTransactionAlert(NormalizedTransaction tx) {
    _activeAlertTransaction = tx;
    _isLightStrobeActive = true;
    notifyListeners();

    // Tự động dịu đèn chớp sau 6 giây
    Future.delayed(const Duration(seconds: 6), () {
      if (_isLightStrobeActive) {
        _isLightStrobeActive = false;
        notifyListeners();
      }
    });
  }

  Future<void> dismissAlertAndStopTts() async {
    _activeAlertTransaction = null;
    _isLightStrobeActive = false;
    await _ttsService.stop();
    notifyListeners();
  }

  Future<void> stopTts() async {
    await _ttsService.stop();
    notifyListeners();
  }

  Future<void> updateAlertCategory(String category, {String? note}) async {
    if (_activeAlertTransaction != null) {
      final txId = _activeAlertTransaction!.id;
      await updateTransactionCategory(txId, category, note: note);
      _activeAlertTransaction = _activeAlertTransaction!.copyWith(category: category, note: note);
      notifyListeners();
    }
  }

  TransactionProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _ttsService.init();
    await checkPermission();
    await loadLocalTransactions();
    _startListeningNotificationStream();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkPermission() async {
    _isPermissionGranted = await NotificationService.isListenerEnabled();
    notifyListeners();
  }

  Future<void> loadLocalTransactions() async {
    final list = await _localDataSource.getTransactions();
    _transactions = List<NormalizedTransaction>.from(list);
    _todayTotal = await _localDataSource.getTodayTotalReceived();
    _todayCount = await _localDataSource.getTodayTransactionCount();
    notifyListeners();
  }

  void _startListeningNotificationStream() {
    _notificationSubscription?.cancel();
    _notificationSubscription = NotificationService.notificationStream.listen(
      (rawNotif) {
        processIncomingRawNotification(rawNotif);
      },
      onError: (err) {
        debugPrint('Lỗi notification stream: $err');
      },
    );
  }

  /// Xử lý một thông báo thô từ Android hoặc từ chức năng giả lập
  Future<bool> processIncomingRawNotification(Map<String, dynamic> rawNotif) async {
    final title = (rawNotif['title'] ?? '').toString();
    final text = (rawNotif['text'] ?? '').toString();
    final bigText = (rawNotif['bigText'] ?? '').toString();
    final pkg = (rawNotif['package'] ?? '').toString();

    // Ưu tiên sử dụng bigText nếu có nội dung dài hơn text
    final body = (bigText.trim().length > text.trim().length) ? bigText : text;

    final parsedTx = _parserFactory.parse(
      packageName: pkg,
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );

    if (parsedTx == null) {
      debugPrint('Không nhận diện được định dạng ngân hàng: $title - $body');
      return false;
    }

    // Chèn vào Database với cơ chế chống trùng lặp Fingerprint
    final isNew = await _localDataSource.insertTransaction(parsedTx);
    if (isNew) {
      _transactions = [parsedTx, ..._transactions];
      if (parsedTx.type.isCredit) {
        _todayTotal += parsedTx.amount;
        _todayCount += 1;

        // 1. Kích hoạt thông báo toàn màn hình & sáng đèn tín hiệu
        triggerTransactionAlert(parsedTx);

        // 2. Phát âm thanh giọng nói TTS
        await _ttsService.speakReceivedMoney(
          amount: parsedTx.amount,
          orderCode: parsedTx.orderCode,
          bankName: parsedTx.bankCode,
        );
      } else {
        // Biến động tiền ra (chi tiêu) cũng kích hoạt cảnh báo toàn màn hình để gán phân loại
        triggerTransactionAlert(parsedTx);
      }
      notifyListeners();

      // Đồng bộ bất đồng bộ lên Server MySQL qua NestJS API (không block UI)
      unawaited(_remoteDataSource.syncTransaction(parsedTx));

      return true;
    } else {
      debugPrint('Đã bỏ qua thông báo trùng lặp (Fingerprint: ${parsedTx.fingerprint})');
      return false;
    }
  }

  /// Giả lập thông báo ngân hàng (phục vụ test và demo trên máy thật / giả lập)
  Future<bool> simulateNotification({
    required String bankCode,
    required String title,
    required String body,
  }) async {
    String pkg = 'com.mbmobile';
    if (bankCode == 'VIETCOMBANK') {
      pkg = 'com.VCB';
    }

    final parsed = _parserFactory.parse(
      packageName: pkg,
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    if (parsed != null) {
      triggerTransactionAlert(parsed);
    }

    return await processIncomingRawNotification({
      'title': title,
      'text': body,
      'bigText': body,
      'package': pkg,
    });
  }

  bool get isRepeatTwiceEnabled => _ttsService.isRepeatTwiceEnabled;

  void toggleRepeatTwice() {
    _ttsService.isRepeatTwiceEnabled = !_ttsService.isRepeatTwiceEnabled;
    notifyListeners();
  }

  // Khung giờ đọc thông báo (Lịch phát loa)
  bool get isScheduleEnabled => _ttsService.isScheduleEnabled;
  int get scheduleStartHour => _ttsService.scheduleStartHour;
  int get scheduleStartMinute => _ttsService.scheduleStartMinute;
  int get scheduleEndHour => _ttsService.scheduleEndHour;
  int get scheduleEndMinute => _ttsService.scheduleEndMinute;

  void updateSchedule({
    required bool enabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    _ttsService.updateSchedule(
      enabled: enabled,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );
    notifyListeners();
  }

  // Quản lý danh mục chi tiêu cá nhân
  final List<String> _expenseCategories = [
    'Tiền ăn',
    'Tiền nhà',
    'Đi chơi',
    'Du lịch',
    'Mua sắm',
    'Tiền điện nước',
    'Xăng xe',
    'Khác',
  ];
  List<String> get expenseCategories => List.unmodifiable(_expenseCategories);

  // Quản lý Quỹ ngân sách chi tiêu hàng tháng (VND)
  final Map<String, double> _monthlyBudgets = {
    'Tiền ăn': 3000000.0,
    'Tiền nhà': 5000000.0,
    'Xăng xe': 500000.0,
    'Đi chơi': 1000000.0,
    'Mua sắm': 1500000.0,
    'Tiền điện nước': 1200000.0,
    'Du lịch': 2000000.0,
  };
  Map<String, double> get monthlyBudgets => Map.unmodifiable(_monthlyBudgets);

  void setCategoryBudget(String category, double amount) {
    if (amount <= 0) {
      _monthlyBudgets.remove(category);
    } else {
      _monthlyBudgets[category] = amount;
    }
    notifyListeners();
  }

  double getCategoryBudget(String category) {
    return _monthlyBudgets[category] ?? 0.0;
  }

  void addCustomCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_expenseCategories.contains(trimmed)) {
      _expenseCategories.add(trimmed);
      notifyListeners();
    }
  }

  Future<void> updateTransactionCategory(String txId, String category, {String? note}) async {
    await _localDataSource.updateTransactionCategory(txId, category, note: note);
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx != -1) {
      _transactions[idx] = _transactions[idx].copyWith(category: category, note: note);
      notifyListeners();
    }
  }

  Future<void> addManualTransaction({
    required double amount,
    required TransactionType type,
    required String content,
    String? category,
    String? note,
    String bankCode = 'TIỀN MẶT',
    DateTime? transactionTime,
  }) async {
    final now = transactionTime ?? DateTime.now();
    final newTx = NormalizedTransaction(
      id: 'manual_${now.millisecondsSinceEpoch}',
      bankCode: bankCode,
      accountNumber: 'Ví cá nhân',
      amount: amount,
      type: type,
      content: content,
      category: category,
      note: note,
      transactionTime: now,
      rawContent: 'Ghi chép thủ công: $content',
    );
    await _localDataSource.insertTransaction(newTx);
    _transactions = [newTx, ..._transactions];
    if (type.isCredit) {
      _todayTotal += amount;
      _todayCount += 1;
    }
    notifyListeners();
  }

  Future<void> replayLastSentence() async {
    await _ttsService.replayLastSentence();
  }

  void toggleTts(bool value) {
    _ttsService.isEnabled = value;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _localDataSource.clearAll();
    _transactions.clear();
    _todayTotal = 0.0;
    _todayCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

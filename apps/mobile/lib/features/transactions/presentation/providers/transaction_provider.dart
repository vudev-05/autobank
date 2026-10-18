import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
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

  // Tài khoản hiện tại được đồng bộ
  String? _currentUserEmail;
  String? get currentUserEmail => _currentUserEmail;

  // Quản lý trạng thái bản quyền / gói cước của tài khoản
  bool _isPlanActive = true;
  bool get isPlanActive => _isPlanActive;

  void updatePlanStatus({required bool isActive}) {
    _isPlanActive = isActive;
    if (!isActive && _ttsService.isEnabled) {
      _ttsService.isEnabled = false;
    }
    notifyListeners();
  }

  // Quản lý Thông báo toàn màn hình & Sáng đèn tín hiệu khi có biến động số dư
  NormalizedTransaction? _activeAlertTransaction;
  bool _isLightStrobeActive = false;

  /// Callback khi có giao dịch mới (hỗ trợ đẩy thông báo vào Notification Center)
  Function(NormalizedTransaction tx)? onTransactionReceived;

  List<NormalizedTransaction> get transactions => _transactions;
  double get todayTotal => _todayTotal;
  int get todayCount => _todayCount;
  bool get isPermissionGranted => _isPermissionGranted;
  bool get isLoading => _isLoading;
  bool get isTtsEnabled => _ttsService.isEnabled;
  String get lastSpokenSentence => _ttsService.lastSpokenSentence;
  String get lastBankTransactionSentence => _ttsService.lastBankTransactionSentence;
  NormalizedTransaction? get activeAlertTransaction => _activeAlertTransaction;
  bool get isLightStrobeActive => _isLightStrobeActive;

  bool _isDimmedScreenActive = false;
  bool get isDimmedScreenActive => _isDimmedScreenActive;

  void setDimmedScreenActive(bool active) {
    _isDimmedScreenActive = active;
    notifyListeners();
  }

  /// Trả về câu thông báo ngân hàng vừa nhận về gần nhất
  String get latestBankSentence {
    if (_ttsService.lastBankTransactionSentence.isNotEmpty) {
      return _ttsService.lastBankTransactionSentence;
    }
    if (_transactions.isNotEmpty) {
      final latest = _transactions.first;
      final amt = CurrencyFormatter.formatWords(latest.amount);
      if (latest.type.isCredit) {
        return 'Đã nhận $amt đồng từ ${latest.bankCode}';
      } else {
        return 'Đã chuyển $amt đồng qua ${latest.bankCode}';
      }
    }
    return '';
  }

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
    scheduleMicrotask(() => init());
  }

  // Quản lý tự động reset doanh thu vào 0h sáng múi giờ Việt Nam (UTC+7)
  Timer? _midnightTimer;
  int? _lastRecordedVietnamDay;

  Future<void> init() async {
    try {
      _isLoading = true;
      await _ttsService.init();
      await checkPermission();
      await loadLocalTransactions();
      _startListeningNotificationStream();
      _setupMidnightTimer();
    } catch (e, st) {
      debugPrint('[AutoBank] Lỗi khởi tạo TransactionProvider: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tự động thiết lập đồng hồ đếm ngược reset doanh thu hôm nay vào 0h00 sáng giờ Việt Nam
  void _setupMidnightTimer() {
    _midnightTimer?.cancel();
    _lastRecordedVietnamDay = DateTime.now().toUtc().add(const Duration(hours: 7)).day;
    // Kiểm tra định kỳ mỗi phút để reset chính xác khi bước sang ngày mới
    _midnightTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkMidnightReset();
    });
  }

  /// Kiểm tra nếu đã bước qua 0h sáng giờ Việt Nam thì đặt lại số tiền và số đơn về 0
  Future<void> checkMidnightReset() async {
    try {
      final nowVN = DateTime.now().toUtc().add(const Duration(hours: 7));
      if (_lastRecordedVietnamDay != null && _lastRecordedVietnamDay != nowVN.day) {
        debugPrint('[AutoBank] Đã sang ngày mới theo giờ Việt Nam (${nowVN.day}/${nowVN.month}/${nowVN.year}). Tự động reset doanh thu hôm nay về 0đ!');
        _lastRecordedVietnamDay = nowVN.day;
        _todayTotal = await _localDataSource.getTodayTotalReceived();
        _todayCount = await _localDataSource.getTodayTransactionCount();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> checkPermission() async {
    try {
      _isPermissionGranted = await NotificationService.isListenerEnabled();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadLocalTransactions() async {
    try {
      _lastRecordedVietnamDay = DateTime.now().toUtc().add(const Duration(hours: 7)).day;
      final list = await _localDataSource.getTransactions();
      _transactions = List<NormalizedTransaction>.from(list);
      _todayTotal = await _localDataSource.getTodayTotalReceived();
      _todayCount = await _localDataSource.getTodayTransactionCount();
      notifyListeners();
    } catch (e) {
      debugPrint('[AutoBank] Lỗi nạp loadLocalTransactions: $e');
    }
  }

  /// Tải toàn bộ giao dịch và cài đặt ngân sách của tài khoản đăng nhập từ MySQL về máy
  Future<void> syncAccountTransactions(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;
    _currentUserEmail = cleanEmail;
    await _loadUserBudgetsAndCategories(cleanEmail);

    try {
      // 1. Xóa sạch dữ liệu cục bộ trước khi đồng bộ để đảm bảo chính xác 100% với dữ liệu mới nhất trên MySQL
      await _localDataSource.clearAll();
      _transactions.clear();
      _todayTotal = 0.0;
      _todayCount = 0;

      final remoteList = await _remoteDataSource.fetchTransactionsByUser(cleanEmail);
      if (remoteList.isNotEmpty) {
        for (final rTx in remoteList) {
          await _localDataSource.insertTransaction(rTx);
        }
      }
      await loadLocalTransactions();
    } catch (e) {
      debugPrint('Lỗi tải giao dịch tài khoản $cleanEmail: $e');
    }
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

  // Cache chống trùng lặp giao dịch trong 6 giây (triệt tiêu sự kiện duplicate từ Android OS / Bank updates)
  final Map<String, DateTime> _recentTxCooldownMap = {};

  /// Xử lý một thông báo thô từ Android hoặc từ chức năng giả lập demo
  Future<bool> processIncomingRawNotification(
    Map<String, dynamic> rawNotif, {
    bool isDemo = false,
  }) async {
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

    // NẾU LÀ DEMO (BẮN THỬ TEST THÔNG BÁO):
    // CHỈ PHÁT LOA VÀ HIỂN THỊ POPUP, TUYỆT ĐỐI KHÔNG CỘNG TIỀN, KHÔNG LƯU VÀO DATABASE LOCAL, KHÔNG SYNC LÊN SERVER MYSQL
    if (isDemo) {
      debugPrint('[Demo Test] Đang kích hoạt thử thông báo & đọc loa demo (KHÔNG cộng tiền, KHÔNG lưu SQL)');
      triggerTransactionAlert(parsedTx);

      if (parsedTx.type.isCredit) {
        await _ttsService.speakReceivedMoney(
          amount: parsedTx.amount,
          orderCode: parsedTx.orderCode,
          bankName: parsedTx.bankCode,
          bypassChecks: true,
        );
      } else {
        await _ttsService.speakDebitMoney(
          amount: parsedTx.amount,
          orderCode: parsedTx.orderCode,
          bankName: parsedTx.bankCode,
          bypassChecks: true,
        );
      }
      return true;
    }

    // DƯỚI ĐÂY LÀ GIAO DỊCH THẬT TỪ HỆ THỐNG / APP NGÂN HÀNG:
    // Chống trùng lặp mức ứng dụng (Semantic Deduplication trong 6 giây)
    final semanticKey = '${parsedTx.bankCode}_${parsedTx.amount.toInt()}_${parsedTx.type.name}';
    final now = DateTime.now();
    final lastSeen = _recentTxCooldownMap[semanticKey];
    if (lastSeen != null && now.difference(lastSeen).inSeconds < 6) {
      debugPrint('Đã triệt tiêu thông báo ngân hàng bị bắn lặp lại trong 6 giây: $semanticKey');
      return false;
    }
    _recentTxCooldownMap[semanticKey] = now;

    // Dọn dẹp cache
    if (_recentTxCooldownMap.length > 50) {
      _recentTxCooldownMap.removeWhere((_, time) => now.difference(time).inSeconds > 30);
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

        // 2. Phát âm thanh giọng nói TTS theo mẫu câu đã cấu hình (khóa đọc tự động nếu gói đã hết hạn)
        if (_isPlanActive) {
          await _ttsService.speakReceivedMoney(
            amount: parsedTx.amount,
            orderCode: parsedTx.orderCode,
            bankName: parsedTx.bankCode,
          );
        } else {
          debugPrint('Gói cước đã hết hạn, tạm khóa đọc thông báo nhận tiền tự động.');
        }
      } else {
        // Biến động tiền ra (chi tiêu/trừ tiền): kích hoạt cảnh báo toàn màn hình & phát âm thanh giọng nói TTS
        triggerTransactionAlert(parsedTx);

        if (_isPlanActive) {
          await _ttsService.speakDebitMoney(
            amount: parsedTx.amount,
            orderCode: parsedTx.orderCode,
            bankName: parsedTx.bankCode,
          );
        } else {
          debugPrint('Gói cước đã hết hạn, tạm khóa đọc thông báo chuyển tiền tự động.');
        }
      }
      notifyListeners();

      // Kích hoạt callback giao dịch mới
      try {
        onTransactionReceived?.call(parsedTx);
      } catch (_) {}

      // Đồng bộ bất đồng bộ lên Server MySQL qua NestJS API (kèm user email của tài khoản)
      unawaited(_remoteDataSource.syncTransaction(parsedTx, userEmail: _currentUserEmail));

      return true;
    } else {
      debugPrint('Đã bỏ qua thông báo trùng lặp (Fingerprint: ${parsedTx.fingerprint})');
      return false;
    }
  }

  /// Giả lập thông báo ngân hàng (phục vụ test và demo trên máy thật / giả lập)
  /// Mặc định isDemo = true: chỉ phát âm thanh và hiển thị pop-up, KHÔNG cộng tiền vào doanh thu, KHÔNG lưu vào SQL
  Future<bool> simulateNotification({
    required String bankCode,
    required String title,
    required String body,
    bool isDemo = true,
  }) async {
    String pkg = 'com.mbmobile';
    if (bankCode == 'VIETCOMBANK') {
      pkg = 'com.VCB';
    }

    return await processIncomingRawNotification({
      'title': title,
      'text': body,
      'bigText': body,
      'package': pkg,
    }, isDemo: isDemo);
  }

  bool get isRepeatTwiceEnabled => _ttsService.isRepeatTwiceEnabled;

  void toggleRepeatTwice() {
    _ttsService.setRepeatTwice(!_ttsService.isRepeatTwiceEnabled);
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

  Future<void> _loadUserBudgetsAndCategories(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetStr = prefs.getString('autobank_budgets_$email');
      if (budgetStr != null && budgetStr.isNotEmpty) {
        final decoded = jsonDecode(budgetStr);
        if (decoded is Map) {
          _monthlyBudgets.clear();
          decoded.forEach((k, v) {
            _monthlyBudgets[k.toString()] = (v as num).toDouble();
          });
        }
      }
      final catStr = prefs.getString('autobank_categories_$email');
      if (catStr != null && catStr.isNotEmpty) {
        final decoded = jsonDecode(catStr);
        if (decoded is List) {
          for (final c in decoded) {
            final catName = c.toString().trim();
            if (catName.isNotEmpty && !_expenseCategories.contains(catName)) {
              _expenseCategories.add(catName);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveUserBudgetsAndCategories() async {
    final email = _currentUserEmail ?? 'guest';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('autobank_budgets_$email', jsonEncode(_monthlyBudgets));
      await prefs.setString('autobank_categories_$email', jsonEncode(_expenseCategories));
    } catch (_) {}
  }

  void setCategoryBudget(String category, double amount) {
    if (amount <= 0) {
      _monthlyBudgets.remove(category);
    } else {
      _monthlyBudgets[category] = amount;
    }
    _saveUserBudgetsAndCategories();
    notifyListeners();
  }

  double getCategoryBudget(String category) {
    return _monthlyBudgets[category] ?? 0.0;
  }

  void addCustomCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_expenseCategories.contains(trimmed)) {
      _expenseCategories.add(trimmed);
      _saveUserBudgetsAndCategories();
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

    // Đồng bộ giao dịch thủ công lên MySQL của tài khoản
    unawaited(_remoteDataSource.syncTransaction(newTx, userEmail: _currentUserEmail));
  }

  /// Tùy chỉnh thêm (+) hoặc trừ (-) doanh thu hôm nay để người dùng dễ dàng điều chỉnh khi có sai sót
  Future<void> adjustTodayRevenue({
    required double amount,
    required bool isAddition,
    String? note,
  }) async {
    final now = DateTime.now();
    final cleanNote = (note != null && note.trim().isNotEmpty)
        ? note.trim()
        : (isAddition ? 'Điều chỉnh cộng thêm doanh thu' : 'Điều chỉnh giảm trừ sai lệch doanh thu');

    final newTx = NormalizedTransaction(
      id: 'adj_${now.millisecondsSinceEpoch}',
      bankCode: 'ĐIỀU CHỈNH',
      accountNumber: 'Sổ cái nội bộ',
      amount: amount,
      type: isAddition ? TransactionType.credit : TransactionType.debit,
      content: isAddition ? 'Điều chỉnh (+) $cleanNote' : 'Điều chỉnh (-) $cleanNote',
      category: 'Khác',
      note: cleanNote,
      transactionTime: now,
      rawContent: 'Điều chỉnh số liệu: ${isAddition ? '+' : '-'}${CurrencyFormatter.formatVND(amount)} ($cleanNote)',
    );

    await _localDataSource.insertTransaction(newTx);
    _transactions = [newTx, ..._transactions];

    if (isAddition) {
      _todayTotal += amount;
      _todayCount += 1;
    } else {
      _todayTotal = (_todayTotal - amount).clamp(0.0, double.infinity);
      if (_todayCount > 0 && _todayTotal == 0.0) {
        // Nếu trừ hết về 0 thì cập nhật count tương ứng
      }
    }
    notifyListeners();

    unawaited(_remoteDataSource.syncTransaction(newTx, userEmail: _currentUserEmail));
  }

  Future<void> replayLastSentence() async {
    if (!_isPlanActive) return;
    await _ttsService.replayLastSentence();
  }

  void toggleTts(bool value) {
    if (value && !_isPlanActive) {
      _ttsService.isEnabled = false;
      notifyListeners();
      return;
    }
    _ttsService.isEnabled = value;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final txToDelete = _transactions.cast<NormalizedTransaction?>().firstWhere(
      (t) => t?.id == id,
      orElse: () => null,
    );
    final fingerprint = txToDelete?.fingerprint;

    await _localDataSource.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    _todayTotal = await _localDataSource.getTodayTotalReceived();
    _todayCount = await _localDataSource.getTodayTransactionCount();
    notifyListeners();

    // Đồng bộ xóa vĩnh viễn trên MySQL server
    unawaited(_remoteDataSource.deleteTransaction(id, userEmail: _currentUserEmail));
    if (fingerprint != null && fingerprint.isNotEmpty && fingerprint != id) {
      unawaited(_remoteDataSource.deleteTransaction(fingerprint, userEmail: _currentUserEmail));
    }
  }

  Future<void> clearHistory() async {
    await _localDataSource.clearAll();
    _transactions.clear();
    _todayTotal = 0.0;
    _todayCount = 0;
    notifyListeners();

    if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
      unawaited(_remoteDataSource.clearAllTransactions(_currentUserEmail!));
    }
  }

  /// Làm sạch dữ liệu giao dịch khi đăng xuất tài khoản
  void clearOnLogout() {
    _currentUserEmail = null;
    _transactions.clear();
    _todayTotal = 0.0;
    _todayCount = 0;
    _activeAlertTransaction = null;
    _localDataSource.clearAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

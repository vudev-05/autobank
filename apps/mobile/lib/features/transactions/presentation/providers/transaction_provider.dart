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
    if (isActive) {
      _ttsService.isEnabled = true;
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

  void dismissTransactionAlert() {
    _activeAlertTransaction = null;
    _isLightStrobeActive = false;
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

  // Quản lý tự động reset doanh thu vào 0h00 sáng (12h đêm)
  Timer? _midnightTimer;
  Timer? _midnightPrecisionTimer;
  int? _lastRecordedVietnamDay;

  // Hàng đợi phát âm thanh TTS khi có mạng trở lại hoặc nhận nhiều thông báo dồn dập
  final List<NormalizedTransaction> _speechQueue = [];
  bool _isSpeakingQueueRunning = false;

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

  /// Tự động thiết lập đồng hồ đếm ngược reset doanh thu hôm nay vào đúng chuẩn 12h đêm (00:00:00)
  void _setupMidnightTimer() {
    _midnightTimer?.cancel();
    _midnightPrecisionTimer?.cancel();
    final now = DateTime.now();
    _lastRecordedVietnamDay = now.day;

    // 1. Tính toán thời gian còn lại đến chính xác 00:00:01 của ngày hôm sau
    final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    final durationUntilMidnight = tomorrowMidnight.difference(now);

    _midnightPrecisionTimer = Timer(durationUntilMidnight, () async {
      await checkMidnightReset();
      _setupMidnightTimer(); // Lên lịch chính xác cho đêm tiếp theo
    });

    // 2. Định kỳ quét mỗi 10 giây để đảm bảo nếu máy tắt màn hình/ngủ sâu tỉnh dậy thì reset ngay lập tức
    _midnightTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkMidnightReset();
    });
  }

  /// Kiểm tra nếu đã bước qua 12h đêm (00:00:00) thì tự động đặt lại doanh thu hôm nay về 0đ
  Future<void> checkMidnightReset() async {
    try {
      final now = DateTime.now();
      if (_lastRecordedVietnamDay != null && _lastRecordedVietnamDay != now.day) {
        debugPrint('[AutoBank] Đã sang ngày mới (${now.day}/${now.month}/${now.year}). Tự động reset doanh thu hôm nay về đúng 0đ!');
        _lastRecordedVietnamDay = now.day;
        _todayTotal = await _localDataSource.getTodayTotalReceived();
        _todayCount = await _localDataSource.getTodayTransactionCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AutoBank] Lỗi checkMidnightReset: $e');
    }
  }

  Future<void> checkPermission() async {
    try {
      _isPermissionGranted = await NotificationService.isListenerEnabled();
      notifyListeners();
    } catch (_) {}
  }

  /// Tự động âm thầm đồng bộ các giao dịch offline (chưa đồng bộ) lên VPS khi có mạng
  Future<int> syncPendingOfflineTransactions() async {
    if (kIsWeb || _currentUserEmail == null || _currentUserEmail!.isEmpty) return 0;
    try {
      final unsynced = await _localDataSource.getUnsyncedTransactions();
      if (unsynced.isEmpty) return 0;

      int syncedCount = 0;
      for (final tx in unsynced) {
        final success = await _remoteDataSource.syncTransaction(tx, userEmail: _currentUserEmail);
        if (success) {
          await _localDataSource.markTransactionSynced(tx.id);
          syncedCount++;
        }
      }
      if (syncedCount > 0) {
        debugPrint('[AutoBank Offline Queue] Đã tự động đồng bộ ngầm $syncedCount giao dịch lên máy chủ VPS');
      }
      return syncedCount;
    } catch (e) {
      debugPrint('[AutoBank Offline Queue] Lỗi đồng bộ ngầm: $e');
      return 0;
    }
  }

  Future<void> loadLocalTransactions() async {
    try {
      _lastRecordedVietnamDay = DateTime.now().toUtc().add(const Duration(hours: 7)).day;
      final list = await _localDataSource.getTransactions();
      _transactions = List<NormalizedTransaction>.from(list);
      _todayTotal = await _localDataSource.getTodayTotalReceived();
      _todayCount = await _localDataSource.getTodayTransactionCount();
      notifyListeners();

      // Tự động quét và đẩy các giao dịch offline nếu có kết nối mạng
      unawaited(syncPendingOfflineTransactions());
    } catch (e) {
      debugPrint('[AutoBank] Lỗi nạp loadLocalTransactions: $e');
    }
  }

  /// Tải toàn bộ giao dịch và cài đặt ngân sách của tài khoản đăng nhập từ MySQL về máy
  Future<void> syncAccountTransactions(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;
    
    // Nếu chuyển đổi sang tài khoản khác, làm sạch cache local cũ để đảm bảo cách ly 100% dữ liệu
    if (_currentUserEmail != null && _currentUserEmail != cleanEmail) {
      await _localDataSource.clearAll();
      _transactions.clear();
      _todayTotal = 0.0;
      _todayCount = 0;
    }
    _currentUserEmail = cleanEmail;
    await _loadUserBudgetsAndCategories(cleanEmail);

    try {
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
    // Kiểm tra xem đã qua 12h đêm (00:00:00) chưa trước khi tính toán
    await checkMidnightReset();

    // Chống trùng lặp mức ứng dụng: chỉ triệt tiêu nếu thông báo y hệt từng chi tiết bắn lặp trong 1.5 giây do Android OS
    final cleanOrder = (parsedTx.orderCode ?? '').trim().toLowerCase();
    final cleanContentHash = parsedTx.content.trim().toLowerCase().hashCode;
    final semanticKey = '${parsedTx.bankCode}_${parsedTx.amount.toInt()}_${parsedTx.type.name}_${cleanOrder}_$cleanContentHash';
    final now = DateTime.now();
    final lastSeen = _recentTxCooldownMap[semanticKey];
    if (lastSeen != null && now.difference(lastSeen).inMilliseconds < 1500) {
      debugPrint('Đã triệt tiêu thông báo ngân hàng bị bắn lặp lại bởi Android OS trong 1.5s: $semanticKey');
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

      // ĐỒNG BỘ NGAY LẬP TỨC LÊN SERVER MYSQL QUA NESTJS API TRƯỚC KHI ĐỌC LOA
      // Giúp trang Web Live nhận tín hiệu SSE và phát loa đồng thời ngay lập tức cùng lúc với điện thoại (0s delay)
      unawaited(_remoteDataSource.syncTransaction(parsedTx, userEmail: _currentUserEmail));

      // Kiểm tra chuẩn ngày theo múi giờ địa phương của máy
      final txTimeLocal = parsedTx.transactionTime.toLocal();
      final isTodayTx = txTimeLocal.year == now.year && txTimeLocal.month == now.month && txTimeLocal.day == now.day;

      if (parsedTx.type.isCredit) {
        if (isTodayTx) {
          _todayTotal += parsedTx.amount;
          _todayCount += 1;
        }

        // Đưa vào hàng đợi phát âm thanh và hiển thị cảnh báo (không bị nuốt câu khi có mạng thông báo dồn)
        _enqueueSpeech(parsedTx);
      } else {
        // Biến động tiền ra (chi tiêu/trừ tiền)
        _enqueueSpeech(parsedTx);
      }
      notifyListeners();

      // Kích hoạt callback giao dịch mới
      try {
        onTransactionReceived?.call(parsedTx);
      } catch (_) {}

      return true;
    } else {
      debugPrint('Đã bỏ qua thông báo trùng lặp (Fingerprint: ${parsedTx.fingerprint})');
      return false;
    }
  }

  /// Đưa giao dịch vào hàng đợi âm thanh TTS để đọc lần lượt từng câu rõ ràng khi có mạng lại thông báo dồn dập
  void _enqueueSpeech(NormalizedTransaction tx) {
    _speechQueue.add(tx);
    if (!_isSpeakingQueueRunning) {
      _processNextInSpeechQueue();
    }
  }

  Future<void> _processNextInSpeechQueue() async {
    if (_speechQueue.isEmpty) {
      _isSpeakingQueueRunning = false;
      return;
    }
    _isSpeakingQueueRunning = true;
    final tx = _speechQueue.removeAt(0);

    try {
      // 1. Kích hoạt thông báo toàn màn hình, đánh thức màn hình sáng & loa lớn
      triggerTransactionAlert(tx);
      NotificationService.wakeUpScreen();
      await NotificationService.ensureMaxVolume();

      // 2. Phát âm thanh giọng nói TTS theo mẫu câu đã cấu hình (luôn đọc rõ ràng khi có tiền về)
      if (tx.type.isCredit) {
        await _ttsService.speakReceivedMoney(
          amount: tx.amount,
          orderCode: tx.orderCode,
          bankName: tx.bankCode,
          bypassChecks: true,
        );
      } else {
        await _ttsService.speakDebitMoney(
          amount: tx.amount,
          orderCode: tx.orderCode,
          bankName: tx.bankCode,
          bypassChecks: true,
        );
      }
    } catch (e) {
      debugPrint('[AutoBank Queue] Lỗi đọc giọng nói TTS: $e');
    }

    // Tạm dừng 400ms giữa các câu đọc dồn dập
    await Future.delayed(const Duration(milliseconds: 400));
    _processNextInSpeechQueue();
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

  // 1. QUỸ NGÂN SÁCH DOANH NGHIỆP (Business Funds)
  final Map<String, double> _businessBudgets = {
    'Quỹ Nhập hàng': 20000000.0,
    'Quỹ Mặt bằng & Vận hành': 10000000.0,
    'Quỹ Lương nhân viên': 15000000.0,
    'Quỹ Dự phòng & Thuế': 5000000.0,
  };
  Map<String, double> get businessBudgets => Map.unmodifiable(_businessBudgets);

  // 2. QUỸ NGÂN SÁCH CÁ NHÂN (Personal Funds)
  final Map<String, double> _personalBudgets = {
    'Tiền ăn': 3000000.0,
    'Tiền nhà': 5000000.0,
    'Xăng xe': 500000.0,
    'Đi chơi': 1000000.0,
    'Mua sắm': 1500000.0,
    'Tiền điện nước': 1200000.0,
  };
  Map<String, double> get personalBudgets => Map.unmodifiable(_personalBudgets);

  // Khả năng tương thích ngược
  Map<String, double> get monthlyBudgets => Map.unmodifiable(_personalBudgets);

  // 3. THỜI GIAN HIỂN THỊ THÔNG BÁO NHẬN TIỀN (Mặc định 10 giây nếu chưa cấu hình)
  int _alertDisplayDurationSeconds = 10;
  int get alertDisplayDurationSeconds => _alertDisplayDurationSeconds;

  Future<void> _loadUserBudgetsAndCategories(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Đọc thời gian hiển thị thông báo nhận tiền (mặc định 10s)
      _alertDisplayDurationSeconds = prefs.getInt('autobank_alert_duration_seconds') ?? 10;
      if (_alertDisplayDurationSeconds < 3) _alertDisplayDurationSeconds = 10;

      // Đọc Quỹ Doanh Nghiệp
      final bizBudgetStr = prefs.getString('autobank_biz_budgets_$email');
      if (bizBudgetStr != null && bizBudgetStr.isNotEmpty) {
        final decoded = jsonDecode(bizBudgetStr);
        if (decoded is Map) {
          _businessBudgets.clear();
          decoded.forEach((k, v) {
            _businessBudgets[k.toString()] = (v as num).toDouble();
          });
        }
      }

      // Đọc Quỹ Cá Nhân (nếu chưa có thì đọc autobank_budgets_$email cũ)
      final personalBudgetStr = prefs.getString('autobank_personal_budgets_$email') ?? prefs.getString('autobank_budgets_$email');
      if (personalBudgetStr != null && personalBudgetStr.isNotEmpty) {
        final decoded = jsonDecode(personalBudgetStr);
        if (decoded is Map) {
          _personalBudgets.clear();
          decoded.forEach((k, v) {
            _personalBudgets[k.toString()] = (v as num).toDouble();
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

  Future<void> setAlertDisplayDuration(int seconds) async {
    _alertDisplayDurationSeconds = seconds > 0 ? seconds : 10;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('autobank_alert_duration_seconds', _alertDisplayDurationSeconds);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveUserBudgetsAndCategories() async {
    final email = _currentUserEmail ?? 'guest';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('autobank_biz_budgets_$email', jsonEncode(_businessBudgets));
      await prefs.setString('autobank_personal_budgets_$email', jsonEncode(_personalBudgets));
      await prefs.setString('autobank_categories_$email', jsonEncode(_expenseCategories));
    } catch (_) {}
  }

  // --- QUẢN LÝ QUỸ DOANH NGHIỆP (CRUD) ---
  void setBusinessBudget(String name, double amount) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (amount <= 0) {
      _businessBudgets.remove(clean);
    } else {
      _businessBudgets[clean] = amount;
    }
    _saveUserBudgetsAndCategories();
    notifyListeners();
  }

  void deleteBusinessBudget(String name) {
    _businessBudgets.remove(name);
    _saveUserBudgetsAndCategories();
    notifyListeners();
  }

  void renameBusinessBudget(String oldName, String newName, double amount) {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    _businessBudgets.remove(oldName);
    _businessBudgets[clean] = amount > 0 ? amount : 1000000.0;
    _saveUserBudgetsAndCategories();
    notifyListeners();
  }

  // --- QUẢN LÝ QUỸ CÁ NHÂN (CRUD) ---
  void setPersonalBudget(String name, double amount) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (amount <= 0) {
      _personalBudgets.remove(clean);
    } else {
      _personalBudgets[clean] = amount;
    }
    _saveUserBudgetsAndCategories();
    notifyListeners();
  }

  void deletePersonalBudget(String name) {
    _personalBudgets.remove(name);
    _saveUserBudgetsAndCategories();
    notifyListeners();
  }

  void renamePersonalBudget(String oldName, String newName, double amount) {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    _personalBudgets.remove(oldName);
    _personalBudgets[clean] = amount > 0 ? amount : 1000000.0;
    _saveUserBudgetsAndCategories();
    notifyListeners();
  }

  // Compatibility methods
  void setCategoryBudget(String category, double amount) => setPersonalBudget(category, amount);
  void updateBudget(String category, double amount) {
    if (_businessBudgets.containsKey(category)) {
      setBusinessBudget(category, amount);
    } else {
      setPersonalBudget(category, amount);
    }
  }
  void deleteCategoryBudget(String category) {
    deleteBusinessBudget(category);
    deletePersonalBudget(category);
  }
  double getCategoryBudget(String category) {
    return _businessBudgets[category] ?? _personalBudgets[category] ?? 0.0;
  }

  void addCustomCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_expenseCategories.contains(trimmed)) {
      _expenseCategories.add(trimmed);
      _saveUserBudgetsAndCategories();
      notifyListeners();
    }
  }

  void addCustomFund({required String name, required double budgetAmount, bool isBusiness = false}) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    if (isBusiness) {
      setBusinessBudget(cleanName, budgetAmount);
    } else {
      if (!_expenseCategories.contains(cleanName)) {
        _expenseCategories.add(cleanName);
      }
      setPersonalBudget(cleanName, budgetAmount);
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

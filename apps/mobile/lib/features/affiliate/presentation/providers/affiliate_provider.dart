import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

class AffiliateHistoryItem {
  final String id;
  final String title;
  final String date;
  final double amount;
  final String status; // 'Thành công', 'Đang xử lý', 'Chờ duyệt'

  AffiliateHistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'amount': amount,
    'status': status,
  };

  factory AffiliateHistoryItem.fromJson(Map<String, dynamic> json) => AffiliateHistoryItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    date: json['date'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] ?? 'Thành công',
  );
}

class WithdrawalRequestItem {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final double amount;
  final String date;
  final String status; // 'Chờ xử lý', 'Đã chuyển tiền', 'Từ chối'

  WithdrawalRequestItem({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.amount,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountHolder': accountHolder,
    'amount': amount,
    'date': date,
    'status': status,
  };

  factory WithdrawalRequestItem.fromJson(Map<String, dynamic> json) => WithdrawalRequestItem(
    id: json['id'] ?? '',
    bankName: json['bankName'] ?? '',
    accountNumber: json['accountNumber'] ?? '',
    accountHolder: json['accountHolder'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    date: json['date'] ?? '',
    status: json['status'] ?? 'Chờ xử lý',
  );
}

class AffiliateProvider extends ChangeNotifier {
  String _myReferralCode = '';
  String _savedReferredByCode = '';
  double _availableBalance = 0.0;
  double _pendingBalance = 0.0;
  int _invitedCount = 0;

  List<AffiliateHistoryItem> _incomeHistory = [];
  List<WithdrawalRequestItem> _withdrawalHistory = [];

  String get myReferralCode => _myReferralCode;
  String get savedReferredByCode => _savedReferredByCode;
  double get availableBalance => _availableBalance;
  double get pendingBalance => _pendingBalance;
  int get invitedCount => _invitedCount;
  List<AffiliateHistoryItem> get incomeHistory => List.unmodifiable(_incomeHistory);
  List<WithdrawalRequestItem> get withdrawalHistory => List.unmodifiable(_withdrawalHistory);

  AffiliateProvider() {
    _loadAffiliateData();
  }

  Future<void> _loadAffiliateData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Tạo mã giới thiệu 6 số ngẫu nhiên cố định nếu chưa có
      var code = prefs.getString('user_referral_code');
      if (code == null || code.length != 6) {
        final rand = Random();
        code = (rand.nextInt(900000) + 100000).toString();
        await prefs.setString('user_referral_code', code);
      }
      _myReferralCode = code;

      _savedReferredByCode = prefs.getString('saved_referred_by_code') ?? '';
      _availableBalance = prefs.getDouble('affiliate_available_balance') ?? 0.0;
      _pendingBalance = prefs.getDouble('affiliate_pending_balance') ?? 0.0;
      _invitedCount = prefs.getInt('affiliate_invited_count') ?? 0;

      final historyJson = prefs.getString('affiliate_income_history');
      if (historyJson != null) {
        final List list = jsonDecode(historyJson);
        _incomeHistory = list.map((e) => AffiliateHistoryItem.fromJson(e)).toList();
      }

      final withdrawJson = prefs.getString('affiliate_withdraw_history');
      if (withdrawJson != null) {
        final List list = jsonDecode(withdrawJson);
        _withdrawalHistory = list.map((e) => WithdrawalRequestItem.fromJson(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[AffiliateProvider] Error loading data: $e');
    }
  }

  /// Khởi tạo mã giới thiệu gắn theo email tài khoản Google
  void initUserCode(String email) {
    if (email.isEmpty) return;
    int hash = 0;
    for (int i = 0; i < email.length; i++) {
      hash = (31 * hash + email.codeUnitAt(i)) % 900000;
    }
    final code = (100000 + hash.abs()).toString().padLeft(6, '0');
    _myReferralCode = code;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user_referral_code', code);
    });
    notifyListeners();
  }

  /// Lưu mã giới thiệu của người khác giới thiệu mình
  Future<bool> saveReferredByCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.length != 6 || int.tryParse(cleanCode) == null) {
      return false;
    }
    if (cleanCode == _myReferralCode) {
      return false; // Không tự nhập mã của chính mình
    }

    _savedReferredByCode = cleanCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_referred_by_code', cleanCode);
    notifyListeners();

    // Gửi lên backend để lưu liên kết giới thiệu
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/affiliate/bind');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'referredByCode': cleanCode,
          'myCode': _myReferralCode,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  /// Gửi lệnh rút tiền về tài khoản ngân hàng
  Future<Map<String, dynamic>> requestWithdrawal({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required double amount,
  }) async {
    if (amount < 200000) {
      return {'success': false, 'message': 'Số tiền rút tối thiểu là 200.000đ'};
    }
    if (amount > _availableBalance) {
      return {'success': false, 'message': 'Số dư khả dụng không đủ để thực hiện rút tiền'};
    }

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final item = WithdrawalRequestItem(
      id: 'WD_${now.millisecondsSinceEpoch}',
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder.toUpperCase(),
      amount: amount,
      date: dateStr,
      status: 'Chờ duyệt',
    );

    _availableBalance -= amount;
    _withdrawalHistory.insert(0, item);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('affiliate_available_balance', _availableBalance);
    await prefs.setString('affiliate_withdraw_history', jsonEncode(_withdrawalHistory.map((e) => e.toJson()).toList()));

    notifyListeners();

    // Gửi yêu cầu rút tiền lên server Backend
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/affiliate/withdraw');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'withdrawalId': item.id,
          'referralCode': _myReferralCode,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolder': accountHolder,
          'amount': amount,
          'date': dateStr,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    return {'success': true, 'message': 'Yêu cầu rút tiền đã được gửi thành công! Ban quản trị sẽ chuyển khoản trong vòng 24 giờ.'};
  }

  /// Mô phỏng hoặc nhận hoa hồng khi có bạn bè thanh toán
  void addCommissionBonus({required String packageName, required double commissionAmount}) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    
    final item = AffiliateHistoryItem(
      id: 'COMM_${now.millisecondsSinceEpoch}',
      title: 'Hoa hồng giới thiệu bạn bè ($packageName)',
      date: dateStr,
      amount: commissionAmount,
      status: 'Thành công',
    );

    _availableBalance += commissionAmount;
    _invitedCount += 1;
    _incomeHistory.insert(0, item);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('affiliate_available_balance', _availableBalance);
      prefs.setInt('affiliate_invited_count', _invitedCount);
      prefs.setString('affiliate_income_history', jsonEncode(_incomeHistory.map((e) => e.toJson()).toList()));
    });

    notifyListeners();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:autobank_mobile/core/config/app_config.dart';
import 'package:autobank_mobile/core/data/banks_data.dart';

class SystemConfigProvider extends ChangeNotifier {
  String _brandName = 'Đọc Thông Báo Nhận Tiền';
  String _brandSlogan = 'Tiền vừa sang ~ máy báo vang';
  String _hotline = '0869226687';
  String _email = 'tranquocvu3011@gmail.com';
  String _bankCode = 'MB';
  String _bankAcc = '3011200588888';
  String _bankName = 'TRẦN QUỐC VŨ';
  String _latestVersion = '1.2.0 Pro';
  final int _priceTrial = 0;
  int _price1m = 38000;
  int _price3m = 99000;
  int _price6m = 179000;
  int _price9m = 249000;
  int _price1y = 299000;
  int _priceLifetime = 499000;
  int _bonusMonths1y = 2;
  String _marketingBanner = '';
  bool _maintenance = false;
  String _maintenanceMsg = '';
  bool _googlePayMaintenance = false;
  String _googlePayMaintenanceMsg = '';
  String _chplayLink = '';
  String _youtubeLink = '';
  String _facebook = '';
  String _tiktok = '';
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _coupons = [];
  List<Map<String, dynamic>> _announcements = [];
  bool _isServerConnected = false;
  bool _isLoading = false;

  // Trạng thái trực máy 24/24 và màn hình chờ
  bool _keepScreenOn = true;
  bool _isPhoneListening = true;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatSuccess;

  String get brandName => _brandName;
  String get brandSlogan => _brandSlogan;
  String get hotline => _hotline;
  String get email => _email;
  String get bankCode => _bankCode;
  String get bankAcc => _bankAcc;
  String get bankName => _bankName;
  String get latestVersion => _latestVersion;
  int get priceTrial => _priceTrial;
  int get price1m => _price1m;
  int get price3m => _price3m;
  int get price6m => _price6m;
  int get price9m => _price9m;
  int get price1y => _price1y;
  int get priceLifetime => _priceLifetime;
  int get bonusMonths1y => _bonusMonths1y;
  List<Map<String, dynamic>> get packages => _packages;
  List<Map<String, dynamic>> get coupons => _coupons;
  List<Map<String, dynamic>> get announcements => _announcements;
  String get marketingBanner => _marketingBanner;
  bool get maintenance => _maintenance;
  String get maintenanceMsg => _maintenanceMsg;
  bool get googlePayMaintenance => _googlePayMaintenance;
  String get googlePayMaintenanceMsg => _googlePayMaintenanceMsg.isNotEmpty
      ? _googlePayMaintenanceMsg
      : 'Cổng thanh toán Google Pay đang tạm bảo trì nâng cấp. Quý khách vui lòng chuyển khoản qua VietQR để kích hoạt ngay!';
  String get chplayLink => _chplayLink;
  String get youtubeLink => _youtubeLink;
  String get facebook => _facebook;
  String get tiktok => _tiktok;
  bool get isServerConnected => _isServerConnected;
  bool get isLoading => _isLoading;
  bool get keepScreenOn => _keepScreenOn;
  bool get isPhoneListening => _isPhoneListening;
  DateTime? get lastHeartbeatSuccess => _lastHeartbeatSuccess;

  Map<String, dynamic>? getBestCouponForUser({DateTime? userCreatedAt, String? userEmail}) {
    if (_coupons.isEmpty) return null;
    final now = DateTime.now();

    final activeCoupons = _coupons.where((c) {
      if (c['isActive'] == false) return false;
      if (c['autoApply'] == false) return false;
      final target = (c['targetAudience'] ?? 'ALL').toString().toUpperCase();
      if (userCreatedAt != null) {
        if (target == 'NEW_1DAY') {
          if (now.isAfter(userCreatedAt.add(const Duration(hours: 24)))) return false;
        } else if (target == 'NEW_2DAYS') {
          if (now.isAfter(userCreatedAt.add(const Duration(hours: 48)))) return false;
        } else if (target == 'NEW_3DAYS') {
          if (now.isAfter(userCreatedAt.add(const Duration(hours: 72)))) return false;
        }
      }
      return true;
    }).toList();

    if (activeCoupons.isEmpty) return null;

    activeCoupons.sort((a, b) {
      final pA = (a['discountPercent'] as num?)?.toInt() ?? 0;
      final pB = (b['discountPercent'] as num?)?.toInt() ?? 0;
      if (pA != pB) return pB.compareTo(pA);
      final amtA = (a['discountAmount'] as num?)?.toInt() ?? 0;
      final amtB = (b['discountAmount'] as num?)?.toInt() ?? 0;
      return amtB.compareTo(amtA);
    });

    return activeCoupons.first;
  }

  SystemConfigProvider() {
    scheduleMicrotask(() {
      fetchConfig();
      startHeartbeat();
    });
  }

  void setKeepScreenOn(bool val) {
    _keepScreenOn = val;
    notifyListeners();
    sendHeartbeat();
  }

  void setIsPhoneListening(bool val) {
    _isPhoneListening = val;
    notifyListeners();
    sendHeartbeat();
  }

  // Thông tin thật của tài khoản đang đăng nhập (đẩy vào từ GoogleAuthProvider)
  String? _activePackage;
  String? _accountEmail;

  void updateAccountContext({String? email, String? activePackage}) {
    if (_accountEmail == email && _activePackage == activePackage) return;
    _accountEmail = email;
    _activePackage = activePackage;
    sendHeartbeat();
  }

  void startHeartbeat() {
    sendHeartbeat();
    fetchConfig();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      sendHeartbeat();
      fetchConfig();
    });
  }

  Future<void> sendHeartbeat() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/phone-heartbeat');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceName': kIsWeb ? 'Trình duyệt Web' : defaultTargetPlatform.name,
          'isListening': _isPhoneListening,
          'keepScreenOn': _keepScreenOn,
          if (_activePackage != null) 'activePackage': _activePackage,
          if (_accountEmail != null) 'email': _accountEmail,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _lastHeartbeatSuccess = DateTime.now();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/configs');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _brandName = data['brandName'] ?? _brandName;
        _brandSlogan = data['brandSlogan'] ?? _brandSlogan;
        _hotline = data['hotline'] ?? _hotline;
        _email = data['email'] ?? _email;
        _bankCode = data['bankCode'] ?? _bankCode;
        _bankAcc = data['bankAcc'] ?? _bankAcc;
        _bankName = data['bankName'] ?? _bankName;
        _latestVersion = data['latestVersion'] ?? _latestVersion;
        if (data['price1m'] != null) _price1m = (data['price1m'] as num).toInt();
        if (data['price3m'] != null) _price3m = (data['price3m'] as num).toInt();
        if (data['price6m'] != null) _price6m = (data['price6m'] as num).toInt();
        if (data['price9m'] != null) _price9m = (data['price9m'] as num).toInt();
        if (data['price1y'] != null) _price1y = (data['price1y'] as num).toInt();
        if (data['priceLifetime'] != null) _priceLifetime = (data['priceLifetime'] as num).toInt();
        if (data['bonusMonths1y'] != null) _bonusMonths1y = (data['bonusMonths1y'] as num).toInt();
        if (data['marketingBanner'] != null && (data['marketingBanner'] as String).isNotEmpty) {
          _marketingBanner = data['marketingBanner'];
        }
        _maintenance = data['maintenance'] == true;
        _maintenanceMsg = data['maintenanceMsg'] ?? '';
        _googlePayMaintenance = data['googlePayMaintenance'] == true;
        _googlePayMaintenanceMsg = data['googlePayMaintenanceMsg'] ?? '';
        _chplayLink = data['chplayLink'] ?? '';
        _youtubeLink = data['youtubeLink'] ?? '';
        _facebook = data['facebook'] ?? '';
        _tiktok = data['tiktok'] ?? '';

        if (data['packages'] != null && data['packages'] is List) {
          _packages = (data['packages'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        if (data['serverDomain'] != null && (data['serverDomain'] as String).trim().isNotEmpty) {
          AppConfig.updateDomains(
            apiDomain: data['serverDomain'] as String,
            webDomain: data['webDomain'] as String?,
          );
        }

        _isServerConnected = true;
      }

      // Tải danh sách mã giảm giá từ Admin Backend MySQL
      try {
        final couponUri = Uri.parse('${AppConfig.apiBaseUrl}/admin/coupons');
        final cRes = await http.get(couponUri).timeout(const Duration(seconds: 4));
        if (cRes.statusCode == 200) {
          final cList = jsonDecode(cRes.body);
          if (cList is List) {
            _coupons = cList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      } catch (_) {}

      // Tải danh sách thông báo phát sóng từ Admin Backend MySQL (push_broadcasts)
      try {
        final pushUri = Uri.parse('${AppConfig.apiBaseUrl}/admin/push');
        final pRes = await http.get(pushUri).timeout(const Duration(seconds: 4));
        if (pRes.statusCode == 200) {
          final pList = jsonDecode(pRes.body);
          if (pList is List) {
            _announcements = pList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      } catch (_) {}

      // Đồng bộ danh sách 65+ ngân hàng từ MySQL (bank_apps)
      await BankDataRepository.fetchFromBackend(AppConfig.apiBaseUrl);
    } catch (_) {
      // Khi offline hoặc server đang khởi động
      _isServerConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

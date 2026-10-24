import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:autobank_mobile/core/config/app_config.dart';
import 'package:autobank_mobile/core/data/banks_data.dart';
import 'package:autobank_mobile/core/utils/currency_formatter.dart';

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
  int _price1m = 29000;
  int _price3m = 69000;
  int _price6m = 109000;
  int _price9m = 109000;
  int _price1y = 159000;
  int _priceLifetime = 219000;
  int _bonusMonths1y = 2;
  String _marketingBanner = '';
  bool _maintenance = false;
  String _maintenanceMsg = '';
  bool _googlePayMaintenance = false;
  String _googlePayMaintenanceMsg = '';
  String _chplayLink = '';
  String _ratingUrl = '';
  String _youtubeLink = '';
  String _videoGuideNewbie = '';
  String _videoGuideSmooth = '';
  String _videoGuideAffiliate = '';
  String _videoGuideHistory = '';
  String _videoGuideVoice = '';
  String _facebook = '';
  String _tiktok = '';
  List<Map<String, dynamic>> _packages = [
    {
      'key': 'trial',
      'name': 'Dùng thử miễn phí',
      'durationDays': 3,
      'price': 0,
      'badge': 'Miễn phí',
      'description': 'Trải nghiệm 100% tính năng cao cấp trong 3 ngày',
      'isActive': true,
    },
    {
      'key': '1m',
      'name': '1 Tháng',
      'durationDays': 30,
      'price': 29000,
      'badge': 'Trải nghiệm',
      'description': 'Bản quyền 30 ngày đầy đủ thông báo giọng nói',
      'isActive': true,
    },
    {
      'key': '3m',
      'name': '3 Tháng',
      'durationDays': 90,
      'price': 69000,
      'badge': 'Tiết kiệm',
      'description': 'Bản quyền 90 ngày cho cửa hàng kinh doanh',
      'isActive': true,
    },
    {
      'key': '6m',
      'name': '6 Tháng',
      'durationDays': 180,
      'price': 109000,
      'badge': 'Phổ biến',
      'description': 'Bản quyền 180 ngày ổn định 24/7',
      'isActive': true,
    },
    {
      'key': '1y',
      'name': '1 Năm (tặng 2T)',
      'durationDays': 425,
      'price': 159000,
      'badge': 'Khuyên dùng',
      'description': 'Tặng thêm 2 tháng + Hỗ trợ kỹ thuật 24/7',
      'isActive': true,
    },
    {
      'key': '2y',
      'name': '2 Năm (tặng 6T)',
      'durationDays': 910,
      'price': 219000,
      'badge': 'Tốt Nhất',
      'description': 'Tặng thêm 6 tháng + Hỗ trợ kỹ thuật 24/7',
      'isActive': true,
    },
  ];
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
  String get ratingUrl => _ratingUrl.isNotEmpty ? _ratingUrl : _chplayLink;
  String get youtubeLink => _youtubeLink;
  String get youtubeGuideUrl => _youtubeLink.isNotEmpty
      ? _youtubeLink
      : 'https://www.youtube.com/watch?v=kYJqD9bZ_fQ';
  String get videoGuideNewbie => _videoGuideNewbie.isNotEmpty ? _videoGuideNewbie : youtubeGuideUrl;
  String get videoGuideSmooth => _videoGuideSmooth.isNotEmpty ? _videoGuideSmooth : youtubeGuideUrl;
  String get videoGuideAffiliate => _videoGuideAffiliate.isNotEmpty ? _videoGuideAffiliate : youtubeGuideUrl;
  String get videoGuideHistory => _videoGuideHistory.isNotEmpty ? _videoGuideHistory : youtubeGuideUrl;
  String get videoGuideVoice => _videoGuideVoice.isNotEmpty ? _videoGuideVoice : youtubeGuideUrl;
  String get facebook => _facebook;
  String get tiktok => _tiktok;
  bool get isServerConnected => _isServerConnected;
  bool get isLoading => _isLoading;
  bool get keepScreenOn => _keepScreenOn;
  bool get isPhoneListening => _isPhoneListening;
  DateTime? get lastHeartbeatSuccess => _lastHeartbeatSuccess;

  // Bảng thưởng hoa hồng đối tác được đồng bộ từ cấu hình Admin
  List<Map<String, dynamic>> _affiliateRewards = [
    {'name': 'Gói 1 Tháng', 'duration': '30 ngày', 'reward': 10000, 'desc': 'Nhận 10.000₫/lượt'},
    {'name': 'Gói 3 Tháng', 'duration': '90 ngày', 'reward': 25000, 'desc': 'Nhận 25.000₫/lượt'},
    {'name': 'Gói 6 Tháng', 'duration': '180 ngày', 'reward': 45000, 'desc': 'Nhận 45.000₫/lượt'},
    {'name': 'Gói 1 Năm (VIP)', 'duration': '365 ngày', 'reward': 75000, 'desc': 'Nhận 75.000₫/lượt'},
    {'name': 'Gói Vĩnh Viễn Trọn Đời', 'duration': 'Trọn đời', 'reward': 120000, 'desc': 'Nhận 120.000₫/lượt'},
  ];

  List<Map<String, dynamic>> get affiliateRewards {
    if (_packages.isNotEmpty) {
      final list = <Map<String, dynamic>>[];
      for (final p in _packages) {
        if (p['isActive'] == false) continue;
        final name = (p['name'] ?? 'Gói VIP').toString();
        final days = (p['durationDays'] as num?)?.toInt() ?? 30;
        final key = (p['key'] ?? '').toString();
        final price = (p['price'] as num?)?.toInt() ?? 0;
        final comm = getCommissionForPackage(
          key: key,
          name: name,
          durationDays: days,
          price: price,
        );
        list.add({
          'name': name,
          'duration': days >= 9999 ? 'Trọn đời' : '$days ngày',
          'reward': comm,
          'price': price,
          'desc': 'Nhận ${CurrencyFormatter.formatVND(comm.toDouble())}/lượt',
        });
      }
      if (list.isNotEmpty) return list;
    }
    return _affiliateRewards;
  }

  void updateAffiliateRewards(List<Map<String, dynamic>> customList) {
    if (customList.isNotEmpty) {
      _affiliateRewards = customList;
      notifyListeners();
    }
  }

  /// Lấy mức hoa hồng đại lý / đối tác tương ứng cho từng gói cước
  /// Ưu tiên 1: Giá trị cài đặt trực tiếp từ Admin Backend MySQL
  /// Ưu tiên 2: Cấu hình tỷ lệ thưởng theo gói
  /// Ưu tiên 3: Tỷ lệ thưởng chuẩn theo thời hạn gói
  int getCommissionForPackage({String? key, String? name, int? durationDays, int? price}) {
    // 1. Kiểm tra trực tiếp trong danh sách _packages do Admin cài đặt
    if (_packages.isNotEmpty) {
      for (final p in _packages) {
        final pKey = (p['key'] ?? '').toString();
        final pName = (p['name'] ?? '').toString().toLowerCase();
        final pDays = (p['durationDays'] as num?)?.toInt();

        final isMatch = (key != null && key.isNotEmpty && pKey == key) ||
            (name != null && name.isNotEmpty && (pName == name.toLowerCase() || pName.contains(name.toLowerCase()))) ||
            (durationDays != null && pDays == durationDays);

        if (isMatch) {
          if (p['commission'] != null && (p['commission'] as num) > 0) {
            return (p['commission'] as num).toInt();
          }
          if (p['affiliateReward'] != null && (p['affiliateReward'] as num) > 0) {
            return (p['affiliateReward'] as num).toInt();
          }
        }
      }
    }

    // 2. Kiểm tra trong danh sách _affiliateRewards do Admin cấu hình
    if (_affiliateRewards.isNotEmpty && name != null) {
      for (final r in _affiliateRewards) {
        final rName = (r['name'] ?? '').toString().toLowerCase();
        if (rName.contains(name.toLowerCase()) || name.toLowerCase().contains(rName)) {
          if (r['reward'] != null && (r['reward'] as num) > 0) {
            return (r['reward'] as num).toInt();
          }
        }
      }
    }

    // 3. Mức hoa hồng chuẩn theo ngày sử dụng gói
    final days = durationDays ?? 30;
    if (days <= 3) return 0;
    if (days <= 30) return 10000;
    if (days <= 90) return 25000;
    if (days <= 180) return 45000;
    if (days <= 270) return 60000;
    if (days <= 365) return 75000;
    return 120000;
  }

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
        _ratingUrl = data['ratingUrl'] ?? _chplayLink;
        _youtubeLink = data['youtubeLink'] ?? '';
        _videoGuideNewbie = data['videoGuideNewbie'] ?? '';
        _videoGuideSmooth = data['videoGuideSmooth'] ?? '';
        _videoGuideAffiliate = data['videoGuideAffiliate'] ?? '';
        _videoGuideHistory = data['videoGuideHistory'] ?? '';
        _videoGuideVoice = data['videoGuideVoice'] ?? '';
        _facebook = data['facebook'] ?? '';
        _tiktok = data['tiktok'] ?? '';

        if (data['affiliateRewards'] != null && data['affiliateRewards'] is List) {
          _affiliateRewards = (data['affiliateRewards'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

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

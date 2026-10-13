import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SystemConfigProvider extends ChangeNotifier {
  String _brandName = 'Đọc thông báo nhận tiền';
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
  String _marketingBanner = '🎉 ƯU ĐÃI ĐẶC BIỆT: Nhập mã AUTOBANK20 giảm ngay 20% cho tất cả các gói!';
  bool _maintenance = false;
  String _maintenanceMsg = '';
  String _chplayLink = '';
  String _youtubeLink = '';
  String _facebook = '';
  String _tiktok = '';
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
  String get marketingBanner => _marketingBanner;
  bool get maintenance => _maintenance;
  String get maintenanceMsg => _maintenanceMsg;
  String get chplayLink => _chplayLink;
  String get youtubeLink => _youtubeLink;
  String get facebook => _facebook;
  String get tiktok => _tiktok;
  bool get isServerConnected => _isServerConnected;
  bool get isLoading => _isLoading;
  bool get keepScreenOn => _keepScreenOn;
  bool get isPhoneListening => _isPhoneListening;
  DateTime? get lastHeartbeatSuccess => _lastHeartbeatSuccess;

  SystemConfigProvider() {
    fetchConfig();
    startHeartbeat();
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

  void startHeartbeat() {
    sendHeartbeat();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      sendHeartbeat();
    });
  }

  Future<void> sendHeartbeat() async {
    try {
      final uri = Uri.parse('http://localhost:3000/admin/phone-heartbeat');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceName': 'Samsung Galaxy A54 (Android 14)',
          'batteryLevel': 98,
          'isListening': _isPhoneListening,
          'keepScreenOn': _keepScreenOn,
          'activePackage': 'Gói Doanh Nghiệp (365 ngày)',
          'voiceName': 'Giọng đọc chuẩn',
          'repeatCount': 2,
          'autoSpeechCredit': true,
          'autoSpeechDebit': false,
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
      final uri = Uri.parse('http://localhost:3000/admin/configs');
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
        _chplayLink = data['chplayLink'] ?? '';
        _youtubeLink = data['youtubeLink'] ?? '';
        _facebook = data['facebook'] ?? '';
        _tiktok = data['tiktok'] ?? '';
        _isServerConnected = true;
      }
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

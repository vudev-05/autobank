import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Model quản lý thông tin từng tài khoản Google trên thiết bị
class GoogleUserAccount {
  final String id;
  final String name;
  final String email;
  final String initial;
  String shop;
  String phone;
  String? boundDeviceId;
  final DateTime createdAt; // Thời điểm tạo tài khoản
  bool isTrialStarted; // Đã bấm chọn gói dùng thử chưa
  DateTime? trialStartedAt; // Thời điểm chọn gói dùng thử (bắt đầu đếm ngược)
  bool hasUsedTrial; // Đã từng dùng thử chưa (chỉ được dùng thử 1 lần duy nhất)
  bool isActivated;
  bool isLifetime; // Đã mua gói vĩnh viễn trọn đời (VIP cao nhất hệ thống)
  String activePackageName;
  DateTime expireDate;

  GoogleUserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.initial,
    required this.shop,
    this.phone = '0988123456',
    this.boundDeviceId,
    required this.createdAt,
    this.isTrialStarted = false,
    this.trialStartedAt,
    this.hasUsedTrial = false,
    this.isActivated = false,
    bool? isLifetime,
    this.activePackageName = 'Chưa kích hoạt gói',
    DateTime? expireDate,
  })  : isLifetime = isLifetime ??
            (activePackageName.contains('Vĩnh Viễn') ||
                activePackageName.toLowerCase().contains('lifetime')),
        expireDate = expireDate ??
            (activePackageName.contains('Vĩnh Viễn')
                ? DateTime(2099, 12, 31)
                : createdAt.add(const Duration(days: 3)));
}

class GoogleAuthProvider extends ChangeNotifier {
  bool _isSignedIn = false;
  final String _deviceName = 'Samsung Galaxy (Android 14)';
  final String _currentDeviceId = 'DEV-VN-9921';
  final String _appVersion = '1.2.0';

  // Danh sách tài khoản Google đã lưu trên máy
  final List<GoogleUserAccount> _accounts = [
    GoogleUserAccount(
      id: 'acc_1',
      name: 'Nguyễn Văn An',
      email: 'nguyenvanan.dev@gmail.com',
      initial: 'A',
      shop: 'Tiệm Bánh Mì Kim Anh',
      phone: '0912345678',
      boundDeviceId: 'DEV-VN-9921',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 23)),
      isTrialStarted: true,
      trialStartedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 23)),
      hasUsedTrial: true, // Đã kích hoạt dùng thử 1 lần duy nhất
      isActivated: true,
      activePackageName: 'Dùng thử 3 ngày miễn phí',
      expireDate: DateTime.now().subtract(const Duration(hours: 1, minutes: 23)).add(const Duration(days: 3)),
    ),
    GoogleUserAccount(
      id: 'acc_2',
      name: 'Trần Thị Kim Anh',
      email: 'tiembanhmikimanh@gmail.com',
      initial: 'K',
      shop: 'Bánh Mì Kim Anh Q1',
      phone: '0977889900',
      boundDeviceId: 'DEV-VN-9921',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isTrialStarted: false, // Chưa kích hoạt dùng thử
      trialStartedAt: null,
      hasUsedTrial: false, // Còn quyền dùng thử 1 lần duy nhất
      isActivated: false,
      activePackageName: 'Chưa kích hoạt gói',
      expireDate: DateTime.now().add(const Duration(days: 3)),
    ),
    GoogleUserAccount(
      id: 'acc_3',
      name: 'Trần Quốc Vũ',
      email: 'tranquocvu3011@gmail.com',
      initial: 'V',
      shop: 'AutoBank Store Official',
      phone: '0869226687',
      boundDeviceId: 'DEV-VN-9921',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      isTrialStarted: true,
      trialStartedAt: DateTime.now().subtract(const Duration(days: 10)),
      hasUsedTrial: true,
      isActivated: true,
      activePackageName: 'Gói 1 năm (365 ngày)',
      expireDate: DateTime.now().add(const Duration(days: 355)),
    ),
  ];

  int _currentIndex = 2; // Mặc định chọn Trần Quốc Vũ

  // Getters cho tài khoản hiện tại
  bool get isSignedIn => _isSignedIn;
  List<GoogleUserAccount> get accounts => List.unmodifiable(_accounts);
  GoogleUserAccount get currentAccount => _accounts[_currentIndex];

  String get displayName => currentAccount.name;
  String get email => currentAccount.email;
  String get avatarInitial => currentAccount.initial;
  String get deviceName => _deviceName;
  String get currentDeviceId => _currentDeviceId;
  String get appVersion => _appVersion;
  String get shopName => currentAccount.shop;
  String get phone => currentAccount.phone;
  String? get boundDeviceId => currentAccount.boundDeviceId;
  bool get isDeviceLockedToCurrent => currentAccount.boundDeviceId == _currentDeviceId;

  DateTime get createdAt => currentAccount.createdAt;
  bool get isTrialStarted => currentAccount.isTrialStarted;
  DateTime? get trialStartedAt => currentAccount.trialStartedAt;
  bool get isActivated => currentAccount.isActivated;
  bool get isLifetime => currentAccount.isLifetime;
  String get activePackageName => currentAccount.activePackageName;
  DateTime get expireDate => currentAccount.expireDate;

  // Danh sách dạng map tương thích cho các widget cũ
  static List<Map<String, String>> get availableGoogleAccounts => [
    {
      'name': 'Nguyễn Văn An',
      'email': 'nguyenvanan.dev@gmail.com',
      'initial': 'A',
      'shop': 'Tiệm Bánh Mì Kim Anh',
    },
    {
      'name': 'Trần Thị Kim Anh',
      'email': 'tiembanhmikimanh@gmail.com',
      'initial': 'K',
      'shop': 'Bánh Mì Kim Anh Q1',
    },
    {
      'name': 'Trần Quốc Vũ',
      'email': 'tranquocvu3011@gmail.com',
      'initial': 'V',
      'shop': 'AutoBank Store Official',
    },
  ];

  /// Chọn tài khoản Google theo index
  void selectAccountByIndex(int index) {
    if (index >= 0 && index < _accounts.length) {
      _currentIndex = index;
      _isSignedIn = true;
      notifyListeners();
      _syncUserToBackend();
    }
  }

  /// Cập nhật thông tin quán & SĐT của tài khoản hiện tại
  void updateAccountInfo({required String shop, required String phone}) {
    currentAccount.shop = shop;
    currentAccount.phone = phone;
    notifyListeners();
    _syncUserToBackend();
  }

  /// Đăng nhập / Chọn tài khoản theo email
  void signInWithGoogle({
    required String name,
    required String email,
    required String initial,
    String? shop,
    String? phone,
  }) {
    _isSignedIn = true;
    final foundIndex = _accounts.indexWhere((acc) => acc.email == email);
    if (foundIndex != -1) {
      _currentIndex = foundIndex;
      if (shop != null && shop.isNotEmpty) {
        _accounts[foundIndex].shop = shop;
      }
      if (phone != null && phone.isNotEmpty) {
        _accounts[foundIndex].phone = phone;
      }
    } else {
      final newAcc = GoogleUserAccount(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        initial: initial,
        shop: shop ?? 'Cửa hàng $name',
        phone: phone ?? '0988123456',
        boundDeviceId: _currentDeviceId,
        createdAt: DateTime.now(),
        isTrialStarted: false,
        trialStartedAt: null,
        isActivated: false,
        activePackageName: 'Chưa kích hoạt gói',
      );
      _accounts.add(newAcc);
      _currentIndex = _accounts.length - 1;
    }
    notifyListeners();
    _syncUserToBackend();
  }

  /// Tạo tài khoản Google mới lúc tải app về hoặc bấm thêm tài khoản mới
  GoogleUserAccount createNewGoogleAccount({
    required String name,
    required String email,
    required String shop,
    String? phone,
  }) {
    _isSignedIn = true;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'G';
    final now = DateTime.now();

    final newAcc = GoogleUserAccount(
      id: 'acc_${now.millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      initial: initial,
      shop: shop.trim().isNotEmpty ? shop.trim() : 'Cửa hàng $name',
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : '0988123456',
      boundDeviceId: _currentDeviceId,
      createdAt: now,
      isTrialStarted: false,
      trialStartedAt: null,
      isActivated: false,
      activePackageName: 'Chưa kích hoạt gói',
      expireDate: now.add(const Duration(days: 3)),
    );

    _accounts.add(newAcc);
    _currentIndex = _accounts.length - 1;
    notifyListeners();
    _syncUserToBackend();
    return newAcc;
  }

  /// BẮT ĐẦU ĐẾM NGƯỢC KHI NGƯỜI DÙNG CHỌN GÓI DÙNG THỬ (CHỈ 1 LẦN DUY NHẤT)
  bool startTrial() {
    if (currentAccount.hasUsedTrial) {
      return false; // Đã từng dùng thử rồi!
    }
    final now = DateTime.now();
    currentAccount.hasUsedTrial = true;
    currentAccount.isTrialStarted = true;
    currentAccount.trialStartedAt = now;
    currentAccount.isActivated = true;
    currentAccount.activePackageName = 'Dùng thử 3 ngày miễn phí';
    currentAccount.expireDate = now.add(const Duration(days: 3));
    notifyListeners();
    _syncUserToBackend();
    return true;
  }

  /// Kích hoạt gói bản quyền bất kỳ (Dùng thử hoặc Gói tháng / năm / Vĩnh viễn)
  bool activatePackage(String packageName, int days) {
    // 1. NẾU TÀI KHOẢN ĐÃ SỞ HỮU GÓI VĨNH VIỄN -> KHÓA KHÔNG CHO MUA NỮA
    if (currentAccount.isLifetime) {
      return false;
    }

    final now = DateTime.now();

    // 2. NẾU MUA GÓI VĨNH VIỄN TRỌN ĐỜI
    if (packageName.contains('Vĩnh Viễn') || packageName.toLowerCase().contains('lifetime')) {
      currentAccount.isLifetime = true;
      currentAccount.isActivated = true;
      currentAccount.activePackageName = 'Gói Vĩnh Viễn (Trọn Đời)';
      currentAccount.expireDate = DateTime(2099, 12, 31);
      notifyListeners();
      _syncUserToBackend();
      return true;
    }

    // 3. NẾU CHỌN DÙNG THỬ
    if (packageName.contains('Dùng thử')) {
      if (currentAccount.hasUsedTrial) {
        return false; // Chỉ được dùng thử 1 lần duy nhất!
      }
      currentAccount.hasUsedTrial = true;
      currentAccount.isTrialStarted = true;
      currentAccount.trialStartedAt = now;
      currentAccount.isActivated = true;
      currentAccount.activePackageName = packageName;
      currentAccount.expireDate = now.add(Duration(days: days));
      notifyListeners();
      _syncUserToBackend();
      return true;
    }

    // 4. NẾU MUA GÓI THÁNG / NĂM -> CỘNG DỒN THỜI HẠN VÀO HẠN DÙNG HIỆN TẠI
    final baseDate = (currentAccount.isActivated && currentAccount.expireDate.isAfter(now))
        ? currentAccount.expireDate
        : now;

    currentAccount.isActivated = true;
    currentAccount.activePackageName = packageName;
    currentAccount.expireDate = baseDate.add(Duration(days: days));
    notifyListeners();
    _syncUserToBackend();
    return true;
  }

  /// Hủy liên kết thiết bị hiện tại
  Future<bool> unbindCurrentDevice() async {
    currentAccount.boundDeviceId = null;
    notifyListeners();
    try {
      final uri = Uri.parse('http://localhost:3000/admin/device/unbind');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return true;
    }
  }

  /// Liên kết thiết bị hiện tại (hỗ trợ forceSwitch nếu đổi máy)
  Future<Map<String, dynamic>> bindCurrentDevice({bool forceSwitch = false}) async {
    try {
      final uri = Uri.parse('http://localhost:3000/admin/device/bind');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'deviceId': _currentDeviceId,
          'deviceName': _deviceName,
          'phone': phone,
          'shopName': shopName,
          'forceSwitch': forceSwitch,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['conflict'] == true) {
          return {
            'success': false,
            'conflict': true,
            'message': data['message'] ?? 'Tài khoản đang liên kết với máy khác!',
            'boundDevice': data['boundDevice'],
          };
        }
        currentAccount.boundDeviceId = _currentDeviceId;
        notifyListeners();
        return {'success': true};
      }
    } catch (_) {}
    currentAccount.boundDeviceId = _currentDeviceId;
    notifyListeners();
    return {'success': true};
  }

  void signOut() {
    _isSignedIn = false;
    notifyListeners();
  }

  void setShopName(String newShop) {
    currentAccount.shop = newShop;
    notifyListeners();
    _syncUserToBackend();
  }

  GoogleAuthProvider() {
    _syncUserToBackend();
  }

  Future<void> _syncUserToBackend() async {
    try {
      final uri = Uri.parse('http://localhost:3000/admin/users');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': displayName,
          'email': email,
          'device': _deviceName,
          'version': _appVersion,
          'packagePlan': activePackageName,
          'hasUsedTrial': currentAccount.hasUsedTrial,
          'expiresAt': expireDate.toIso8601String(),
          'phone': phone,
          'shopName': shopName,
          'deviceId': boundDeviceId ?? _currentDeviceId,
          'status': 'ACTIVE',
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data != null && data['expiresAt'] != null) {
          final serverExpiry = DateTime.tryParse(data['expiresAt'].toString());
          if (serverExpiry != null && (serverExpiry.isAfter(currentAccount.expireDate) || serverExpiry.isBefore(currentAccount.expireDate))) {
            currentAccount.expireDate = serverExpiry;
            if (data['packagePlan'] != null) {
              currentAccount.activePackageName = data['packagePlan'].toString();
            }
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // Offline fallback
    }
  }
}

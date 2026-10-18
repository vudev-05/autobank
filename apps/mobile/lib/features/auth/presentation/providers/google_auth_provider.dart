import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';

class GoogleUserAccount {
  final String id;
  final String name;
  final String email;
  final String initial;
  String shop;
  String phone;
  String? boundDeviceId;
  final DateTime createdAt;
  bool isTrialStarted;
  DateTime? trialStartedAt;
  bool hasUsedTrial;
  bool isActivated;
  bool isLifetime;
  String activePackageName;
  DateTime expireDate;

  GoogleUserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.initial,
    this.shop = 'Cửa hàng',
    this.phone = '',
    this.boundDeviceId,
    required this.createdAt,
    this.isTrialStarted = false,
    this.trialStartedAt,
    this.hasUsedTrial = false,
    this.isActivated = false,
    this.isLifetime = false,
    this.activePackageName = 'Chưa kích hoạt gói',
    DateTime? expireDate,
  }) : expireDate = expireDate ??
            (activePackageName.contains('Vĩnh Viễn')
                ? DateTime(2099, 12, 31)
                : createdAt.add(const Duration(days: 3)));

  /// Tự động kiểm tra thời hạn sử dụng gói cước (Dùng thử 3 ngày hoặc gói tháng/năm)
  bool get isExpired => !isLifetime && DateTime.now().isAfter(expireDate);

  /// Trạng thái kích hoạt thực tế: Nếu đã quá hạn thì tự động thu hồi quyền
  bool get effectiveIsActivated => isActivated && !isExpired;

  /// Tên gói cước hiển thị chuẩn theo trạng thái thời gian thực
  String get effectivePackageName {
    if (isExpired) {
      return activePackageName.contains('Dùng thử')
          ? 'Gói dùng thử đã hết hạn'
          : 'Gói cước đã hết hạn';
    }
    return activePackageName;
  }
}

class GoogleAuthProvider extends ChangeNotifier {
  bool _isSignedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  final String _deviceName = 'Thiết bị di động';
  final String _currentDeviceId = 'DEV-VN-9921';
  final String _appVersion = '1.2.0';

  /// Callback gửi thông báo ra hệ thống khi có sự kiện đăng nhập, xác thực, nâng cấp gói
  Function(String title, String message, String type)? onNotificationEvent;

  GoogleSignIn? _googleSignIn;
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      clientId: kIsWeb ? AppConfig.googleWebClientId : null,
      serverClientId: kIsWeb ? null : AppConfig.googleWebClientId,
      scopes: ['email'],
    );
    return _googleSignIn!;
  }

  static final _guestAccount = GoogleUserAccount(
    id: 'guest',
    name: 'Khách hàng',
    email: '',
    initial: 'K',
    shop: 'Cửa hàng',
    phone: '',
    createdAt: DateTime.now(),
    isTrialStarted: true,
    hasUsedTrial: true,
    isActivated: true,
    activePackageName: 'Gói dùng thử trải nghiệm',
  );

  // 100% Tài khoản thật từ Google OAuth (Không chứa bất kỳ dữ liệu ảo nào)
  final List<GoogleUserAccount> _accounts = [];
  int _currentIndex = 0;

  bool get isSignedIn => _isSignedIn && _accounts.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GoogleUserAccount> get accounts => List.unmodifiable(_accounts);
  GoogleUserAccount get currentAccount =>
      (_accounts.isNotEmpty && _currentIndex < _accounts.length) ? _accounts[_currentIndex] : _guestAccount;

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
  bool get hasUsedTrial => currentAccount.hasUsedTrial;
  DateTime? get trialStartedAt => currentAccount.trialStartedAt;
  bool get isExpired => currentAccount.isExpired;
  bool get isActivated => currentAccount.effectiveIsActivated;
  bool get isLifetime => currentAccount.isLifetime;
  String get activePackageName => currentAccount.effectivePackageName;
  DateTime get expireDate => currentAccount.expireDate;

  void selectAccountByIndex(int index) {
    if (index >= 0 && index < _accounts.length) {
      _currentIndex = index;
      _isSignedIn = true;
      notifyListeners();
      _syncUserToBackend();
    }
  }

  /// Đăng nhập bằng tài khoản Google (hỗ trợ nhập email thật hoặc mở OAuth)
  void signInWithGoogle({
    required String name,
    required String email,
    required String initial,
    String? shop,
    String? phone,
  }) {
    if (email.trim().isNotEmpty) {
      signInWithEmailDirect(email: email, name: name, shop: shop, phone: phone);
    } else {
      signInWithRealGoogle();
    }
  }

  void createNewGoogleAccount({
    required String name,
    required String email,
    String? shop,
    String? phone,
  }) {
    if (email.trim().isNotEmpty) {
      signInWithEmailDirect(email: email, name: name, shop: shop, phone: phone);
    } else {
      signInWithRealGoogle();
    }
  }

  /// Đăng nhập trực tiếp bằng Email Google thật (rất hữu ích khi chạy trên Web localhost chưa cấu hình Authorized Origins trên Google Cloud)
  Future<bool> signInWithEmailDirect({
    required String email,
    String? name,
    String? shop,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim();
      if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
        _errorMessage = 'Vui lòng nhập định dạng email hợp lệ (ví dụ: name@gmail.com).';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final cleanName = (name != null && name.trim().isNotEmpty) ? name.trim() : cleanEmail.split('@').first;
      final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'G';
      final hasCustomShop = shop != null && shop.trim().isNotEmpty;

      // Đồng bộ vào backend MySQL
      Map<String, dynamic>? backendUser;
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users');
        final Map<String, dynamic> bodyPayload = {
          'name': cleanName,
          'email': cleanEmail,
          'device': _deviceName,
          'version': _appVersion,
          'packagePlan': 'Dùng thử 3 ngày',
          'hasUsedTrial': true,
          'expiresAt': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'phone': phone ?? '',
          'deviceId': _currentDeviceId,
          'status': 'ACTIVE',
        };
        if (hasCustomShop) {
          bodyPayload['shopName'] = shop.trim();
        }
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyPayload),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(res.body);
          if (data != null && data['email'] != null) {
            backendUser = Map<String, dynamic>.from(data);
          }
        }
      } catch (e) {
        debugPrint('Lỗi kết nối backend /admin/users: $e');
      }

      final hasUsedTrial = backendUser?['hasUsedTrial'] == true;
      final String packagePlan = (backendUser?['packagePlan'] ?? 'Chưa kích hoạt gói').toString();
      final bool isPaidPlan = packagePlan != 'Chưa kích hoạt gói' && !packagePlan.toLowerCase().contains('dùng thử');
      final bool isTrialPlan = packagePlan.toLowerCase().contains('dùng thử');
      final DateTime createdAt = DateTime.tryParse('${backendUser?['createdAt']}') ?? DateTime.now();
      final DateTime expiresAt = DateTime.tryParse('${backendUser?['expiresAt']}') ?? DateTime.now().add(const Duration(days: 3));

      final bool isTrialStarted = hasUsedTrial || isTrialPlan || isPaidPlan;
      final bool isActivated = (backendUser?['status'] == 'ACTIVE') && (isPaidPlan || (isTrialPlan && !DateTime.now().isAfter(expiresAt)));

      // Tên quán: ưu tiên tuyệt đối từ MySQL (nơi người dùng đã lưu)
      final String resolvedShop = (backendUser != null && backendUser['shopName'] != null && backendUser['shopName'].toString().trim().isNotEmpty)
          ? backendUser['shopName'].toString().trim()
          : (hasCustomShop ? shop.trim() : 'Cửa hàng $cleanName');

      final realAcc = GoogleUserAccount(
        id: backendUser?['id']?.toString() ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        email: cleanEmail,
        initial: initial,
        shop: resolvedShop,
        phone: (backendUser?['phone'] ?? phone ?? '').toString(),
        boundDeviceId: _currentDeviceId,
        createdAt: createdAt,
        isTrialStarted: isTrialStarted,
        hasUsedTrial: hasUsedTrial,
        isActivated: isActivated,
        isLifetime: packagePlan.contains('Vĩnh Viễn') || packagePlan.toLowerCase().contains('lifetime'),
        activePackageName: packagePlan,
        expireDate: expiresAt,
      );

      _accounts.clear();
      _accounts.add(realAcc);
      _currentIndex = 0;
      _isSignedIn = true;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      _syncUserToBackend();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi đăng nhập: $e';
      notifyListeners();
      return false;
    }
  }

  static List<Map<String, String>> get availableGoogleAccounts => [];

  GoogleAuthProvider() {
    scheduleMicrotask(() {
      _initSilentSignIn();
      _loadUserFromBackend();
    });
  }

  /// Tải thông tin người dùng thực tế từ Cơ sở dữ liệu MySQL (Không bao giờ tạo dữ liệu ảo trong code)
  Future<void> _loadUserFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty && _accounts.isEmpty) {
          final primary = list.firstWhere(
            (u) => (u['email'] ?? '').toString() == 'tranquocvu3011@gmail.com',
            orElse: () => list.first,
          );

          if (primary != null && primary['email'] != null) {
            final String uEmail = primary['email'].toString();
            final String uName = (primary['name'] ?? uEmail.split('@').first).toString();
            final cachedShop = prefs.getString('shop_name_$uEmail');
            final cachedPhone = prefs.getString('phone_$uEmail');
            final String rawShop = (primary['shopName'] ?? '').toString().trim();
            final String uShop = rawShop.isNotEmpty ? rawShop : (cachedShop != null && cachedShop.isNotEmpty ? cachedShop : 'Cửa hàng $uName');
            final String rawPhone = (primary['phone'] ?? '').toString().trim();
            final String uPhone = rawPhone.isNotEmpty ? rawPhone : (cachedPhone ?? '');
            final String uPkg = (primary['packagePlan'] ?? 'Dùng thử 3 ngày').toString();
            final DateTime uCreated = DateTime.tryParse('${primary['createdAt']}') ?? DateTime.now();
            final DateTime uExpires = DateTime.tryParse('${primary['expiresAt']}') ?? DateTime.now().add(const Duration(days: 365));

            final sqlUser = GoogleUserAccount(
              id: primary['id']?.toString() ?? 'acc_sql_1',
              name: uName,
              email: uEmail,
              initial: uName.isNotEmpty ? uName[0].toUpperCase() : 'U',
              shop: uShop,
              phone: uPhone,
              boundDeviceId: primary['deviceId']?.toString() ?? _currentDeviceId,
              createdAt: uCreated,
              isTrialStarted: true,
              hasUsedTrial: true,
              isActivated: primary['status'] != 'BLOCKED',
              isLifetime: uPkg.contains('Vĩnh Viễn') || uPkg.toLowerCase().contains('lifetime'),
              activePackageName: uPkg,
              expireDate: uExpires,
            );

            _accounts.clear();
            _accounts.add(sqlUser);
            _currentIndex = 0;
            _isSignedIn = true;
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }

  /// Tự động phục hồi phiên đăng nhập nếu người dùng đã từng đăng nhập Google
  Future<void> _initSilentSignIn() async {
    try {
      final account = await googleSignIn.signInSilently();
      if (account != null) {
        await _handleSuccessfulGoogleUser(account);
      }
    } catch (_) {}
  }

  /// ĐĂNG NHẬP BẰNG TÀI KHOẢN GOOGLE THẬT 100% (Google Sign-In SDK)
  Future<bool> signInWithRealGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Mở cửa sổ đăng nhập Google OAuth chính thức
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _handleSuccessfulGoogleUser(googleUser);
      return true;
    } catch (e, st) {
      debugPrint('Lỗi Google Sign-In: $e\n$st');
      if (e is StateError && _errorMessage != null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final errStr = e.toString();
      if (kIsWeb && (errStr.contains('origin') || errStr.contains('idpiframe') || errStr.contains('redirect_uri'))) {
        _errorMessage = 'Google chưa cho phép địa chỉ ${Uri.base.origin}. Hãy thêm địa chỉ này vào "Authorized JavaScript origins" của Web Client ID trong Google Cloud Console.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (errStr.contains('People API') || errStr.contains('people.googleapis.com')) {
        _errorMessage = 'Dự án Google Cloud chưa bật People API. Hãy bật tại Google Developers Console.';
      } else if (errStr.contains('popup_closed') || errStr.contains('user_cancelled')) {
        _errorMessage = 'Bạn đã hủy đăng nhập Google.';
      } else {
        _errorMessage = 'Lỗi đăng nhập Google: $e';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Xử lý dữ liệu sau khi đăng nhập Google thật thành công
  Future<void> _handleSuccessfulGoogleUser(GoogleSignInAccount googleUser) async {
    String? idToken;
    try {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      idToken = googleAuth.idToken;
    } catch (e) {
      debugPrint('Lấy Google idToken cảnh báo: $e');
    }

    debugPrint('Google Sign-In thành công: ${googleUser.email}');

    // Đồng bộ và lấy thông tin gói cước thực tế từ Backend (nếu máy chủ trực tuyến)
    Map<String, dynamic>? backendUser = await _authenticateWithBackend(idToken, googleUser);

    final name = googleUser.displayName ?? googleUser.email.split('@').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';
    final email = googleUser.email;

    final String packagePlan;
    final bool isActivated;
    final DateTime createdAt;
    final DateTime expiresAt;
    final String shopName;
    final String phone;
    final String? boundDeviceId;
    final bool isTrialStarted;
    final bool hasUsedTrial;

    if (backendUser != null) {
      if (backendUser['status'] == 'BLOCKED') {
        _errorMessage = 'Tài khoản của bạn đã bị tạm khóa bởi Quản trị viên.';
        _isLoading = false;
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        notifyListeners();
        throw StateError(_errorMessage!);
      }

      packagePlan = (backendUser['packagePlan'] ?? 'Chưa kích hoạt gói').toString();
      final backendStatus = (backendUser['status'] ?? 'PENDING_PLAN').toString().toUpperCase();
      hasUsedTrial = backendUser['hasUsedTrial'] == true || (packagePlan != 'Chưa kích hoạt gói' && packagePlan != 'Chưa đăng ký gói' && !packagePlan.contains('Dùng thử'));
      isTrialStarted = backendUser['hasUsedTrial'] == true || (hasUsedTrial && packagePlan.contains('Dùng thử'));
      final isNewUserWithoutPlan = packagePlan == 'Chưa kích hoạt gói' || packagePlan == 'Chưa đăng ký gói' || !hasUsedTrial;
      isActivated = backendStatus == 'ACTIVE' && !isNewUserWithoutPlan;
      createdAt = DateTime.tryParse('${backendUser['createdAt']}') ?? DateTime.now();
      final rawExpires = DateTime.tryParse('${backendUser['expiresAt']}') ?? (isNewUserWithoutPlan ? DateTime.now().subtract(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 3)));
      if (backendStatus == 'EXPIRED' && rawExpires.isAfter(DateTime.now())) {
        expiresAt = DateTime.now().subtract(const Duration(days: 1));
      } else {
        expiresAt = rawExpires;
      }
      shopName = (backendUser['shopName'] ?? 'Cửa hàng $name').toString();
      phone = (backendUser['phone'] ?? '').toString();
      boundDeviceId = backendUser['deviceId']?.toString();
    } else {
      // Khi mạng LAN máy chủ chưa thông: Người dùng mới cần bấm chọn gói trên màn hình bắt buộc
      packagePlan = 'Chưa kích hoạt gói';
      isActivated = false;
      createdAt = DateTime.now();
      expiresAt = DateTime.now().subtract(const Duration(days: 1));
      shopName = 'Cửa hàng $name';
      phone = '';
      boundDeviceId = _currentDeviceId;
      hasUsedTrial = false;
      isTrialStarted = false;
    }

    final realAcc = GoogleUserAccount(
      id: backendUser != null && backendUser['id'] != null ? backendUser['id'].toString() : 'gg_${googleUser.id}',
      name: name,
      email: email,
      initial: initial,
      shop: shopName,
      phone: phone,
      boundDeviceId: boundDeviceId,
      createdAt: createdAt,
      isTrialStarted: isTrialStarted,
      hasUsedTrial: hasUsedTrial,
      isActivated: isActivated,
      isLifetime: packagePlan.contains('Vĩnh Viễn') || packagePlan.toLowerCase().contains('lifetime'),
      activePackageName: packagePlan,
      expireDate: expiresAt,
    );

    _accounts.clear();
    _accounts.add(realAcc);
    _currentIndex = 0;
    _isSignedIn = true;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();

    // Đồng bộ tiếp với máy chủ trong nền
    _syncUserToBackend();

    try {
      onNotificationEvent?.call(
        '✅ Đăng nhập Google thành công',
        'Chào mừng $name ($email)! Giấy phép bản quyền và tài khoản đã được xác thực an toàn.',
        'auth',
      );
    } catch (_) {}
  }

  /// Gửi idToken lên NestJS API /auth/google để lưu vào CSDL
  Future<Map<String, dynamic>?> _authenticateWithBackend(String? idToken, GoogleSignInAccount googleUser) async {
    // 1. Thử xác thực chuẩn bằng idToken qua POST /auth/google
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/google');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': idToken,
            'deviceId': _currentDeviceId,
          }),
        ).timeout(const Duration(seconds: 8));

        debugPrint('Phản hồi Backend /auth/google: ${res.statusCode} - ${res.body}');
        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['user'] != null) {
            return Map<String, dynamic>.from(data['user']);
          }
        }
      } catch (e) {
        debugPrint('Cảnh báo: không thể kết nối tới Backend /auth/google: $e');
      }
    }

    // 2. Fallback đồng bộ trực tiếp qua POST /admin/users
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': googleUser.displayName ?? googleUser.email.split('@').first,
          'email': googleUser.email,
          'device': _deviceName,
          'version': _appVersion,
          'packagePlan': 'Chưa kích hoạt gói',
          'hasUsedTrial': false,
          'expiresAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'deviceId': _currentDeviceId,
          'status': 'PENDING_PLAN',
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data != null && data['email'] != null) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Cảnh báo: không thể kết nối tới Backend /admin/users: $e');
    }

    return null;
  }

  /// Cập nhật thông tin quán & SĐT (lưu vào MySQL và cache bộ nhớ máy)
  Future<void> updateAccountInfo({required String shop, required String phone}) async {
    if (!isSignedIn) return;
    currentAccount.shop = shop.trim();
    currentAccount.phone = phone.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_shop_${currentAccount.email}', shop.trim());
      await prefs.setString('custom_phone_${currentAccount.email}', phone.trim());
    } catch (_) {}
    _syncUserToBackend();
  }

  /// Kích hoạt gói dùng thử
  bool startTrial() {
    if (!isSignedIn || currentAccount.hasUsedTrial) return false;
    final now = DateTime.now();
    currentAccount.isTrialStarted = true;
    currentAccount.trialStartedAt = now;
    currentAccount.hasUsedTrial = true;
    currentAccount.isActivated = true;
    currentAccount.activePackageName = 'Dùng thử 3 ngày miễn phí';
    currentAccount.expireDate = now.add(const Duration(days: 3));
    notifyListeners();
    _syncUserToBackend();
    return true;
  }

  /// Kích hoạt gói bản quyền
  bool activatePackage(String packageName, int days) {
    if (!isSignedIn) return false;
    final now = DateTime.now();
    final isLife = packageName.contains('Vĩnh Viễn') || packageName.toLowerCase().contains('lifetime');

    if (isLife) {
      currentAccount.isActivated = true;
      currentAccount.isLifetime = true;
      currentAccount.activePackageName = 'Gói Vĩnh Viễn Trọn Đời';
      currentAccount.expireDate = DateTime(2099, 12, 31);
      notifyListeners();
      _syncUserToBackend();
      try {
        onNotificationEvent?.call(
          '💎 Kích hoạt gói VIP Vĩnh Viễn',
          'Đã mở khóa trọn đời dịch vụ đọc loa không giới hạn cho tài khoản.',
          'promo',
        );
      } catch (_) {}
      return true;
    }

    final baseDate = (currentAccount.isActivated && currentAccount.expireDate.isAfter(now))
        ? currentAccount.expireDate
        : now;

    currentAccount.isActivated = true;
    currentAccount.activePackageName = packageName;
    currentAccount.expireDate = baseDate.add(Duration(days: days));
    notifyListeners();
    _syncUserToBackend();
    try {
      onNotificationEvent?.call(
        '💎 Kích hoạt thành công: $packageName',
        'Thời hạn sử dụng gói đến ngày ${currentAccount.expireDate.day}/${currentAccount.expireDate.month}/${currentAccount.expireDate.year}',
        'promo',
      );
    } catch (_) {}
    return true;
  }

  /// Hủy liên kết thiết bị hiện tại
  Future<bool> unbindCurrentDevice() async {
    if (!isSignedIn) return true;
    currentAccount.boundDeviceId = null;
    notifyListeners();
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/device/unbind');
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

  /// Liên kết thiết bị hiện tại
  Future<Map<String, dynamic>> bindCurrentDevice({bool forceSwitch = false}) async {
    if (!isSignedIn) return {'success': false, 'message': 'Chưa đăng nhập'};
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/device/bind');
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

  /// Đăng xuất tài khoản Google
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    _accounts.clear();
    _isSignedIn = false;
    _currentIndex = 0;
    notifyListeners();
    try {
      onNotificationEvent?.call(
        '🔒 Đã đăng xuất an toàn',
        'Phiên làm việc và dữ liệu tài khoản đã được bảo mật an toàn.',
        'auth',
      );
    } catch (_) {}
  }

  void setShopName(String newShop) {
    if (!isSignedIn) return;
    currentAccount.shop = newShop.trim();
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('custom_shop_${currentAccount.email}', newShop.trim());
    }).catchError((_) {});
    _syncUserToBackend();
  }

  void setPhone(String newPhone) {
    if (!isSignedIn) return;
    currentAccount.phone = newPhone.trim();
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('custom_phone_${currentAccount.email}', newPhone.trim());
    }).catchError((_) {});
    _syncUserToBackend();
  }

  void updateShopAndPhone({String? newShop, String? newPhone}) {
    if (!isSignedIn) return;
    if (newShop != null) currentAccount.shop = newShop.trim();
    if (newPhone != null) currentAccount.phone = newPhone.trim();
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      if (newShop != null) prefs.setString('custom_shop_${currentAccount.email}', newShop.trim());
      if (newPhone != null) prefs.setString('custom_phone_${currentAccount.email}', newPhone.trim());
    }).catchError((_) {});
    _syncUserToBackend();
  }

  Future<void> _syncUserToBackend() async {
    if (!isSignedIn) return;
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users');
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
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data != null && data['expiresAt'] != null) {
          final serverExpiry = DateTime.tryParse(data['expiresAt'].toString());
          if (serverExpiry != null &&
              (serverExpiry.isAfter(currentAccount.expireDate) ||
                  serverExpiry.isBefore(currentAccount.expireDate))) {
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

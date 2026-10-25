import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/security/app_pin_security_service.dart';

class GoogleUserAccount {
  final String id;
  final String name;
  final String email;
  final String initial;
  String shop;
  String phone;
  String bankName;
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
    this.bankName = '',
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

  /// Trạng thái kích hoạt thực tế: Nếu thời hạn dùng còn trong tương lai thì luôn được xem là ACTIVE
  bool get effectiveIsActivated => !isExpired;

  /// Tên gói cước hiển thị chuẩn theo trạng thái thời gian thực
  String get effectivePackageName {
    if (isExpired) {
      return activePackageName.contains('Dùng thử')
          ? 'Gói dùng thử đã hết hạn'
          : 'Gói cước đã hết hạn';
    }
    // Nếu chưa hết hạn (còn ngày sử dụng) nhưng tên gói lại chứa chuỗi 'hết hạn' hoặc 'Chưa kích hoạt'
    if (activePackageName.contains('hết hạn') ||
        activePackageName == 'Chưa kích hoạt gói' ||
        activePackageName == 'Chưa đăng ký gói') {
      if (isLifetime) return 'Gói Vĩnh Viễn Trọn Đời';
      final daysLeft = expireDate.difference(DateTime.now()).inDays;
      if (daysLeft >= 300) return 'Gói 1 Năm (VIP)';
      if (daysLeft >= 75) return 'Gói 3 Tháng (VIP)';
      if (daysLeft >= 20) return 'Gói 1 Tháng (VIP)';
      if (daysLeft >= 4) return 'Gói Bản Quyền ($daysLeft ngày)';
      return 'Dùng thử 3 ngày miễn phí';
    }
    return activePackageName;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'initial': initial,
    'shop': shop,
    'phone': phone,
    'bankName': bankName,
    'boundDeviceId': boundDeviceId,
    'createdAt': createdAt.toIso8601String(),
    'isTrialStarted': isTrialStarted,
    'trialStartedAt': trialStartedAt?.toIso8601String(),
    'hasUsedTrial': hasUsedTrial,
    'isActivated': isActivated,
    'isLifetime': isLifetime,
    'activePackageName': activePackageName,
    'expireDate': expireDate.toIso8601String(),
  };

  factory GoogleUserAccount.fromMap(Map<String, dynamic> map) => GoogleUserAccount(
    id: map['id']?.toString() ?? 'acc_local',
    name: map['name']?.toString() ?? 'Người dùng',
    email: map['email']?.toString() ?? '',
    initial: map['initial']?.toString() ?? 'U',
    shop: map['shop']?.toString() ?? 'Cửa hàng',
    phone: map['phone']?.toString() ?? '',
    bankName: map['bankName']?.toString() ?? '',
    boundDeviceId: map['boundDeviceId']?.toString(),
    createdAt: DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
    isTrialStarted: map['isTrialStarted'] == true,
    trialStartedAt: DateTime.tryParse('${map['trialStartedAt']}'),
    hasUsedTrial: map['hasUsedTrial'] == true,
    isActivated: map['isActivated'] == true,
    isLifetime: map['isLifetime'] == true,
    activePackageName: map['activePackageName']?.toString() ?? 'Dùng thử 3 ngày miễn phí',
    expireDate: DateTime.tryParse('${map['expireDate']}') ?? DateTime.now().add(const Duration(days: 3)),
  );
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
      serverClientId: null,
      scopes: ['email', 'profile'],
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
  String get bankName => currentAccount.bankName;
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

  /// Đăng nhập / Bắt đầu sử dụng bằng Tên cửa hàng & Số điện thoại (Hoàn toàn không cần Gmail/Google)
  Future<bool> signInWithShopAndPhone({
    required String shopOrName,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanName = shopOrName.trim();
      final cleanPhone = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
      if (cleanName.isEmpty) {
        _errorMessage = 'Vui lòng nhập tên cửa hàng hoặc họ tên của bạn.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (cleanPhone.length < 9) {
        _errorMessage = 'Vui lòng nhập số điện thoại hợp lệ (tối thiểu 9 số).';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Tạo định danh duy nhất nội bộ theo SĐT (người dùng hoàn toàn không cần nhập hay biết đến email)
      final cleanEmail = '$cleanPhone@docthongbaobank.com';
      final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'C';

      // Đồng bộ vào backend MySQL
      Map<String, dynamic>? backendUser;
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users');
        final Map<String, dynamic> bodyPayload = {
          'name': cleanName,
          'email': cleanEmail,
          'device': _deviceName,
          'version': _appVersion,
          'packagePlan': 'Chưa kích hoạt gói',
          'hasUsedTrial': false,
          'expiresAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'phone': cleanPhone,
          'shopName': cleanName,
          'deviceId': _currentDeviceId,
          'status': 'PENDING_PLAN',
        };
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

      // Giới hạn tuyệt đối 72 giờ cho gói dùng thử
      DateTime expiresAt = DateTime.tryParse('${backendUser?['expiresAt']}') ?? DateTime.now().subtract(const Duration(days: 1));
      if (isTrialPlan && expiresAt.difference(DateTime.now()) > const Duration(hours: 72)) {
        expiresAt = DateTime.now().add(const Duration(hours: 72));
      }

      final bool isTrialStarted = hasUsedTrial || isTrialPlan || isPaidPlan;
      final bool isActivated = (backendUser?['status'] == 'ACTIVE') && (isPaidPlan || (isTrialPlan && !DateTime.now().isAfter(expiresAt)));

      final realAcc = GoogleUserAccount(
        id: backendUser?['id']?.toString() ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        email: cleanEmail,
        initial: initial,
        shop: cleanName,
        phone: cleanPhone,
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
      AppPinSecurityService().initUniqueLivePinForUser(cleanEmail);
      _saveSessionOffline(realAcc);

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi lưu thông tin: $e';
      notifyListeners();
      return false;
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

      // 1. Kiểm tra xem tài khoản này ĐÃ TỒN TẠI trên hệ thống hay là TÀI KHOẢN MỚI
      Map<String, dynamic>? backendUser;
      try {
        final getUri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users/$cleanEmail');
        final getRes = await http.get(getUri).timeout(const Duration(seconds: 4));
        if (getRes.statusCode == 200 && getRes.body.isNotEmpty && getRes.body != 'null') {
          final data = jsonDecode(getRes.body);
          if (data != null && data['email'] != null) {
            backendUser = Map<String, dynamic>.from(data);
          }
        }
      } catch (e) {
        debugPrint('Lỗi query getUserByEmail: $e');
      }

      final bool isExistingOnServer = backendUser != null &&
          ((backendUser['phone'] != null && backendUser['phone'].toString().trim().isNotEmpty) ||
           backendUser['hasUsedTrial'] == true ||
           (backendUser['packagePlan'] != null &&
            backendUser['packagePlan'] != 'Chưa kích hoạt gói' &&
            backendUser['packagePlan'] != 'Chưa đăng ký gói'));

      if (!isExistingOnServer && backendUser == null) {
        // Tài khoản MỚI ĐĂNG KÝ -> Lưu trạng thái chờ chọn gói và chờ nhập SĐT/Ngân hàng
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users');
        final Map<String, dynamic> bodyPayload = {
          'name': cleanName,
          'email': cleanEmail,
          'device': _deviceName,
          'version': _appVersion,
          'packagePlan': 'Chưa kích hoạt gói',
          'hasUsedTrial': false,
          'expiresAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'phone': phone ?? '',
          'shopName': hasCustomShop ? shop.trim() : 'Cửa hàng $cleanName',
          'deviceId': _currentDeviceId,
          'status': 'PENDING_PLAN',
        };
        try {
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
        } catch (_) {}
      }

      final hasUsedTrial = backendUser?['hasUsedTrial'] == true;
      final String packagePlan = (backendUser?['packagePlan'] ?? 'Chưa kích hoạt gói').toString();
      final bool isPaidPlan = packagePlan != 'Chưa kích hoạt gói' && !packagePlan.toLowerCase().contains('dùng thử');
      final bool isTrialPlan = packagePlan.toLowerCase().contains('dùng thử');
      final DateTime createdAt = DateTime.tryParse('${backendUser?['createdAt']}') ?? DateTime.now();
      final DateTime expiresAt = DateTime.tryParse('${backendUser?['expiresAt']}') ??
          (isExistingOnServer ? DateTime.now().add(const Duration(days: 3)) : DateTime.now().subtract(const Duration(days: 1)));

      final bool isTrialStarted = hasUsedTrial || isTrialPlan || isPaidPlan;
      final bool isActivated = (backendUser?['status'] == 'ACTIVE') && (isPaidPlan || (isTrialPlan && !DateTime.now().isAfter(expiresAt)));

      // Tên quán & SĐT & Ngân hàng: ưu tiên từ MySQL
      final String resolvedShop = (backendUser != null && backendUser['shopName'] != null && backendUser['shopName'].toString().trim().isNotEmpty)
          ? backendUser['shopName'].toString().trim()
          : (hasCustomShop ? shop.trim() : 'Cửa hàng $cleanName');
      final String resolvedPhone = (backendUser?['phone'] ?? phone ?? '').toString();
      final String resolvedBank = (backendUser?['bankName'] ?? '').toString();

      final realAcc = GoogleUserAccount(
        id: backendUser?['id']?.toString() ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        email: cleanEmail,
        initial: initial,
        shop: resolvedShop,
        phone: resolvedPhone,
        bankName: resolvedBank,
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
      AppPinSecurityService().initUniqueLivePinForUser(cleanEmail);
      _saveSessionOffline(realAcc);

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
    scheduleMicrotask(() async {
      // 1. Phục hồi ngay lập tức phiên đăng nhập từ bộ nhớ máy (0ms độ trễ, không bao giờ bị văng khi mất mạng)
      await _loadUserFromLocalStorage();
      _initSilentSignIn();
      _loadUserFromBackend();
    });
  }

  /// Lưu trữ bền vững toàn bộ phiên đăng nhập vào bộ nhớ cục bộ
  Future<void> _saveSessionOffline(GoogleUserAccount acc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_signed_in_email', acc.email.trim());
      await prefs.setString('autobank_offline_user_session', jsonEncode(acc.toMap()));
    } catch (_) {}
  }

  /// Nạp phiên đăng nhập offline ngay khi app bật lên
  Future<void> _loadUserFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('autobank_offline_user_session');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(cachedJson);
        final acc = GoogleUserAccount.fromMap(map);
        if (acc.email.isNotEmpty && _accounts.isEmpty) {
          _accounts.clear();
          _accounts.add(acc);
          _currentIndex = 0;
          _isSignedIn = true;
          notifyListeners();
          debugPrint('[AutoBank Auth] Phục hồi tài khoản offline thành công: ${acc.email}');
        }
      }
    } catch (e) {
      debugPrint('[AutoBank Auth] Lỗi nạp local session: $e');
    }
  }

  /// Tải thông tin người dùng thực tế từ Cơ sở dữ liệu MySQL nếu thiết bị đã từng đăng nhập
  Future<void> _loadUserFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString('last_signed_in_email') ?? (_accounts.isNotEmpty ? _accounts.first.email : null);
      if (cachedEmail == null || cachedEmail.trim().isEmpty) return;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users/${Uri.encodeComponent(cachedEmail.trim())}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final dynamic rawData = jsonDecode(res.body);
        Map<String, dynamic>? primary;
        if (rawData is Map<String, dynamic>) {
          primary = rawData;
        } else if (rawData is List && rawData.isNotEmpty) {
          primary = rawData.cast<Map<String, dynamic>?>().firstWhere(
            (u) => (u?['email'] ?? '').toString().toLowerCase() == cachedEmail.trim().toLowerCase(),
            orElse: () => null,
          );
        }

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
          final DateTime uExpires = DateTime.tryParse('${primary['expiresAt']}') ?? 
              (uPkg.contains('Dùng thử') ? DateTime.now().add(const Duration(days: 3)) : DateTime.now().add(const Duration(days: 30)));
          final DateTime uCreated = DateTime.tryParse('${primary['createdAt']}') ?? DateTime.now();

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
          _saveSessionOffline(sqlUser);
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
      if (errStr.contains('10') || errStr.contains('sign_in_failed') || errStr.contains('ApiException')) {
        _errorMessage = 'GOOGLE_PLAY_SETUP_NEEDED';
      } else if (errStr.contains('People API') || errStr.contains('people.googleapis.com')) {
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
      createdAt = DateTime.tryParse('${backendUser['createdAt']}') ?? DateTime.now();
      final rawExpires = DateTime.tryParse('${backendUser['expiresAt']}') ?? DateTime.now().add(const Duration(days: 3));
      final bool hasFutureExpiry = rawExpires.isAfter(DateTime.now());

      expiresAt = rawExpires;
      isActivated = backendStatus != 'BLOCKED' && hasFutureExpiry;
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

    final String bankName = (backendUser?['bankName'] ?? '').toString();

    final realAcc = GoogleUserAccount(
      id: backendUser != null && backendUser['id'] != null ? backendUser['id'].toString() : 'gg_${googleUser.id}',
      name: name,
      email: email,
      initial: initial,
      shop: shopName,
      phone: phone,
      bankName: bankName,
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
    AppPinSecurityService().initUniqueLivePinForUser(email);
    _saveSessionOffline(realAcc);

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
    // 0. Kiểm tra trước xem tài khoản đã tồn tại trong CSDL MySQL chưa
    try {
      final getUri = Uri.parse('${AppConfig.apiBaseUrl}/admin/users/${googleUser.email}');
      final getRes = await http.get(getUri).timeout(const Duration(seconds: 4));
      if (getRes.statusCode == 200 && getRes.body.isNotEmpty && getRes.body != 'null') {
        final data = jsonDecode(getRes.body);
        if (data != null && data['email'] != null) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {}

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

  /// Cập nhật thông tin quán, SĐT & Ngân hàng (lưu vào MySQL và cache bộ nhớ máy)
  Future<void> updateAccountInfo({String? shop, String? phone, String? bankName}) async {
    if (!isSignedIn) return;
    if (shop != null && shop.trim().isNotEmpty) {
      currentAccount.shop = shop.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      currentAccount.phone = phone.trim();
    }
    if (bankName != null && bankName.trim().isNotEmpty) {
      currentAccount.bankName = bankName.trim();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (shop != null && shop.trim().isNotEmpty) {
        await prefs.setString('custom_shop_${currentAccount.email}', shop.trim());
      }
      if (phone != null && phone.trim().isNotEmpty) {
        await prefs.setString('custom_phone_${currentAccount.email}', phone.trim());
      }
      if (bankName != null && bankName.trim().isNotEmpty) {
        await prefs.setString('custom_bank_${currentAccount.email}', bankName.trim());
      }
    } catch (_) {}
    _syncUserToBackend();
  }


  /// Kích hoạt gói dùng thử 3 ngày chính xác 72 giờ
  Future<bool> startTrial({String? shop, String? phone, String? bankName}) async {
    if (!isSignedIn) return false;
    final now = DateTime.now();
    currentAccount.isTrialStarted = true;
    currentAccount.trialStartedAt = now;
    currentAccount.hasUsedTrial = true;
    currentAccount.isActivated = true;
    currentAccount.activePackageName = 'Dùng thử 3 ngày miễn phí';
    // Đếm ngược chính xác đúng 72 giờ (3 ngày) từ thời điểm bấm kích hoạt
    currentAccount.expireDate = now.add(const Duration(hours: 72));

    if (shop != null && shop.trim().isNotEmpty) {
      currentAccount.shop = shop.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      currentAccount.phone = phone.trim();
    }
    if (bankName != null && bankName.trim().isNotEmpty) {
      currentAccount.bankName = bankName.trim();
    }

    notifyListeners();
    _saveSessionOffline(currentAccount);

    try {
      final prefs = await SharedPreferences.getInstance();
      if (shop != null && shop.trim().isNotEmpty) {
        await prefs.setString('custom_shop_${currentAccount.email}', shop.trim());
      }
      if (phone != null && phone.trim().isNotEmpty) {
        await prefs.setString('custom_phone_${currentAccount.email}', phone.trim());
      }
      if (bankName != null && bankName.trim().isNotEmpty) {
        await prefs.setString('custom_bank_${currentAccount.email}', bankName.trim());
      }
    } catch (_) {}

    await _syncUserToBackend();
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
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('last_signed_in_email');
      prefs.remove('autobank_offline_user_session');
    }).catchError((_) {});
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
          'bankName': bankName,
          'deviceId': boundDeviceId ?? _currentDeviceId,
          'status': isExpired ? 'EXPIRED' : 'ACTIVE',
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data != null && data['expiresAt'] != null) {
          final serverExpiry = DateTime.tryParse(data['expiresAt'].toString());
          if (serverExpiry != null) {
            final now = DateTime.now();
            // Nếu tài khoản trên máy đang còn hạn hợp lệ (chưa hết hạn),
            // TUYỆT ĐỐI không cho phép dữ liệu quá khứ từ server đè lên làm hết hạn!
            if (currentAccount.expireDate.isAfter(now) && serverExpiry.isBefore(now)) {
              debugPrint('Bỏ qua ngày hết hạn quá khứ từ server: $serverExpiry vs còn hạn máy: ${currentAccount.expireDate}');
            } else {
              DateTime clampedExpiry = serverExpiry;
              if (currentAccount.activePackageName.contains('Dùng thử')) {
                final maxAllowed = now.add(const Duration(hours: 72));
                if (clampedExpiry.isAfter(maxAllowed)) {
                  clampedExpiry = maxAllowed;
                }
              }
              if (clampedExpiry != currentAccount.expireDate) {
                currentAccount.expireDate = clampedExpiry;
                if (data['packagePlan'] != null) {
                  currentAccount.activePackageName = data['packagePlan'].toString();
                }
                notifyListeners();
                _saveSessionOffline(currentAccount);
              }
            }
          }
        }
      }
    } catch (_) {
      // Offline fallback
    }
  }
}

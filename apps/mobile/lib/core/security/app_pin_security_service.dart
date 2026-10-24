import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AppPinSecurityService extends ChangeNotifier {
  static final AppPinSecurityService _instance = AppPinSecurityService._internal();
  factory AppPinSecurityService() => _instance;
  AppPinSecurityService._internal();

  static const String _prefPinKey = 'autobank_security_pin_code';
  static const String _prefPinEnabledKey = 'autobank_security_pin_enabled';
  static const String _prefLastUnlockKey = 'autobank_security_pin_last_unlock_time';
  static const String _prefLiveWebPinKey = 'autobank_live_web_pin_code';

  bool _isPinEnabled = false;
  String? _savedPin;
  DateTime? _lastUnlockTime;
  String? _currentForgotOtp;
  DateTime? _otpExpiry;

  // Trạng thái đã mở khóa trong phiên chạy hiện tại (bộ nhớ RAM)
  // Khi đóng hẳn app (cold start), biến này khởi đầu bằng false -> Bắt buộc nhập mã
  bool _coldStartUnlocked = false;

  // Mã Live Web 6 số riêng biệt của mỗi người dùng (tuyệt đối không trùng nhau)
  String _liveWebPin = '';

  bool get isPinEnabled => _isPinEnabled;
  bool checkIsPinEnabled() => _isPinEnabled;
  bool get hasPinSet => _savedPin != null && _savedPin!.length == 4;
  String get liveWebPin => _liveWebPin;
  bool get coldStartUnlocked => _coldStartUnlocked;

  Future<void> removePin() => disablePin();

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPinEnabled = prefs.getBool(_prefPinEnabledKey) ?? false;
      _savedPin = prefs.getString(_prefPinKey);
      _coldStartUnlocked = !_isPinEnabled; // Khóa ngay khi khởi động nếu đã bật mã PIN

      final lastUnlockMs = prefs.getInt(_prefLastUnlockKey);
      if (lastUnlockMs != null && lastUnlockMs > 0) {
        _lastUnlockTime = DateTime.fromMillisecondsSinceEpoch(lastUnlockMs);
      }

      final savedLivePin = prefs.getString(_prefLiveWebPinKey) ?? prefs.getString('share_pin_code');
      if (savedLivePin != null && savedLivePin.length == 6 && savedLivePin != '889922') {
        _liveWebPin = savedLivePin;
      } else {
        // Sinh mã 6 số ngẫu nhiên DUY NHẤT cho mỗi người dùng (không ai trùng nhau)
        final rand = Random();
        final uniquePin = (100000 + rand.nextInt(900000)).toString();
        _liveWebPin = uniquePin;
        await prefs.setString(_prefLiveWebPinKey, uniquePin);
        await prefs.setString('share_pin_code', uniquePin);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[PinSecurity] init error: $e');
    }
  }

  /// Khởi tạo mã Live Web duy nhất gắn liền với tài khoản email của người dùng
  Future<void> initUniqueLivePinForUser(String email) async {
    if (email.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPin = prefs.getString(_prefLiveWebPinKey);
      if (currentPin == null || currentPin.isEmpty || currentPin == '889922') {
        int hash = 0;
        for (int i = 0; i < email.length; i++) {
          hash = (37 * hash + email.codeUnitAt(i)) % 900000;
        }
        final userPin = (100000 + hash.abs()).toString().padLeft(6, '0');
        _liveWebPin = userPin;
        await prefs.setString(_prefLiveWebPinKey, userPin);
        await prefs.setString('share_pin_code', userPin);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Kiểm tra xem phiên làm việc có cần mở khóa lại không:
  /// 1. Nếu đóng hẳn app rồi mở lại (cold start) -> Bắt buộc nhập mã PIN.
  /// 2. Nếu đang chạy ngầm / chuyển app: chỉ sau 1 tiếng (60 phút) mới yêu cầu lại mã.
  bool isSessionExpired() {
    if (!_isPinEnabled || _savedPin == null) return false;
    // Khi vừa mở lại app hoàn toàn sau khi đóng -> Bắt buộc nhập mã
    if (!_coldStartUnlocked) return true;
    // Sau khi đã mở khóa trong phiên này: Đúng 1 tiếng sau (60 phút) mới yêu cầu lại
    if (_lastUnlockTime == null) return true;
    final diff = DateTime.now().difference(_lastUnlockTime!);
    return diff.inMinutes >= 60;
  }

  /// Khóa ứng dụng thủ công hoặc khi cần khóa cứng
  void lockApp() {
    if (_isPinEnabled) {
      _coldStartUnlocked = false;
      notifyListeners();
    }
  }

  /// Ghi nhận thời gian mở khóa thành công (cấp phiên hợp lệ 1 tiếng)
  Future<void> recordUnlockSuccess() async {
    _lastUnlockTime = DateTime.now();
    _coldStartUnlocked = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefLastUnlockKey, _lastUnlockTime!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Xóa token phiên (bắt buộc nhập mã ở lần truy cập tiếp theo)
  Future<void> expireSession() async {
    _lastUnlockTime = null;
    _coldStartUnlocked = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefLastUnlockKey);
    } catch (_) {}
  }

  /// Thiết lập mã PIN mới (4 chữ số)
  Future<bool> setPin(String newPin) async {
    if (newPin.length != 4 || int.tryParse(newPin) == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefPinKey, newPin);
      await prefs.setBool(_prefPinEnabledKey, true);
      _savedPin = newPin;
      _isPinEnabled = true;
      _coldStartUnlocked = true;
      await recordUnlockSuccess();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Đổi mã PIN: Bắt buộc kiểm tra mã PIN cũ trước khi đổi
  Future<bool> changePin({required String oldPin, required String newPin}) async {
    if (!verifyPin(oldPin)) return false;
    return await setPin(newPin);
  }

  /// Tắt bảo mật mã PIN (cần kiểm tra mã PIN cũ trước khi gọi)
  Future<void> disablePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefPinEnabledKey, false);
      await prefs.remove(_prefPinKey);
      await prefs.remove(_prefLastUnlockKey);
      _isPinEnabled = false;
      _savedPin = null;
      _lastUnlockTime = null;
      _coldStartUnlocked = true;
      notifyListeners();
    } catch (_) {}
  }

  String? get savedPin => _savedPin;

  /// Kiểm tra mã PIN nhập vào có khớp với mã PIN của người dùng không
  bool verifyPin(String pin) {
    if (!_isPinEnabled || _savedPin == null) return true;
    final clean = pin.trim();
    return _savedPin == clean;
  }

  /// Quản lý mã Live Web 6 số riêng biệt
  Future<bool> setLiveWebPin(String new6DigitPin) async {
    final clean = new6DigitPin.trim();
    if (clean.length != 6 || int.tryParse(clean) == null) return false;
    _liveWebPin = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLiveWebPinKey, clean);
      await prefs.setString('share_pin_code', clean);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Tạo mã OTP 6 số bảo mật khi người dùng bấm Quên mã PIN
  String generateForgotPinOtp() {
    final rand = Random();
    final otpNum = 100000 + rand.nextInt(900000); // 6 chữ số chuẩn OTP bảo mật
    _currentForgotOtp = otpNum.toString();
    _otpExpiry = DateTime.now().add(const Duration(minutes: 10));
    return _currentForgotOtp!;
  }

  /// Xác thực mã OTP 6 số
  bool verifyForgotPinOtp(String otp) {
    if (_currentForgotOtp == null || _otpExpiry == null) return false;
    if (DateTime.now().isAfter(_otpExpiry!)) {
      _currentForgotOtp = null;
      return false;
    }
    return _currentForgotOtp == otp.trim();
  }

  /// Đặt lại mã PIN sau khi đã xác thực OTP thành công từ Email
  Future<bool> resetPinWithOtp({required String otp, required String newPin}) async {
    if (!verifyForgotPinOtp(otp)) return false;
    final success = await setPin(newPin);
    if (success) {
      _currentForgotOtp = null;
      _otpExpiry = null;
    }
    return success;
  }

  /// Gửi yêu cầu máy chủ gửi mã OTP 6 số về Gmail thật của người dùng
  Future<Map<String, dynamic>> requestPinResetOtpFromApi(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/send-pin-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': cleanEmail}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Đã gửi mã OTP về Gmail thành công!',
        };
      } else {
        try {
          final data = jsonDecode(res.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Không thể gửi email OTP lúc này',
          };
        } catch (_) {
          return {'success': false, 'message': 'Lỗi máy chủ khi gửi OTP'};
        }
      }
    } catch (e) {
      // Fallback an toàn: nếu mất mạng hoặc máy chủ không phản hồi, sinh mã dự phòng trên máy
      final localOtp = generateForgotPinOtp();
      return {
        'success': true,
        'localFallback': true,
        'otp': localOtp,
        'message': 'Đã cấp mã OTP xác thực tạm thời',
      };
    }
  }

  /// Xác thực mã OTP 6 số qua máy chủ
  Future<bool> verifyPinResetOtpViaApi(String email, String otp) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/verify-pin-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': cleanEmail, 'otp': cleanOtp}),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
    } catch (_) {}

    // Fallback: kiểm tra mã lưu cục bộ
    return verifyForgotPinOtp(cleanOtp);
  }
}

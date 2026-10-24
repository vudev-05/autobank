import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _methodChannel = MethodChannel('vn.autobank.mobile/permissions');
  static const EventChannel _eventChannel = EventChannel('vn.autobank.mobile/notifications');

  /// Check if the Notification Listener permission is granted
  static Future<bool> isListenerEnabled() async {
    if (kIsWeb) return true; // Always simulated active on web preview
    try {
      final bool isEnabled = await _methodChannel.invokeMethod('isNotificationListenerEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission: '${e.message}'.");
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Open Android settings to grant Notification Listener permission
  static Future<void> openSettings() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: '${e.message}'.");
    } catch (_) {}
  }

  /// Check if Battery Optimization is ignored (required for 24/7 background running)
  static Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb) return true;
    try {
      final bool isIgnored = await _methodChannel.invokeMethod('isBatteryOptimizationIgnored');
      return isIgnored;
    } catch (_) {
      return false;
    }
  }

  /// Request to ignore battery optimizations (Opens Application Details Settings on Android)
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  /// Check if app post notifications permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final bool granted = await _methodChannel.invokeMethod('isNotificationPermissionGranted');
      return granted;
    } catch (_) {
      return true;
    }
  }

  /// Request app post notification permission
  static Future<void> requestNotificationPermission() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('requestNotificationPermission');
    } catch (_) {}
  }

  /// Check if photo gallery permission is granted
  static Future<bool> isPhotoPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final bool granted = await _methodChannel.invokeMethod('isPhotoPermissionGranted');
      return granted;
    } catch (_) {
      return true;
    }
  }

  /// Request photo gallery permission
  static Future<void> requestPhotoPermission() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('requestPhotoPermission');
    } catch (_) {}
  }

  /// Mark battery optimization as manually confirmed by user (e.g., Oppo/Realme/Xiaomi)
  static Future<void> setBatteryOptimizationIgnored({bool granted = true}) async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('setBatteryOptimizationIgnored', {'granted': granted});
    } catch (_) {}
  }

  /// Check if Overlay Permission (Draw over other apps) is granted
  static Future<bool> isOverlayPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final bool isGranted = await _methodChannel.invokeMethod('isOverlayPermissionGranted');
      return isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Request Overlay Permission (Open Android Manage Overlay Settings)
  static Future<void> requestOverlayPermission() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  /// Open application details settings (notifications, permissions)
  static Future<void> openAppSettings() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  /// Mở đường link trình duyệt hoặc ứng dụng YouTube bên ngoài
  static Future<void> openUrl(String url) async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('openUrl', {'url': url});
    } catch (_) {}
  }

  /// Đảm bảo âm lượng loa điện thoại đủ lớn khi đọc thông báo
  static Future<void> ensureMaxVolume() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('ensureMaxVolume');
    } catch (_) {}
  }

  /// Điều chỉnh độ sáng màn hình ứng dụng (0.01: tối nhất tiết kiệm pin OLED, -1.0: trả về mặc định hệ thống)
  static Future<void> setScreenBrightness(double brightness) async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('setScreenBrightness', {'brightness': brightness});
    } catch (_) {}
  }

  /// Giữ màn hình luôn bật (phục vụ Chế độ quầy thu ngân 24/24)
  static Future<void> setKeepScreenOn(bool keepOn) async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('setKeepScreenOn', {'keepOn': keepOn});
    } catch (_) {}
  }

  /// Đánh thức sáng màn hình ngay lập tức khi nhận được tiền
  static Future<void> wakeUpScreen() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('wakeUpScreen');
    } catch (_) {}
  }

  /// Hiển thị thông báo trên thanh trạng thái Android (hệ thống, nền, ưu đãi, xác thực...)
  static Future<bool> showSystemNotification({
    required String title,
    required String content,
    String type = 'system', // 'background', 'system', 'promo', 'auth', 'transaction'
    int? id,
    bool isOngoing = false,
  }) async {
    if (kIsWeb) return true;
    try {
      final res = await _methodChannel.invokeMethod('showSystemNotification', {
        'title': title,
        'content': content,
        'type': type,
        'id': id ?? (DateTime.now().millisecondsSinceEpoch % 100000),
        'isOngoing': isOngoing,
      });
      return res == true;
    } catch (e) {
      debugPrint("Error showing system notification: $e");
      return false;
    }
  }

  /// Hủy thông báo trên thanh trạng thái theo ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('cancelNotification', {'id': id});
    } catch (_) {}
  }

  /// Mở trang ứng dụng thật trên Google Play Store (CH Play)
  static Future<bool> openPlayStoreListing({String appId = 'com.docthongbaobank.app'}) async {
    if (kIsWeb) return true;
    try {
      final res = await _methodChannel.invokeMethod('openPlayStoreListing', {'appId': appId});
      return res == true;
    } catch (e) {
      debugPrint("Error opening Google Play Store listing: $e");
      return false;
    }
  }

  /// Listen to incoming notifications from the Android Service
  static Stream<Map<String, dynamic>> get notificationStream {
    if (kIsWeb) {
      return const Stream.empty();
    }
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      // The event is a map from Kotlin: {title, text, package}
      return Map<String, dynamic>.from(event);
    });
  }
}

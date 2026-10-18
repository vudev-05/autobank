import 'package:flutter/foundation.dart';

/// Cấu hình tập trung cho toàn bộ ứng dụng AutoBank Mobile
class AppConfig {
  /// Địa chỉ IP máy tính Backend trong mạng LAN (IP Wi-Fi hiện tại)
  static const String serverHost = '192.168.1.217';
  static const int apiPort = 3000;
  static const int webPort = 5173;

  /// Cho phép cập nhật động từ Cấu hình Tên Miền trên Web Admin
  static String? _dynamicApiBaseUrl;
  static String? _dynamicWebBaseUrl;

  static void updateDomains({String? apiDomain, String? webDomain}) {
    if (apiDomain != null && apiDomain.trim().isNotEmpty) {
      _dynamicApiBaseUrl = apiDomain.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (webDomain != null && webDomain.trim().isNotEmpty) {
      _dynamicWebBaseUrl = webDomain.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }

  /// Lấy Base URL của NestJS API tuỳ theo nền tảng đang chạy hoặc tên miền cấu hình động
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Khi chạy Flutter Web trên cùng máy tính, luôn trỏ về backend local
      return 'http://localhost:$apiPort';
    }
    if (_dynamicApiBaseUrl != null && _dynamicApiBaseUrl!.isNotEmpty) {
      return _dynamicApiBaseUrl!;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Chạy trên điện thoại thật dùng IP LAN
        return 'http://$serverHost:$apiPort';
      case TargetPlatform.iOS:
        return 'http://$serverHost:$apiPort';
      default:
        return 'http://localhost:$apiPort';
    }
  }

  /// Web URL để tạo link chia sẻ đơn hàng / live sync
  static String get webBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$webPort';
    }
    if (_dynamicWebBaseUrl != null && _dynamicWebBaseUrl!.isNotEmpty) {
      return _dynamicWebBaseUrl!;
    }
    return 'http://$serverHost:$webPort';
  }

  /// Google Web Client ID (dùng để yêu cầu idToken từ Google Sign-In SDK)
  static const String googleWebClientId =
      '326124862102-oddd2tnbc6he6fk820bc15n3kpte3uo6.apps.googleusercontent.com';

  /// Google Android Client ID (dành riêng cho ứng dụng Android)
  static const String googleAndroidClientId =
      '326124862102-mbibb162b8dp9fnoqij6ms3k3ba6mc71.apps.googleusercontent.com';
}

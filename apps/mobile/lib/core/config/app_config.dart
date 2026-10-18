import 'package:flutter/foundation.dart';

/// Cấu hình tập trung cho toàn bộ ứng dụng AutoBank Mobile
class AppConfig {
  /// Địa chỉ IP máy tính Backend trong mạng LAN (IP Wi-Fi hiện tại)
  static const String serverHost = '192.168.1.217';
  static const int apiPort = 3000;
  static const int webPort = 5173;

  /// Tên miền chính thức của hệ thống AutoBank Production
  static const String productionApiBaseUrl = 'https://api.docthongbaobank.com';
  static const String productionWebBaseUrl = 'https://docthongbaobank.com';

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
      return 'http://localhost:$apiPort';
    }
    if (_dynamicApiBaseUrl != null && _dynamicApiBaseUrl!.isNotEmpty) {
      return _dynamicApiBaseUrl!;
    }
    // Mặc định kết nối thẳng tới VPS production chính thức
    return productionApiBaseUrl;
  }

  /// Web URL để tạo link chia sẻ đơn hàng / live sync
  static String get webBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$webPort';
    }
    if (_dynamicWebBaseUrl != null && _dynamicWebBaseUrl!.isNotEmpty) {
      return _dynamicWebBaseUrl!;
    }
    return productionWebBaseUrl;
  }

  /// Google Web Client ID (dùng để yêu cầu idToken từ Google Sign-In SDK)
  static const String googleWebClientId =
      '326124862102-oddd2tnbc6he6fk820bc15n3kpte3uo6.apps.googleusercontent.com';

  /// Google Android Client ID (dành riêng cho ứng dụng Android)
  static const String googleAndroidClientId =
      '326124862102-nmmicgns6ioajr2f07hjsb79fqc8slm7.apps.googleusercontent.com';
}

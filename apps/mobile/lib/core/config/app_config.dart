/// Cấu hình tập trung cho toàn bộ ứng dụng AutoBank Mobile
class AppConfig {
  /// Tên miền máy chủ Backend Cloud
  static const String serverHost = 'api.docthongbaobank.com';
  static const int apiPort = 3000;
  static const int webPort = 5173;

  /// Tên miền chính thức của hệ thống AutoBank Production Web
  static const String productionApiBaseUrl = 'https://api.docthongbaobank.com';
  static const String productionWebBaseUrl = 'https://docthongbaobank.com';

  /// Cho phép cập nhật động từ Cấu hình Tên Miền trên Web Admin
  static String? _dynamicApiBaseUrl;
  static String? _dynamicWebBaseUrl;

  static bool _isLocalDomain(String? domain) {
    if (domain == null) return true;
    final d = domain.toLowerCase().trim();
    return d.contains('localhost') ||
        d.contains('127.0.0.1') ||
        d.contains('192.168.') ||
        d.contains('10.0.2.2') ||
        d.contains(':3000') ||
        d.contains(':5173');
  }

  static void updateDomains({String? apiDomain, String? webDomain}) {
    // Tuyệt đối không bao giờ cho phép đè IP local/mạng LAN vào ứng dụng APK
    if (apiDomain != null && apiDomain.trim().isNotEmpty && !_isLocalDomain(apiDomain)) {
      _dynamicApiBaseUrl = apiDomain.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (webDomain != null && webDomain.trim().isNotEmpty && !_isLocalDomain(webDomain)) {
      _dynamicWebBaseUrl = webDomain.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }

  /// Lấy Base URL của NestJS API: 100% kết nối với Web Production (https://api.docthongbaobank.com)
  static String get apiBaseUrl {
    if (_dynamicApiBaseUrl != null &&
        _dynamicApiBaseUrl!.isNotEmpty &&
        !_isLocalDomain(_dynamicApiBaseUrl)) {
      return _dynamicApiBaseUrl!;
    }
    return productionApiBaseUrl;
  }

  /// Web URL: 100% kết nối với Web Production (https://docthongbaobank.com)
  static String get webBaseUrl {
    if (_dynamicWebBaseUrl != null &&
        _dynamicWebBaseUrl!.isNotEmpty &&
        !_isLocalDomain(_dynamicWebBaseUrl)) {
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

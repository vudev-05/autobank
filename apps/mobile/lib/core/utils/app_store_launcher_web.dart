import 'dart:html' as html;

class AppStoreLauncher {
  static Future<void> openPlayStore({String appId = 'com.docthongbaobank.app'}) async {
    final url = 'https://play.google.com/store/apps/details?id=$appId';
    html.window.open(url, '_blank');
  }
}

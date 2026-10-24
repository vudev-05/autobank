import '../../features/notification_listener/presentation/notification_service.dart';

class AppStoreLauncher {
  static Future<void> openPlayStore({String appId = 'com.docthongbaobank.app'}) async {
    await NotificationService.openPlayStoreListing(appId: appId);
  }
}

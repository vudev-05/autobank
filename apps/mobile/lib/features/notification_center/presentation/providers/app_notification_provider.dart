import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../domain/models/app_notification_item.dart';

class AppNotificationProvider extends ChangeNotifier {
  final List<AppNotificationItem> _notifications = [];
  NotificationCategory _selectedCategory = NotificationCategory.all;
  AppNotificationItem? _latestBannerNotification;
  Timer? _bannerDismissTimer;

  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);

  NotificationCategory get selectedCategory => _selectedCategory;

  AppNotificationItem? get latestBannerNotification => _latestBannerNotification;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  int unreadCountByCategory(NotificationCategory category) {
    if (category == NotificationCategory.all) return unreadCount;
    return _notifications.where((n) => n.category == category && !n.isRead).length;
  }

  List<AppNotificationItem> get filteredNotifications {
    if (_selectedCategory == NotificationCategory.all) {
      return _notifications;
    }
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  AppNotificationProvider() {
    _initDefaultSystemNotifications();
  }

  void _initDefaultSystemNotifications() {
    final now = DateTime.now();

    final defaultItems = [
      // 1. ƯU ĐÃI HỆ THỐNG (PROMO)
      AppNotificationItem(
        id: 'promo_welcome_10',
        title: '🎁 Ưu Đãi Chào Mừng Tân Thủ: Giảm 10%',
        message: 'Áp dụng giảm ngay 10% cho toàn bộ các gói cước trong vòng 72 giờ (3 ngày) tính từ lúc tạo tài khoản. Trừ trực tiếp vào giá thanh toán!',
        timestamp: now.subtract(const Duration(minutes: 5)),
        category: NotificationCategory.promo,
        actionType: 'navigate_register',
        isRead: false,
      ),
      AppNotificationItem(
        id: 'promo_vip_lifetime',
        title: '⚡ Mở Khóa Gói VIP Vĩnh Viễn',
        message: 'Nâng cấp gói Vĩnh Viễn để đọc loa không giới hạn, kết nối chia sẻ máy tính PC/iPhone và bảo hành cập nhật trọn đời.',
        timestamp: now.subtract(const Duration(hours: 1)),
        category: NotificationCategory.promo,
        actionType: 'navigate_register',
        isRead: false,
      ),

      // 2. HOẠT ĐỘNG NỀN (BACKGROUND)
      AppNotificationItem(
        id: 'bg_service_active',
        title: '⚡ Dịch Vụ Chạy Ngầm 24/7 Đang Bật',
        message: 'Ứng dụng đang trực nền 24/7 với dịch vụ Foreground Service, sẵn sàng bắt biến động tài khoản tất cả các ngân hàng.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        category: NotificationCategory.background,
        actionType: 'view_background',
        isRead: false,
      ),
      AppNotificationItem(
        id: 'bg_stealth_mode',
        title: '🌙 Chế Độ Tàng Hình Màn Hình Tối OLED',
        message: 'Tính năng làm mờ màn hình trực quầy thu ngân giúp tiết kiệm 95% pin máy. Loa thông báo vẫn phát to 100% khi có tiền về.',
        timestamp: now.subtract(const Duration(hours: 2)),
        category: NotificationCategory.background,
        actionType: 'view_background',
        isRead: true,
      ),
      AppNotificationItem(
        id: 'bg_battery_ignore',
        title: '🔋 Tối Ưu Quản Lý Pin Hệ Thống',
        message: 'Đã thiết lập Không giới hạn pin (Ignore Battery Optimization), chống hệ điều hành tự động tắt ứng dụng khi tắt màn hình.',
        timestamp: now.subtract(const Duration(hours: 3)),
        category: NotificationCategory.background,
        actionType: 'view_battery',
        isRead: true,
      ),

      // 3. THÔNG BÁO HỆ THỐNG (SYSTEM)
      AppNotificationItem(
        id: 'sys_sql_sync',
        title: '🗄️ Đồng Bộ Cơ Sở Dữ Liệu SQL Server',
        message: 'Kết nối máy chủ cơ sở dữ liệu SQL Server thành công. Trạng thái trực tuyến 24/7, dữ liệu biến động được sao lưu liên tục.',
        timestamp: now.subtract(const Duration(minutes: 30)),
        category: NotificationCategory.system,
        actionType: 'view_system',
        isRead: false,
      ),
      AppNotificationItem(
        id: 'sys_max_volume',
        title: '🔊 Kích Hoạt Âm Lượng Loa 100%',
        message: 'Hệ thống âm lượng đa phương tiện đã được kích hoạt mức tối đa để không bao giờ bỏ sót thông báo khách chuyển khoản.',
        timestamp: now.subtract(const Duration(hours: 4)),
        category: NotificationCategory.system,
        actionType: 'view_voice',
        isRead: true,
      ),
      AppNotificationItem(
        id: 'sys_voice_config',
        title: '🎙️ Đã Lưu Cấu Hình Giọng Đọc Chuẩn',
        message: 'Đã tối ưu hóa mẫu câu đọc ngân hàng: Chuông Ting-Ting + Lời chào + Số tiền + Ngân hàng nhận + Lời cảm ơn.',
        timestamp: now.subtract(const Duration(hours: 5)),
        category: NotificationCategory.system,
        actionType: 'view_voice',
        isRead: true,
      ),
      AppNotificationItem(
        id: 'sys_health_check',
        title: '🛡️ Kiểm Tra Tình Trạng Thiết Bị Đạt Chuẩn',
        message: 'Quyền đọc thông báo, pin ngầm, mạng Internet và loa phát âm đều đạt 100% điều kiện vận hành thu ngân chuyên nghiệp.',
        timestamp: now.subtract(const Duration(hours: 6)),
        category: NotificationCategory.system,
        actionType: 'view_check',
        isRead: true,
      ),

      // 4. XÁC THỰC & BẢO MẬT (AUTH)
      AppNotificationItem(
        id: 'auth_google_login',
        title: '✅ Xác Thực Tài Khoản Google An Toàn',
        message: 'Đăng nhập thành công với tài khoản Google. Giấy phép bản quyền và lịch sử giao dịch được bảo mật tuyệt đối.',
        timestamp: now.subtract(const Duration(minutes: 45)),
        category: NotificationCategory.auth,
        actionType: 'view_auth',
        isRead: false,
      ),
      AppNotificationItem(
        id: 'auth_pin_share',
        title: '🔑 Xác Thực Mã PIN Kết Nối Đa Màn Hình',
        message: 'Mã PIN bảo mật chia sẻ trực tiếp tới máy tính thu ngân và iPhone đã được tạo và kích hoạt an toàn.',
        timestamp: now.subtract(const Duration(hours: 2)),
        category: NotificationCategory.auth,
        actionType: 'view_share',
        isRead: true,
      ),
      AppNotificationItem(
        id: 'auth_listener_perm',
        title: '🔐 Xác Thực Quyền Đọc Thông Báo Ngân Hàng',
        message: 'Dịch vụ NotificationListenerService đã được Android cấp quyền truy cập đầy đủ 65+ ngân hàng và ví điện tử.',
        timestamp: now.subtract(const Duration(hours: 7)),
        category: NotificationCategory.auth,
        actionType: 'view_permission',
        isRead: true,
      ),
    ];

    _notifications.addAll(defaultItems);
  }

  void setCategory(NotificationCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool hasChange = false;
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        hasChange = true;
      }
    }
    if (hasChange) {
      notifyListeners();
    }
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Bắn một thông báo mới vào ứng dụng + hiển thị Banner nổi + phát Android status bar notification + đọc TTS (nếu muốn)
  Future<void> postNotification({
    required String title,
    required String message,
    required NotificationCategory category,
    String? actionType,
    Map<String, dynamic>? metadata,
    bool speakTts = false,
    bool showAndroidStatusNotification = true,
  }) async {
    final newItem = AppNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      category: category,
      actionType: actionType,
      metadata: metadata,
      isRead: false,
    );

    _notifications.insert(0, newItem);

    // Kích hoạt In-App Banner nổi
    _showInAppBanner(newItem);

    // Phát Native Android Notification vào khay thông báo điện thoại
    if (showAndroidStatusNotification) {
      NotificationService.showSystemNotification(
        title: title,
        content: message,
        type: category.name,
      );
    }

    // Đọc giọng nói TTS phản hồi nếu có yêu cầu
    if (speakTts) {
      TtsService().speakTestFeedback(title);
    }

    notifyListeners();
  }

  void _showInAppBanner(AppNotificationItem item) {
    _bannerDismissTimer?.cancel();
    _latestBannerNotification = item;
    notifyListeners();

    _bannerDismissTimer = Timer(const Duration(milliseconds: 4000), () {
      _latestBannerNotification = null;
      notifyListeners();
    });
  }

  void dismissBanner() {
    _bannerDismissTimer?.cancel();
    _latestBannerNotification = null;
    notifyListeners();
  }
}

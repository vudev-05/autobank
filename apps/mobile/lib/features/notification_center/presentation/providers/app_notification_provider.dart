import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../domain/models/app_notification_item.dart';

class AppNotificationProvider extends ChangeNotifier {
  final List<AppNotificationItem> _notifications = [];
  final Set<String> _sentNotificationKeys = {};
  NotificationCategory _selectedCategory = NotificationCategory.all;
  AppNotificationItem? _latestBannerNotification;
  Timer? _bannerDismissTimer;

  static const String _prefKeyNotifs = 'autobank_notification_history_v2';
  static const String _prefKeySentKeys = 'autobank_sent_notification_keys';

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
    _loadNotificationHistory();
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sentList = prefs.getStringList(_prefKeySentKeys) ?? [];
      _sentNotificationKeys.addAll(sentList);

      final rawData = prefs.getString(_prefKeyNotifs);
      if (rawData != null && rawData.isNotEmpty) {
        final List<dynamic> list = jsonDecode(rawData);
        _notifications.clear();
        for (var item in list) {
          try {
            _notifications.add(AppNotificationItem(
              id: item['id'] ?? '',
              title: item['title'] ?? '',
              message: item['message'] ?? '',
              timestamp: DateTime.fromMillisecondsSinceEpoch(item['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
              category: NotificationCategory.values.firstWhere(
                (c) => c.name == item['category'],
                orElse: () => NotificationCategory.system,
              ),
              actionType: item['actionType'],
              isRead: item['isRead'] ?? false,
            ));
          } catch (_) {}
        }
      } else {
        // Lần đầu mở app: Chỉ tạo 2 thông báo ưu đãi và chạy ngầm DUY NHẤT 1 LẦN
        final now = DateTime.now();
        final initialItems = [
          AppNotificationItem(
            id: 'promo_welcome_10',
            title: '🎁 Ưu Đãi Chào Mừng Tân Thủ: Giảm 10%',
            message: 'Áp dụng giảm ngay 10% cho toàn bộ các gói cước trong vòng 72 giờ tính từ lúc tạo tài khoản.',
            timestamp: now.subtract(const Duration(minutes: 5)),
            category: NotificationCategory.promo,
            actionType: 'navigate_register',
            isRead: false,
          ),
          AppNotificationItem(
            id: 'bg_service_active',
            title: '⚡ Dịch Vụ Chạy Ngầm 24/7 Đang Bật',
            message: 'Ứng dụng trực nền 24/7, sẵn sàng bắt biến động tài khoản tất cả các ngân hàng.',
            timestamp: now.subtract(const Duration(minutes: 15)),
            category: NotificationCategory.background,
            actionType: 'view_background',
            isRead: false,
          ),
        ];

        for (var item in initialItems) {
          _sentNotificationKeys.add(item.id);
          _notifications.add(item);
        }
        _saveToStorage();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationProvider] Load error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKeySentKeys, _sentNotificationKeys.toList());

      final data = _notifications.map((n) => {
        'id': n.id,
        'title': n.title,
        'message': n.message,
        'timestamp': n.timestamp.millisecondsSinceEpoch,
        'category': n.category.name,
        'actionType': n.actionType,
        'isRead': n.isRead,
      }).toList();

      await prefs.setString(_prefKeyNotifs, jsonEncode(data));
    } catch (_) {}
  }

  void setCategory(NotificationCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _saveToStorage();
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
      _saveToStorage();
      notifyListeners();
    }
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _saveToStorage();
    notifyListeners();
  }

  /// Bắn một thông báo mới vào ứng dụng ĐÚNG 1 LẦN DUY NHẤT (tránh spam trùng lặp)
  Future<void> postNotification({
    required String title,
    required String message,
    required NotificationCategory category,
    String? uniqueKey,
    String? actionType,
    Map<String, dynamic>? metadata,
    bool speakTts = false,
    bool showAndroidStatusNotification = true,
  }) async {
    final key = uniqueKey ?? '${category.name}_$title';

    // Chỉ thông báo đúng 1 lần duy nhất cho mỗi sự kiện hệ thống
    if (category != NotificationCategory.transaction) {
      if (_sentNotificationKeys.contains(key)) {
        return; // Đã thông báo rồi, không lặp lại
      }
      _sentNotificationKeys.add(key);
    }

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
    _saveToStorage();

    // Kích hoạt In-App Banner nổi
    _showInAppBanner(newItem);

    // Khi có giao dịch nhận tiền: KHÔNG bắn thanh thông báo hệ thống (tránh trùng lặp với app ngân hàng), CHỈ đọc loa TTS và bật sáng màn hình
    if (category == NotificationCategory.transaction) {
      NotificationService.wakeUpScreen();
    } else if (showAndroidStatusNotification) {
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

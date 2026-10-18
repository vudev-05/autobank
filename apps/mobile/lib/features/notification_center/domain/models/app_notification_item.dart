import 'package:flutter/material.dart';

enum NotificationCategory {
  all,
  background,
  system,
  promo,
  auth,
  transaction,
}

extension NotificationCategoryExtension on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.all:
        return 'Tất cả';
      case NotificationCategory.background:
        return 'Hoạt động nền';
      case NotificationCategory.system:
        return 'Hệ thống';
      case NotificationCategory.promo:
        return 'Ưu đãi hệ thống';
      case NotificationCategory.auth:
        return 'Xác thực & Bảo mật';
      case NotificationCategory.transaction:
        return 'Biến động số dư';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.all:
        return Icons.notifications_active_rounded;
      case NotificationCategory.background:
        return Icons.bolt_rounded;
      case NotificationCategory.system:
        return Icons.tune_rounded;
      case NotificationCategory.promo:
        return Icons.card_giftcard_rounded;
      case NotificationCategory.auth:
        return Icons.verified_user_rounded;
      case NotificationCategory.transaction:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationCategory.all:
        return const Color(0xFF0284C7);
      case NotificationCategory.background:
        return const Color(0xFF10B981);
      case NotificationCategory.system:
        return const Color(0xFF6366F1);
      case NotificationCategory.promo:
        return const Color(0xFFF59E0B);
      case NotificationCategory.auth:
        return const Color(0xFF0D9488);
      case NotificationCategory.transaction:
        return const Color(0xFF059669);
    }
  }
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  final String? actionType;
  final Map<String, dynamic>? metadata;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.actionType,
    this.metadata,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'category': category.name,
        'actionType': actionType,
        'metadata': metadata,
        'isRead': isRead,
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => NotificationCategory.system,
      ),
      actionType: json['actionType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

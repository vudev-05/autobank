import 'package:flutter/material.dart';

class WebTheme {
  // Bảng màu chuẩn đồng bộ trang Web Đọc Thông Báo Nhận Tiền
  static const Color primary = Color(0xFF0284C7);       // Xanh nước biển (Water Blue)
  static const Color primaryDark = Color(0xFF0369A1);   // Xanh nước đậm
  static const Color primaryLight = Color(0xFFBAE6FD);  // Xanh nước nhạt
  static const Color primaryBg = Color(0xFFF0F9FF);     // Nền xanh nước nhạt

  static const Color emerald = Color(0xFF059669);       // Xanh ngọc tiền vào
  static const Color emeraldLight = Color(0xFFDCFCE7);  // Nền xanh ngọc nhạt

  static const Color slate = Color(0xFF0F172A);         // Slate 900
  static const Color slateBg = Color(0xFFF8FAFC);       // Nền web Slate 50
  static const Color scaffoldBg = Color(0xFFF8FAFC);    // Nền scaffold
  static const Color rose = Color(0xFFE11D48);          // Đỏ hồng cảnh báo/nổi bật
  static const Color cardBorder = Color(0xFFE2E8F0);    // Viền card chuẩn web
  static const Color textHeading = Color(0xFF0F172A);   // Chữ tiêu đề Slate 900
  static const Color textBody = Color(0xFF334155);      // Chữ nội dung Slate 700
  static const Color textMuted = Color(0xFF64748B);     // Chữ phụ Slate 500

  // Độ bo góc tinh tế (Subtle Radius 8-12px) đồng bộ 100% với trang web, không bo tròn quá đà
  static const double radiusSm = 8.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 12.0;
  static const double radiusCard = 14.0;

  static BoxDecoration cardDecoration({
    Color? color,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radiusCard),
      border: border ?? Border.all(color: cardBorder, width: 1),
      boxShadow: shadows ?? [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration badgeDecoration({
    required Color bgColor,
    required Color borderColor,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radiusSm),
      border: Border.all(color: borderColor, width: 1),
    );
  }
}

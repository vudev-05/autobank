import '../entities/normalized_transaction.dart';

abstract class IBankParser {
  /// Mã ngân hàng nhận diện (vd: MBBANK, VIETCOMBANK, TECHCOMBANK)
  String get bankCode;

  /// Tên hiển thị của ngân hàng
  String get displayName;

  /// Kiểm tra xem parser này có thể xử lý thông báo này không
  bool canParse(String packageName, String title, String body);

  /// Bóc tách thông báo thành NormalizedTransaction
  NormalizedTransaction? parse(
    String packageName,
    String title,
    String body, {
    DateTime? timestamp,
  });

  /// Hàm tiện ích: Trích xuất mã đơn hàng từ nội dung chuyển khoản
  /// Hỗ trợ các định dạng phổ biến: DH1058, BILL99, HD001, ORDER123, PAY456,...
  static String? extractOrderCode(String content) {
    if (content.isEmpty) return null;
    final regex = RegExp(
      r'\b(DH|BILL|HD|ORDER|PAY|MDH|DON|MA)[-_]?([0-9]{2,10})\b',
      caseSensitive: false,
    );
    final match = regex.firstMatch(content);
    if (match != null) {
      final prefix = match.group(1)?.toUpperCase() ?? '';
      final number = match.group(2) ?? '';
      return '$prefix$number';
    }
    return null;
  }

  /// Chuẩn hóa số tiền dạng chuỗi (ví dụ: "100,000", "50.000", "150000") thành double
  static double parseAmount(String rawAmount) {
    // Loại bỏ dấu phân tách hàng nghìn (, hoặc .) và đơn vị tiền
    final cleaned = rawAmount
        .replaceAll(RegExp(r'[^\d]'), '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Trích xuất thời gian giao dịch thực tế được ngân hàng in trong thông báo
  /// Hỗ trợ các định dạng: dd/MM/yy HH:mm[:ss], dd/MM/yyyy HH:mm[:ss], HH:mm dd/MM/yyyy, lúc HH:mm ngày dd/MM/yyyy
  static DateTime? extractTransactionTime(String text, {DateTime? fallback}) {
    if (text.isEmpty) return fallback;

    // Pattern 1: dd/MM/yyyy HH:mm[:ss] hoặc dd/MM/yy HH:mm[:ss] (MBBank, VCB,...)
    final p1 = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\b',
    );
    final m1 = p1.firstMatch(text);
    if (m1 != null) {
      try {
        final d = int.parse(m1.group(1)!);
        final m = int.parse(m1.group(2)!);
        var y = int.parse(m1.group(3)!);
        if (y < 100) y += 2000;
        final h = int.parse(m1.group(4)!);
        final min = int.parse(m1.group(5)!);
        final s = m1.group(6) != null ? int.parse(m1.group(6)!) : 0;
        if (m >= 1 && m <= 12 && d >= 1 && d <= 31 && h >= 0 && h <= 23 && min >= 0 && min <= 59) {
          return DateTime(y, m, d, h, min, s);
        }
      } catch (_) {}
    }

    // Pattern 2: HH:mm[:ss] [ngày|ngay] dd/MM/yyyy hoặc HH:mm[:ss] dd/MM/yy
    final p2 = RegExp(
      r'\b(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(?:ngày|ngay|,)?\s*(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
      caseSensitive: false,
    );
    final m2 = p2.firstMatch(text);
    if (m2 != null) {
      try {
        final h = int.parse(m2.group(1)!);
        final min = int.parse(m2.group(2)!);
        final s = m2.group(3) != null ? int.parse(m2.group(3)!) : 0;
        final d = int.parse(m2.group(4)!);
        final m = int.parse(m2.group(5)!);
        var y = int.parse(m2.group(6)!);
        if (y < 100) y += 2000;
        if (m >= 1 && m <= 12 && d >= 1 && d <= 31 && h >= 0 && h <= 23 && min >= 0 && min <= 59) {
          return DateTime(y, m, d, h, min, s);
        }
      } catch (_) {}
    }

    return fallback;
  }
}

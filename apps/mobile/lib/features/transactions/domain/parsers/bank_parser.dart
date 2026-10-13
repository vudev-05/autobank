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
}

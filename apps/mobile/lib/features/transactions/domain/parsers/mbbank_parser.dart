import '../entities/normalized_transaction.dart';
import '../entities/transaction_type.dart';
import 'bank_parser.dart';

class MBBankParser implements IBankParser {
  @override
  String get bankCode => 'MBBANK';

  @override
  String get displayName => 'MB Bank (Quân Đội)';

  @override
  bool canParse(String packageName, String title, String body) {
    final lowerPkg = packageName.toLowerCase();
    final combined = '$title $body'.toLowerCase();

    return lowerPkg.contains('mbmobile') ||
        combined.contains('mbbank') ||
        combined.contains('mb bank') ||
        (combined.contains('biến động số dư') && combined.contains('mb'));
  }

  @override
  NormalizedTransaction? parse(
    String packageName,
    String title,
    String body, {
    DateTime? timestamp,
  }) {
    final fullText = '$title $body'.trim();
    final now = timestamp ?? DateTime.now();

    // 1. Trích xuất loại giao dịch & Số tiền
    // Format 1: GD: +100,000VND hoặc GD: -50,000VND
    // Format 2: +100,000VND hoặc +100.000 VND
    TransactionType type = TransactionType.unknown;
    double amount = 0.0;

    final amountRegex = RegExp(
      r'(?:GD:\s*)?([\+\-])\s*([0-9,.]+)\s*(?:VND|đ|d)?',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(fullText);

    if (amountMatch != null) {
      final sign = amountMatch.group(1);
      final rawAmount = amountMatch.group(2) ?? '0';

      type = (sign == '+') ? TransactionType.credit : TransactionType.debit;
      amount = IBankParser.parseAmount(rawAmount);
    } else {
      // Fallback: Tìm số tiền kèm chữ VND
      final fallbackAmountRegex = RegExp(r'([0-9,.]+)\s*(?:VND|đ|d)', caseSensitive: false);
      final fallbackMatch = fallbackAmountRegex.firstMatch(fullText);
      if (fallbackMatch != null) {
        amount = IBankParser.parseAmount(fallbackMatch.group(1) ?? '0');
        type = TransactionType.credit; // Mặc định nhận tiền nếu không thấy dấu âm
      }
    }

    if (amount <= 0) return null; // Không trích xuất được số tiền hợp lệ

    // 2. Trích xuất số tài khoản
    // Format: TK 0338889999 hoặc So TK 0338889999 hoặc TK: 0338889999
    String accountNumber = '';
    final accountRegex = RegExp(r'(?:TK|Tài khoản|Tai khoan)\s*[:]?\s*([0-9A-Za-z]+)', caseSensitive: false);
    final accountMatch = accountRegex.firstMatch(fullText);
    if (accountMatch != null) {
      accountNumber = accountMatch.group(1) ?? '';
    }

    // 3. Trích xuất nội dung (ND: ...) - dùng \bND\b để tránh nhầm chữ ND trong VND
    String content = '';
    final contentRegex = RegExp(r'(?:\bND\b|Nội dung|Noi dung)\s*[:]?\s*([^|\r\n]+)', caseSensitive: false);
    final contentMatch = contentRegex.firstMatch(fullText);
    if (contentMatch != null) {
      content = contentMatch.group(1)?.trim() ?? '';
    } else {
      content = body.trim();
    }

    // 4. Bóc tách mã đơn hàng (nếu có trong nội dung hoặc toàn bộ thông báo)
    final orderCode = IBankParser.extractOrderCode(content) ?? IBankParser.extractOrderCode(fullText);

    final id = 'MB_${now.millisecondsSinceEpoch}_${(amount).toInt()}';

    return NormalizedTransaction(
      id: id,
      bankCode: bankCode,
      accountNumber: accountNumber,
      amount: amount,
      type: type,
      content: content,
      orderCode: orderCode,
      transactionTime: now,
      rawContent: '$title\n$body',
    );
  }
}

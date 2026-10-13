import '../entities/normalized_transaction.dart';
import '../entities/transaction_type.dart';
import 'bank_parser.dart';

class VietcombankParser implements IBankParser {
  @override
  String get bankCode => 'VIETCOMBANK';

  @override
  String get displayName => 'Vietcombank (VCB Digibank)';

  @override
  bool canParse(String packageName, String title, String body) {
    final lowerPkg = packageName.toLowerCase();
    final combined = '$title $body'.toLowerCase();

    return lowerPkg.contains('vietcombank') ||
        lowerPkg.contains('vcb') ||
        combined.contains('vietcombank') ||
        combined.contains('vcb digibank') ||
        combined.contains('vcb') ||
        combined.contains('sd tk');
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

    // 1. Trích xuất Loại giao dịch & Số tiền
    // VCB: +500,000 VND hoặc -200,000VND hoặc +100.000 VND
    TransactionType type = TransactionType.unknown;
    double amount = 0.0;

    final amountRegex = RegExp(
      r'([\+\-])\s*([0-9,.]+)\s*(?:VND|đ|d)',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(fullText);

    if (amountMatch != null) {
      final sign = amountMatch.group(1);
      final rawAmount = amountMatch.group(2) ?? '0';

      type = (sign == '+') ? TransactionType.credit : TransactionType.debit;
      amount = IBankParser.parseAmount(rawAmount);
    } else {
      // Fallback tìm số tiền kèm VND
      final fallbackRegex = RegExp(r'([0-9,.]+)\s*(?:VND|đ|d)', caseSensitive: false);
      final fallbackMatch = fallbackRegex.firstMatch(fullText);
      if (fallbackMatch != null) {
        amount = IBankParser.parseAmount(fallbackMatch.group(1) ?? '0');
        type = TransactionType.credit;
      }
    }

    if (amount <= 0) return null;

    // 2. Trích xuất Số tài khoản
    // Format: TK 1012345678 hoặc SD TK 0011001234567
    String accountNumber = '';
    final accountRegex = RegExp(r'(?:TK|SD TK|Tài khoản|Tai khoan)\s*[:]?\s*([0-9A-Za-z]+)', caseSensitive: false);
    final accountMatch = accountRegex.firstMatch(fullText);
    if (accountMatch != null) {
      accountNumber = accountMatch.group(1) ?? '';
    }

    // 3. Trích xuất Nội dung
    // VCB thường có: ND: DH1058 LE THI B CHUYEN KHOAN
    String content = '';
    final contentRegex = RegExp(r'(?:\bND\b|Nội dung|Noi dung)\s*[:]?\s*([^;\r\n]+)', caseSensitive: false);
    final contentMatch = contentRegex.firstMatch(fullText);
    if (contentMatch != null) {
      content = contentMatch.group(1)?.trim() ?? '';
    } else {
      content = body.trim();
    }

    // 4. Trích xuất mã đơn hàng (từ nội dung hoặc toàn bộ thông báo)
    final orderCode = IBankParser.extractOrderCode(content) ?? IBankParser.extractOrderCode(fullText);

    final id = 'VCB_${now.millisecondsSinceEpoch}_${(amount).toInt()}';

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

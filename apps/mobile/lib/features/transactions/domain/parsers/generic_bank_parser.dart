import '../entities/normalized_transaction.dart';
import '../entities/transaction_type.dart';
import 'bank_parser.dart';

class GenericBankParser implements IBankParser {
  @override
  String get bankCode => 'OTHER_BANK';

  @override
  String get displayName => 'Ngân hàng khác';

  @override
  bool canParse(String packageName, String title, String body) {
    final combined = '$title $body'.toLowerCase();
    // Chấp nhận nếu có chữ VND hoặc đ hoặc dấu + / - kèm số tiền
    return combined.contains('vnd') ||
        combined.contains('đ') ||
        combined.contains('so du') ||
        combined.contains('số dư') ||
        combined.contains('biến động');
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

    TransactionType type = TransactionType.unknown;
    double amount = 0.0;

    final amountRegex = RegExp(
      r'([\+\-])\s*([0-9,.]+)\s*(?:VND|đ|d)?',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(fullText);

    if (amountMatch != null) {
      final sign = amountMatch.group(1);
      final rawAmount = amountMatch.group(2) ?? '0';
      type = (sign == '+') ? TransactionType.credit : TransactionType.debit;
      amount = IBankParser.parseAmount(rawAmount);
    } else {
      final fallbackRegex = RegExp(r'([0-9,.]+)\s*(?:VND|đ|d)', caseSensitive: false);
      final fallbackMatch = fallbackRegex.firstMatch(fullText);
      if (fallbackMatch != null) {
        amount = IBankParser.parseAmount(fallbackMatch.group(1) ?? '0');
        type = TransactionType.credit;
      }
    }

    if (amount <= 0) return null;

    String accountNumber = '';
    final accountRegex = RegExp(r'(?:TK|Tài khoản|Tai khoan)\s*[:]?\s*([0-9A-Za-z]+)', caseSensitive: false);
    final accountMatch = accountRegex.firstMatch(fullText);
    if (accountMatch != null) {
      accountNumber = accountMatch.group(1) ?? '';
    }

    String content = '';
    final contentRegex = RegExp(r'(?:\bND\b|Nội dung|Noi dung)\s*[:]?\s*([^|\r\n]+)', caseSensitive: false);
    final contentMatch = contentRegex.firstMatch(fullText);
    if (contentMatch != null) {
      content = contentMatch.group(1)?.trim() ?? '';
    } else {
      content = body.trim();
    }

    final orderCode = IBankParser.extractOrderCode(content) ?? IBankParser.extractOrderCode(fullText);
    final id = 'GEN_${now.millisecondsSinceEpoch}_${(amount).toInt()}';

    // Cố gắng đoán tên ngân hàng từ package hoặc title
    String detectedBank = bankCode;
    final lowerPkg = packageName.toLowerCase();
    final lowerTitle = title.toLowerCase();
    final combined = '$lowerTitle $lowerPkg';

    final bankMap = {
      'vietcombank': 'VIETCOMBANK',
      'vcb': 'VIETCOMBANK',
      'techcombank': 'TECHCOMBANK',
      'mbbank': 'MBBANK',
      'mbmobile': 'MBBANK',
      'bidv': 'BIDV',
      'vietinbank': 'VIETINBANK',
      'acb': 'ACB',
      'vpbank': 'VPBANK',
      'vpb': 'VPBANK',
      'sacombank': 'SACOMBANK',
      'hdbank': 'HDBANK',
      'agribank': 'AGRIBANK',
      'scb': 'SCB',
      'pvcombank': 'PVCOMBANK',
      'bacabank': 'BACABANK',
      'bắc á': 'BACABANK',
      'ocb': 'OCB',
      'shb': 'SHB',
      'seabank': 'SEABANK',
      'tpbank': 'TPBANK',
      'namabank': 'NAMABANK',
      'nam á': 'NAMABANK',
      'lpbank': 'LPBANK',
      'lienviet': 'LPBANK',
      'vib': 'VIB',
      'eximbank': 'EXIMBANK',
      'msb': 'MSB',
      'uob': 'UOB',
      'cimb': 'CIMB',
      'hongleong': 'HONGLEONG',
      'publicbank': 'PUBLICBANK',
      'standardchartered': 'STANDARD_CHARTERED',
      'hsbc': 'HSBC',
      'woori': 'WOORI',
      'ibk': 'IBK',
      'kasikorn': 'KASIKORNBANK',
      'kienlong': 'KIENLONGBANK',
      'saigonbank': 'SAIGONBANK',
      'vietabank': 'VIETABANK',
      'việt á': 'VIETABANK',
      'ncb': 'NCB',
      'pgbank': 'PGBANK',
      'oceanbank': 'OCEANBANK',
      'coopbank': 'COOPBANK',
      'bidc': 'BIDC',
      'baoviet': 'BAOVIETBANK',
      'abbank': 'ABBANK',
      'indovina': 'INDOVINABANK',
      'gpbank': 'GPBANK',
      'vietbank': 'VIETBANK',
      'shinhan': 'SHINHAN',
      // Neobank
      'cake': 'CAKE',
      'liobank': 'LIOBANK',
      'tnex': 'TNEX',
      'timo': 'TIMO',
      'vikki': 'VIKKI',
      'mbv': 'MBV_BANK',
      // Ví điện tử
      'momo': 'MOMO',
      'zalopay': 'ZALOPAY',
      'shopeepay': 'SHOPEEPAY',
      'airpay': 'SHOPEEPAY',
      'viettelmoney': 'VIETTEL_MONEY',
      'viettelpay': 'VIETTEL_MONEY',
      'vnptmoney': 'VNPT_MONEY',
      // Corporate
      'digibiz': 'VCB_DIGIBIZ',
      'one biz': 'ACB_ONEBIZ',
      'ditizen': 'AB_DITIZEN',
      'ibank': 'BIDV_IBANK',
    };

    for (final entry in bankMap.entries) {
      if (combined.contains(entry.key)) {
        detectedBank = entry.value;
        break;
      }
    }

    return NormalizedTransaction(
      id: id,
      bankCode: detectedBank,
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

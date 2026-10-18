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
    // Không bắt thông báo nếu phát ra từ chính app AutoBank
    if (packageName.contains('autobank')) return false;

    final combined = '$title $body'.toLowerCase();

    return combined.contains('vnd') ||
        combined.contains('đ') ||
        combined.contains('so du') ||
        combined.contains('số dư') ||
        combined.contains('biến động') ||
        combined.contains('bien dong') ||
        combined.contains('nhận tiền') ||
        combined.contains('nhan tien') ||
        combined.contains('chuyển tiền') ||
        combined.contains('chuyen tien') ||
        combined.contains('thanh toán') ||
        combined.contains('thanh toan') ||
        combined.contains('thành công') ||
        combined.contains('giao dịch') ||
        combined.contains('gd:') ||
        combined.contains('cộng') ||
        combined.contains('cong') ||
        combined.contains('nạp') ||
        combined.contains('nap') ||
        (combined.contains('+') && (combined.contains('vnd') || combined.contains('đ') || combined.contains('tk')));
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

    // Yêu cầu bắt buộc có đơn vị tiền tệ (VND, đ, d) hoặc ngữ cảnh ngân hàng rõ ràng (GD, TK, SD)
    // Triệt tiêu hoàn toàn lỗi bóc tách các con số ngẫu nhiên như +2, +1, +84 thành tiền nhận
    final creditRegex = RegExp(
      r'(?:\+|\bcộng\b|\bcong\b)\s*([0-9,.]+)\s*(?:VND|đ|d\b)',
      caseSensitive: false,
    );
    final debitRegex = RegExp(
      r'(?:\-|\btrừ\b|\btru\b)\s*([0-9,.]+)\s*(?:VND|đ|d\b)',
      caseSensitive: false,
    );

    final creditMatch = creditRegex.firstMatch(fullText);
    final debitMatch = debitRegex.firstMatch(fullText);

    if (creditMatch != null) {
      type = TransactionType.credit;
      amount = IBankParser.parseAmount(creditMatch.group(1) ?? '0');
    } else if (debitMatch != null) {
      type = TransactionType.debit;
      amount = IBankParser.parseAmount(debitMatch.group(1) ?? '0');
    } else {
      // Kiểm tra cấu trúc tiền tệ ngân hàng: GD: +50.000 hoặc SD: 100.000VND
      final bankingRegex = RegExp(
        r'(?:GD|Giao dịch|Số dư|SD)\s*[:]?\s*(?:\+)?\s*([0-9,.]+)\s*(?:VND|đ|d)?',
        caseSensitive: false,
      );
      final bankingMatch = bankingRegex.firstMatch(fullText);

      final fallbackRegex = RegExp(r'([0-9,.]+)\s*(?:VND|đ|d\b)', caseSensitive: false);
      final fallbackMatch = fallbackRegex.firstMatch(fullText);

      if (bankingMatch != null) {
        amount = IBankParser.parseAmount(bankingMatch.group(1) ?? '0');
        type = fullText.contains('-') ? TransactionType.debit : TransactionType.credit;
      } else if (fallbackMatch != null && (fullText.contains('nhận') || fullText.contains('cộng') || fullText.contains('+'))) {
        amount = IBankParser.parseAmount(fallbackMatch.group(1) ?? '0');
        type = TransactionType.credit;
      }
    }

    // Giao dịch chuyển khoản ngân hàng thực tế tại Việt Nam luôn có giá trị tối thiểu từ 1.000đ trở lên
    // Loại bỏ các trường hợp lỗi như +1, +2, số lượng thông báo...
    if (amount < 1000) return null;

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

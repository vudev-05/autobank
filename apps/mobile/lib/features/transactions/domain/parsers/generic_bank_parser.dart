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
    // 1. Tuyệt đối chặn thông báo từ chính app AutoBank
    if (packageName.contains('autobank')) return false;

    final combined = '$title $body'.toLowerCase();

    // 2. CHẶN TRIỆT ĐỂ MỌI THÔNG BÁO QUẢNG CÁO, VOUCHER, ĐẶT MÓN, KHUYẾN MÃI
    final spamKeywords = [
      'voucher', 'giảm', 'giam', 'khuyến mãi', 'khuyen mai', 'ưu đãi', 'uu dai',
      'qc', '[qc]', 'phiên live', 'phien live', 'bữa sáng', 'bua sang', 'bánh tráng',
      'đặt món', 'dat mon', 'mã giảm', 'ma giam', 'freeship', 'freeshipxtra',
      'hoàn xu', 'hoan xu', 'quà tặng', 'qua tang', 'tặng bạn', 'tang ban',
      'cơ hội nhận', 'co hoi nhan', 'nhập mã', 'nhap ma', 'livestream', 'flash sale',
      'đến từ shop', 'shopee tặng', 'tiktok shop', 'mua sắm', 'mua sam'
    ];

    for (final spam in spamKeywords) {
      if (combined.contains(spam)) return false;
    }

    // 3. CHỈ BẮT KHI CÓ DẤU HIỆU CỦA GIAO DỊCH TÀI CHÍNH / BIẾN ĐỘNG SỐ DƯ NGÂN HÀNG THẬT
    final hasBankingSignature = combined.contains('số dư') ||
        combined.contains('so du') ||
        combined.contains('biến động') ||
        combined.contains('bien dong') ||
        combined.contains('tài khoản') ||
        combined.contains('tai khoan') ||
        combined.contains('gd:') ||
        combined.contains('giao dịch') ||
        combined.contains('giao dich') ||
        combined.contains('chuyển tiền') ||
        combined.contains('chuyen tien') ||
        combined.contains('nhận tiền') ||
        combined.contains('nhan tien') ||
        combined.contains('momo') ||
        combined.contains('zalopay') ||
        combined.contains('vnpay') ||
        combined.contains('viettel') ||
        combined.contains('tk ') ||
        combined.contains('stk:');

    if (!hasBankingSignature) return false;

    return combined.contains('vnd') ||
        combined.contains('đ') ||
        combined.contains('d\b') ||
        (combined.contains('+') && combined.contains('tk')) ||
        (combined.contains('-') && combined.contains('tk'));
  }

  @override
  NormalizedTransaction? parse(
    String packageName,
    String title,
    String body, {
    DateTime? timestamp,
  }) {
    final fullText = '$title $body'.trim();
    final parsedTime = IBankParser.extractTransactionTime(fullText, fallback: timestamp ?? DateTime.now())!;

    TransactionType type = TransactionType.unknown;
    double amount = 0.0;
    final lowerText = fullText.toLowerCase();

    // 1. ƯU TIÊN TUYỆT ĐỐI: Dấu toán học (+ hoặc -) đi liền trước số tiền
    // Nếu có dấu trừ (-) trước số tiền -> 100% LÀ TRỪ TIỀN (DEBIT), KHÔNG BAO GIỜ BỊ NHẦM THÀNH CỘNG TIỀN
    final signedAmountRegex = RegExp(
      r'(?:GD|Giao dịch|Số dư|SD|Số tiền|So tien|Biến động|TK)?\s*[:]?\s*([\+\-])\s*([0-9,.]+)\s*(?:VND|đ|d\b)?',
      caseSensitive: false,
    );
    final signedMatch = signedAmountRegex.firstMatch(fullText);

    if (signedMatch != null && signedMatch.group(1) != null) {
      final sign = signedMatch.group(1);
      final rawAmount = signedMatch.group(2) ?? '0';
      amount = IBankParser.parseAmount(rawAmount);
      type = (sign == '-') ? TransactionType.debit : TransactionType.credit;
    } else {
      // 2. Phân tích hành động chi tiêu / chuyển đi (Debit)
      // Bao gồm: "chuyển thành công", "đã chuyển", "chuyển tiền", "thanh toán", "trừ tiền", "rút tiền", "thu phí"
      // LƯU Ý: "người nhận", "tài khoản nhận", "tk nhan" là người nhận của lệnh chuyển tiền đi, không phải nhận tiền về!
      final hasDebitAction = lowerText.contains('chuyển') ||
          lowerText.contains('chuyen') ||
          lowerText.contains('thanh toán') ||
          lowerText.contains('thanh toan') ||
          lowerText.contains('trừ') ||
          lowerText.contains('tru') ||
          lowerText.contains('rút') ||
          lowerText.contains('rut') ||
          lowerText.contains('thu phí') ||
          lowerText.contains('phí dịch vụ') ||
          lowerText.contains('phi sms') ||
          lowerText.contains('phi duy tri') ||
          lowerText.contains('quẹt thẻ') ||
          lowerText.contains('quet the');

      // Phân tích hành động nhận tiền thực sự (Credit)
      final hasCreditAction = lowerText.contains('đã nhận') ||
          lowerText.contains('da nhan') ||
          lowerText.contains('nhận được') ||
          lowerText.contains('nhan duoc') ||
          lowerText.contains('vừa nhận') ||
          lowerText.contains('vua nhan') ||
          lowerText.contains('tiền vào') ||
          lowerText.contains('tien vao') ||
          lowerText.contains('cộng tiền') ||
          lowerText.contains('cong tien') ||
          lowerText.contains('được cộng');

      // 1. Nhận diện số tiền nhận (Credit):
      final creditRegex = RegExp(
        r'(?:\+|\bcộng\b|\bcong\b|\bvừa nhận\b|\bvua nhan\b|\bnhận được\b|\bnhan duoc\b|\bđã nhận\b|\bda nhan\b|\bnạp tiền\b|\bnap tien\b|\bnạp ví\b|\bnap vi\b|\btiền vào\b|\btien vao\b)\s*(?:thành công\s*)?[:]?\s*(?:\+)?\s*([0-9,.]+)\s*(?:VND|đ|d\b)?',
        caseSensitive: false,
      );

      // 2. Nhận diện số tiền chuyển đi / thanh toán (Debit):
      final debitRegex = RegExp(
        r'(?:\-|\btrừ\b|\btru\b|\bđã chuyển\b|\bda chuyen\b|\bchuyển thành công\b|\bchuyen thanh cong\b|\bchuyển\b|\bchuyen\b|\bthanh toán\b|\bthanh toan\b|\brút tiền\b|\brut tien\b|\brút\b|\brut\b)\s*(?:thành công\s*)?[:]?\s*(?:\-)?\s*([0-9,.]+)\s*(?:VND|đ|d\b)?',
        caseSensitive: false,
      );

      final debitMatch = debitRegex.firstMatch(fullText);
      final creditMatch = creditRegex.firstMatch(fullText);

      if (debitMatch != null && hasDebitAction) {
        type = TransactionType.debit;
        amount = IBankParser.parseAmount(debitMatch.group(1) ?? '0');
      } else if (creditMatch != null && hasCreditAction && !hasDebitAction) {
        type = TransactionType.credit;
        amount = IBankParser.parseAmount(creditMatch.group(1) ?? '0');
      } else if (debitMatch != null) {
        type = TransactionType.debit;
        amount = IBankParser.parseAmount(debitMatch.group(1) ?? '0');
      } else if (creditMatch != null) {
        type = TransactionType.credit;
        amount = IBankParser.parseAmount(creditMatch.group(1) ?? '0');
      } else {
        // Fallback: Tìm số tiền kèm VND / đ
        final fallbackRegex = RegExp(r'([0-9,.]+)\s*(?:VND|đ|d\b)', caseSensitive: false);
        final fallbackMatch = fallbackRegex.firstMatch(fullText);
        if (fallbackMatch != null) {
          amount = IBankParser.parseAmount(fallbackMatch.group(1) ?? '0');
          type = hasDebitAction ? TransactionType.debit : TransactionType.credit;
        }
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
    final contentRegex = RegExp(r'(?:\bND\b|Nội dung|Noi dung|Lời nhắn|Loi nhan)\s*[:]?\s*([^|\r\n]+)', caseSensitive: false);
    final contentMatch = contentRegex.firstMatch(fullText);
    if (contentMatch != null) {
      content = contentMatch.group(1)?.trim() ?? '';
    } else {
      content = body.trim();
    }

    final orderCode = IBankParser.extractOrderCode(content) ?? IBankParser.extractOrderCode(fullText);
    final id = 'GEN_${parsedTime.millisecondsSinceEpoch}_${(amount).toInt()}';

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
      'abb': 'ABBANK',
      'an binh': 'ABBANK',
      'an bình': 'ABBANK',
      'abditizen': 'ABBANK',
      'ditizen': 'ABBANK',
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
      'mservice': 'MOMO',
      'zalopay': 'ZALOPAY',
      'zalo': 'ZALOPAY',
      'shopeepay': 'SHOPEEPAY',
      'airpay': 'SHOPEEPAY',
      'viettelmoney': 'VIETTEL_MONEY',
      'viettelpay': 'VIETTEL_MONEY',
      'vnptmoney': 'VNPT_MONEY',
      'vnpay': 'VNPAY',
      // Corporate
      'digibiz': 'VCB_DIGIBIZ',
      'one biz': 'ACB_ONEBIZ',
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
      transactionTime: parsedTime,
      rawContent: '$title\n$body',
    );
  }
}

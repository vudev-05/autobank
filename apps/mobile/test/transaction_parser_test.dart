import 'package:flutter_test/flutter_test.dart';
import 'package:autobank_mobile/features/transactions/domain/entities/normalized_transaction.dart';
import 'package:autobank_mobile/features/transactions/domain/entities/transaction_type.dart';
import 'package:autobank_mobile/features/transactions/domain/parsers/bank_parser.dart';
import 'package:autobank_mobile/features/transactions/domain/parsers/mbbank_parser.dart';
import 'package:autobank_mobile/features/transactions/domain/parsers/vietcombank_parser.dart';
import 'package:autobank_mobile/features/transactions/domain/parsers/transaction_parser_factory.dart';

void main() {
  group('MBBankParser Tests', () {
    final parser = MBBankParser();

    test('Parse MBBank format chuẩn có dấu gạch đứng |', () {
      const pkg = 'com.mbmobile';
      const title = 'Biến động số dư';
      const body = 'TK 0338889999|GD: +150,000VND 11/10/26 10:15|SD: 5,420,000VND|ND: DH1058 NGUYEN VAN A chuyen tien';

      expect(parser.canParse(pkg, title, body), isTrue);
      final tx = parser.parse(pkg, title, body);

      expect(tx, isNotNull);
      expect(tx!.bankCode, equals('MBBANK'));
      expect(tx.accountNumber, equals('0338889999'));
      expect(tx.amount, equals(150000.0));
      expect(tx.type, equals(TransactionType.credit));
      expect(tx.orderCode, equals('DH1058'));
      expect(tx.content, contains('DH1058 NGUYEN VAN A chuyen tien'));
    });

    test('Parse MBBank dạng SMS / thông báo chuyển tiền đi (Debit -)', () {
      const pkg = 'com.mbmobile';
      const title = 'MBBank';
      const body = 'TK 0987654321 -50,000VND vao 11/10/26 09:30. SD: 1,200,000VND. ND: Thanh toan tien an';

      final tx = parser.parse(pkg, title, body);

      expect(tx, isNotNull);
      expect(tx!.amount, equals(50000.0));
      expect(tx.type, equals(TransactionType.debit));
      expect(tx.accountNumber, equals('0987654321'));
    });
  });

  group('VietcombankParser Tests', () {
    final parser = VietcombankParser();

    test('Parse VCB Digibank format chuẩn', () {
      const pkg = 'com.VCB';
      const title = 'VCB Digibank';
      const body = '11/10/26 10:30; TK 1012345678; +500,000 VND; So du: 10,500,000 VND; Ref: MBVCB.123456. ND: DH2048 LE THI B CHUYEN KHOAN';

      expect(parser.canParse(pkg, title, body), isTrue);
      final tx = parser.parse(pkg, title, body);

      expect(tx, isNotNull);
      expect(tx!.bankCode, equals('VIETCOMBANK'));
      expect(tx.accountNumber, equals('1012345678'));
      expect(tx.amount, equals(500000.0));
      expect(tx.type, equals(TransactionType.credit));
      expect(tx.orderCode, equals('DH2048'));
      expect(tx.content, contains('DH2048 LE THI B CHUYEN KHOAN'));
    });

    test('Parse VCB SMS format', () {
      const pkg = 'com.google.android.apps.messaging';
      const title = 'Vietcombank';
      const body = 'SD TK 0011001234567 +2,000,000VND vao 11/10/26 08:15. So du 25,500,000VND. Ref MBVCB.123456. ND: BILL99 ung ho shop';

      expect(parser.canParse(pkg, title, body), isTrue);
      final tx = parser.parse(pkg, title, body);

      expect(tx, isNotNull);
      expect(tx!.amount, equals(2000000.0));
      expect(tx.type, equals(TransactionType.credit));
      expect(tx.orderCode, equals('BILL99'));
    });
  });

  group('Helper & Fingerprint Tests', () {
    test('Trích xuất đa dạng mã đơn hàng: DH, BILL, HD, ORDER', () {
      expect(IBankParser.extractOrderCode('Chuyen tien DH1058 nhe'), equals('DH1058'));
      expect(IBankParser.extractOrderCode('Thanh toan BILL-999'), equals('BILL999'));
      expect(IBankParser.extractOrderCode('HD_8888 mua giay'), equals('HD8888'));
      expect(IBankParser.extractOrderCode('ORDER1234 khach quen'), equals('ORDER1234'));
      expect(IBankParser.extractOrderCode('Chuyen tien binh thuong khong ma'), isNull);
    });

    test('Hai thông báo trùng nhau trong cùng khung 3 phút phải có cùng Fingerprint', () {
      final now = DateTime(2026, 10, 11, 10, 0, 0);
      final twoMinutesLater = DateTime(2026, 10, 11, 10, 1, 30);

      final fp1 = NormalizedTransaction.generateFingerprint(
        bankCode: 'MBBANK',
        accountNumber: '0338889999',
        amount: 100000,
        type: TransactionType.credit,
        content: 'DH1058 Nguyen Van A',
        time: now,
      );

      final fp2 = NormalizedTransaction.generateFingerprint(
        bankCode: 'MBBANK',
        accountNumber: '0338889999',
        amount: 100000,
        type: TransactionType.credit,
        content: 'dh1058  nguyen van a',
        time: twoMinutesLater,
      );

      expect(fp1, equals(fp2), reason: 'Fingerprint phải triệt tiêu chữ hoa/thường, khoảng trắng và trùng time window');
    });

    test('TransactionParserFactory tự động nhận diện và parse đúng ngân hàng', () {
      final factory = TransactionParserFactory();

      // MBBank
      final txMb = factory.parse(
        packageName: 'com.mbmobile',
        title: 'Biến động số dư',
        body: 'TK 0338889999|GD: +350,000VND|ND: DH99',
      );
      expect(txMb?.bankCode, equals('MBBANK'));
      expect(txMb?.amount, equals(350000.0));

      // Vietcombank
      final txVcb = factory.parse(
        packageName: 'com.VCB',
        title: 'VCB Digibank',
        body: 'TK 1012345678; +80,000 VND; ND: DH100',
      );
      expect(txVcb?.bankCode, equals('VIETCOMBANK'));
      expect(txVcb?.amount, equals(80000.0));
    });
  });
}

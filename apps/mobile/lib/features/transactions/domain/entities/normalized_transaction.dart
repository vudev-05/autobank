import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'transaction_type.dart';

class NormalizedTransaction {
  final String id;
  final String bankCode;
  final String accountNumber;
  final double amount;
  final TransactionType type;
  final String content;
  final String? orderCode;
  final DateTime transactionTime;
  final String rawContent;
  final String fingerprint;
  final bool isSynced;
  final String? category;
  final String? note;

  NormalizedTransaction({
    required this.id,
    required this.bankCode,
    required this.accountNumber,
    required this.amount,
    required this.type,
    required this.content,
    this.orderCode,
    required this.transactionTime,
    required this.rawContent,
    String? fingerprint,
    this.isSynced = false,
    this.category,
    this.note,
  }) : fingerprint = fingerprint ?? generateFingerprint(
          bankCode: bankCode,
          accountNumber: accountNumber,
          amount: amount,
          type: type,
          content: content,
          time: transactionTime,
        );

  /// Tạo mã băm duy nhất (Fingerprint) dựa trên ngân hàng, số tài khoản, số tiền,
  /// nội dung và khung thời gian giao dịch để triệt tiêu việc nhận trùng lặp.
  static String generateFingerprint({
    required String bankCode,
    required String accountNumber,
    required double amount,
    required TransactionType type,
    required String content,
    required DateTime time,
  }) {
    // Làm tròn thời gian về khung 3 phút (time window)
    final epochMinutes = time.millisecondsSinceEpoch ~/ (1000 * 60 * 3);
    final normalizedContent = content.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final rawKey = '$bankCode|$accountNumber|${amount.toInt()}|${type.name}|$normalizedContent|$epochMinutes';
    return sha256.convert(utf8.encode(rawKey)).toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank_code': bankCode,
      'account_number': accountNumber,
      'amount': amount,
      'type': type.name,
      'content': content,
      'order_code': orderCode,
      'transaction_time': transactionTime.toIso8601String(),
      'raw_content': rawContent,
      'fingerprint': fingerprint,
      'is_synced': isSynced ? 1 : 0,
      'category': category,
      'note': note,
    };
  }

  factory NormalizedTransaction.fromMap(Map<String, dynamic> map) {
    return NormalizedTransaction(
      id: map['id'] as String,
      bankCode: map['bank_code'] as String,
      accountNumber: map['account_number'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.unknown,
      ),
      content: map['content'] as String? ?? '',
      orderCode: map['order_code'] as String?,
      transactionTime: DateTime.parse(map['transaction_time'] as String),
      rawContent: map['raw_content'] as String? ?? '',
      fingerprint: map['fingerprint'] as String,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      category: map['category'] as String?,
      note: map['note'] as String?,
    );
  }

  factory NormalizedTransaction.fromJson(Map<String, dynamic> json) {
    return NormalizedTransaction(
      id: (json['id'] ?? '').toString(),
      bankCode: (json['bankCode'] ?? json['bank_code'] ?? 'OTHER_BANK').toString(),
      accountNumber: (json['accountNumber'] ?? json['account_number'] ?? '').toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (double.tryParse((json['amount'] ?? '0').toString()) ?? 0.0),
      type: TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['type'] ?? 'credit').toString().toLowerCase(),
        orElse: () => TransactionType.unknown,
      ),
      content: (json['content'] ?? '').toString(),
      orderCode: json['orderCode'] as String? ?? json['order_code'] as String?,
      transactionTime: json['transactionTime'] != null
          ? (DateTime.tryParse(json['transactionTime'].toString()) ?? DateTime.now())
          : (json['transaction_time'] != null
              ? (DateTime.tryParse(json['transaction_time'].toString()) ?? DateTime.now())
              : DateTime.now()),
      rawContent: (json['rawContent'] ?? json['raw_content'] ?? '').toString(),
      fingerprint: (json['fingerprint'] ?? '').toString(),
      isSynced: true,
      category: json['category'] as String?,
      note: json['note'] as String?,
    );
  }

  NormalizedTransaction copyWith({
    String? id,
    String? bankCode,
    String? accountNumber,
    double? amount,
    TransactionType? type,
    String? content,
    String? orderCode,
    DateTime? transactionTime,
    String? rawContent,
    String? fingerprint,
    bool? isSynced,
    String? category,
    String? note,
  }) {
    return NormalizedTransaction(
      id: id ?? this.id,
      bankCode: bankCode ?? this.bankCode,
      accountNumber: accountNumber ?? this.accountNumber,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      content: content ?? this.content,
      orderCode: orderCode ?? this.orderCode,
      transactionTime: transactionTime ?? this.transactionTime,
      rawContent: rawContent ?? this.rawContent,
      fingerprint: fingerprint ?? this.fingerprint,
      isSynced: isSynced ?? this.isSynced,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }
}

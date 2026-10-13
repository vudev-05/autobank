enum TransactionType {
  credit, // Nhận tiền (+)
  debit,  // Chuyển tiền (-)
  unknown;

  String get displayName {
    switch (this) {
      case TransactionType.credit:
        return 'Nhận tiền';
      case TransactionType.debit:
        return 'Chuyển tiền';
      case TransactionType.unknown:
        return 'Không xác định';
    }
  }

  bool get isCredit => this == TransactionType.credit;
}

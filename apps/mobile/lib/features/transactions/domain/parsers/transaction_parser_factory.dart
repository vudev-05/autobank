import '../entities/normalized_transaction.dart';
import 'bank_parser.dart';
import 'generic_bank_parser.dart';
import 'mbbank_parser.dart';
import 'vietcombank_parser.dart';

class TransactionParserFactory {
  final List<IBankParser> _parsers;

  TransactionParserFactory({List<IBankParser>? customParsers})
      : _parsers = customParsers ?? [
          MBBankParser(),
          VietcombankParser(),
          GenericBankParser(),
        ];

  /// Tự động tìm parser phù hợp và bóc tách thông báo
  NormalizedTransaction? parse({
    required String packageName,
    required String title,
    required String body,
    DateTime? timestamp,
  }) {
    for (final parser in _parsers) {
      if (parser.canParse(packageName, title, body)) {
        final transaction = parser.parse(
          packageName,
          title,
          body,
          timestamp: timestamp,
        );
        if (transaction != null) {
          return transaction;
        }
      }
    }
    return null;
  }
}

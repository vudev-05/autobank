import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/normalized_transaction.dart';

class TransactionCard extends StatelessWidget {
  final NormalizedTransaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  Color _getBankColor(String bankCode) {
    switch (bankCode.toUpperCase()) {
      case 'MBBANK':
        return const Color(0xFF003882); // Xanh dương MB
      case 'VIETCOMBANK':
        return const Color(0xFF006B3F); // Xanh lá VCB
      case 'TECHCOMBANK':
        return const Color(0xFFE31B23); // Đỏ Techcombank
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankColor = _getBankColor(transaction.bankCode);
    final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(transaction.transactionTime);
    final isCredit = transaction.type.isCredit;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bankColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.bankCode,
                      style: TextStyle(
                        color: bankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (transaction.orderCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Đơn: ${transaction.orderCode}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${isCredit ? "+" : "-"}${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                transaction.content.isNotEmpty ? transaction.content : 'Không có nội dung',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (transaction.accountNumber.isNotEmpty) ...[
                    Icon(Icons.credit_card, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'TK: ${transaction.accountNumber}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${transaction.bankCode} Chi tiết giao dịch'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Số tiền', CurrencyFormatter.format(transaction.amount)),
              _detailRow('Loại GD', transaction.type.displayName),
              _detailRow('Số tài khoản', transaction.accountNumber),
              _detailRow('Mã đơn hàng', transaction.orderCode ?? 'Không có'),
              _detailRow('Nội dung', transaction.content),
              const Divider(height: 24),
              const Text('Mã chống trùng (Fingerprint):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SelectableText(
                transaction.fingerprint,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text('Nội dung thông báo gốc (Raw):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SelectableText(
                transaction.rawContent,
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

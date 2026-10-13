import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class PosCheckoutPage extends StatefulWidget {
  const PosCheckoutPage({super.key});

  @override
  State<PosCheckoutPage> createState() => _PosCheckoutPageState();
}

class _PosCheckoutPageState extends State<PosCheckoutPage> {
  final TextEditingController _amountController = TextEditingController(text: '50000');
  final TextEditingController _descController = TextEditingController(text: 'DH1058');

  bool _isQrShowing = false;
  double _currentAmount = 50000;
  String _currentDesc = 'DH1058';

  final List<int> _quickAmounts = [10000, 20000, 30000, 50000, 100000, 200000, 500000];

  void _generateQr() {
    final amt = double.tryParse(_amountController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ (> 0đ)')),
      );
      return;
    }
    setState(() {
      _currentAmount = amt;
      _currentDesc = _descController.text.trim().isEmpty ? 'DH1058' : _descController.text.trim();
      _isQrShowing = true;
    });
  }

  void _resetCheckout() {
    setState(() {
      _isQrShowing = false;
      _amountController.text = '50000';
      _descController.text = 'DH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = context.watch<TransactionProvider>();

    // Kiểm tra xem có giao dịch vừa nhận nào khớp với số tiền đang chờ không
    final matchedTx = txProvider.transactions.isNotEmpty &&
            _isQrShowing &&
            txProvider.transactions.first.amount == _currentAmount
        ? txProvider.transactions.first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.point_of_sale_rounded, size: 24, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Chế độ quầy thu ngân', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_isQrShowing)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Đóng mã QR',
              onPressed: _resetCheckout,
            ),
        ],
      ),
      body: _isQrShowing
          ? matchedTx != null
              ? _buildSuccessView(matchedTx)
              : _buildQrDisplayView()
          : _buildAmountInputView(theme),
    );
  }

  // 1. Màn hình nhập số tiền và tạo mã QR
  Widget _buildAmountInputView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Thẻ hướng dẫn
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Row(
            children: [
              Icon(Icons.storefront_rounded, color: Color(0xFF0284C7), size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Biến điện thoại thành màn hình thanh toán tại quầy. Tự động đọc loa ngay khi khách chuyển xong!',
                  style: TextStyle(fontSize: 13, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text('Số tiền thanh toán (VNĐ)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF0284C7)),
            suffixText: 'VNĐ',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amt) {
            return ActionChip(
              label: Text(CurrencyFormatter.format(amt.toDouble())),
              onPressed: () {
                _amountController.text = amt.toString();
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        Text('Mã đơn hàng / Nội dung chuyển khoản',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        TextField(
          controller: _descController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.tag_rounded),
            hintText: 'Ví dụ: DH1058, BAN01',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _generateQr,
            icon: const Icon(Icons.qr_code_2_rounded, size: 24),
            label: const Text('Hiện mã QR cho khách quét',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // 2. Màn hình hiển thị QR toàn màn hình cho khách quét tại quầy
  Widget _buildQrDisplayView() {
    final qrUrl =
        'https://img.vietqr.io/image/techcombank-19036573889018-compact2.png?amount=${_currentAmount.toInt()}&addInfo=${Uri.encodeComponent(_currentDesc)}&accountName=HOANG%20TRONG%20VU';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber.shade800),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang chờ khách quét mã...',
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              CurrencyFormatter.format(_currentAmount),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
            ),
            const SizedBox(height: 4),
            Text(
              'Nội dung: $_currentDesc',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),

            // Thẻ chứa mã QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  qrUrl,
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 280,
                      height: 280,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF0284C7))),
                    );
                  },
                  errorBuilder: (ctx, err, stack) {
                    return Container(
                      width: 280,
                      height: 280,
                      color: Colors.grey.shade100,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 80, color: Color(0xFF0284C7)),
                          SizedBox(height: 10),
                          Text('Mã QR VietQR chuẩn', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_up, size: 18, color: Colors.green),
                SizedBox(width: 6),
                Text('Loa sẽ tự động đọc to ngay khi tiền vào',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _resetCheckout,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Hủy / Tạo đơn khác'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Màn hình thanh toán thành công
  Widget _buildSuccessView(dynamic tx) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade300, width: 3),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Đã nhận ${CurrencyFormatter.format(tx.amount)} từ ${tx.bankCode}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 220,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                onPressed: _resetCheckout,
                icon: const Icon(Icons.add),
                label: const Text('Tiếp tục đơn mới', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class SimulationSheet extends StatefulWidget {
  const SimulationSheet({super.key});

  @override
  State<SimulationSheet> createState() => _SimulationSheetState();
}

class _SimulationSheetState extends State<SimulationSheet> {
  String _selectedBank = 'MBBANK';
  final TextEditingController _amountController = TextEditingController(text: '100000');
  final TextEditingController _orderController = TextEditingController();
  final TextEditingController _accountController = TextEditingController(text: '0338889999');

  @override
  void initState() {
    super.initState();
    _generateRandomOrderCode();
  }

  void _generateRandomOrderCode() {
    final rand = Random().nextInt(9000) + 1000;
    _orderController.text = 'DH$rand';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _orderController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'Giả lập thông báo ngân hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chọn ngân hàng
          const Text('Chọn ngân hàng:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'MBBANK', label: Text('MB Bank')),
              ButtonSegment(value: 'VIETCOMBANK', label: Text('Vietcombank')),
            ],
            selected: {_selectedBank},
            onSelectionChanged: (val) {
              setState(() {
                _selectedBank = val.first;
                if (_selectedBank == 'MBBANK') {
                  _accountController.text = '0338889999';
                } else {
                  _accountController.text = '1012345678';
                }
              });
            },
          ),
          const SizedBox(height: 16),
          // Số tiền
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tiền (VNĐ)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 8),
          // Phím tắt chọn nhanh số tiền
          Wrap(
            spacing: 8,
            children: [50000, 100000, 200000, 500000].map((amt) {
              return ActionChip(
                label: Text('${amt ~/ 1000}K'),
                onPressed: () {
                  setState(() {
                    _amountController.text = amt.toString();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Mã đơn hàng
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    labelText: 'Mã đơn hàng (Order Code)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh),
                tooltip: 'Sinh mã ngẫu nhiên',
                onPressed: _generateRandomOrderCode,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Bắn thông báo thử nghiệm & Phát TTS'),
              onPressed: () async {
                final amount = double.tryParse(_amountController.text) ?? 100000;
                final order = _orderController.text.trim();
                final account = _accountController.text.trim();

                String title = 'Biến động số dư';
                String body = '';

                if (_selectedBank == 'MBBANK') {
                  title = 'MBBank';
                  body = 'TK $account|GD: +${amount.toInt()}VND|ND: $order NGUYEN VAN A thanh toan don hang|SD: 50,000,000VND';
                } else {
                  title = 'VCB Digibank';
                  body = 'TK $account; +${amount.toInt()} VND; Ref: MBVCB.8888; ND: $order TRAN THI B CHUYEN TIEN';
                }

                final provider = Provider.of<TransactionProvider>(context, listen: false);
                final success = await provider.simulateNotification(
                  bankCode: _selectedBank,
                  title: title,
                  body: body,
                  isDemo: false,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '✅ Đã nhận và bóc tách thành công: $order (+${amount.toInt()}đ)'
                            : '⚠️ Đã bỏ qua thông báo (Trùng lặp hoặc định dạng sai)',
                      ),
                      backgroundColor: success ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

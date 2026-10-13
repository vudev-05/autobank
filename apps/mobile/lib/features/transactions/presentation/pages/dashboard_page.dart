import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../providers/transaction_provider.dart';
import '../widgets/simulation_sheet.dart';
import '../widgets/transaction_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.volume_up_rounded, size: 24, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text(
              'Đọc thông báo nhận tiền',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Nút bật/tắt giọng nói TTS
          Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                  color: provider.isTtsEnabled ? Colors.green.shade700 : Colors.grey,
                ),
                tooltip: provider.isTtsEnabled ? 'Giọng nói TTS: Đang bật' : 'Giọng nói TTS: Đã tắt',
                onPressed: () {
                  provider.toggleTts(!provider.isTtsEnabled);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.isTtsEnabled ? '🔊 Đã bật đọc giọng nói TTS' : '🔇 Đã tắt đọc giọng nói TTS',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          // Menu xóa data test
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'clear') {
                _confirmClear(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa lịch sử giao dịch', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.checkPermission();
              await provider.loadLocalTransactions();
            },
            child: CustomScrollView(
              slivers: [
                // 1. Banner kiểm tra quyền
                SliverToBoxAdapter(
                  child: _buildPermissionBanner(context, provider),
                ),

                // 2. Thẻ thống kê tổng tiền trong ngày
                SliverToBoxAdapter(
                  child: _buildSummaryCard(context, provider),
                ),

                // 3. Tiêu đề danh sách
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Biến động gần đây (${provider.transactions.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.flash_on, size: 18),
                          label: const Text('Giả lập GD'),
                          onPressed: () => _openSimulation(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Danh sách giao dịch
                if (provider.transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = provider.transactions[index];
                        return TransactionCard(transaction: tx);
                      },
                      childCount: provider.transactions.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSimulation(context),
        icon: const Icon(Icons.add),
        label: const Text('Test Giao Dịch'),
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context, TransactionProvider provider) {
    if (provider.isPermissionGranted) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lắng nghe thông báo nền: Đang hoạt động',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => provider.checkPermission(),
              tooltip: 'Kiểm tra lại',
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
              const SizedBox(width: 8),
              Text(
                'Chưa cấp quyền đọc thông báo',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ứng dụng cần quyền này để tự động bắt biến động số dư từ MBBank & Vietcombank.',
            style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () async {
                await NotificationService.openSettings();
              },
              child: const Text('Cấp quyền trong Cài đặt Android'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, TransactionProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0369A1), // Deep ocean water blue
            Color(0xFF0284C7), // Bright water blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.28),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đã nhận hôm nay',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.todayCount} giao dịch',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(provider.todayTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 14, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                'Lọc trùng lặp thông báo: Bật (Fingerprint SHA256)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa có giao dịch nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Khi ngân hàng thông báo biến động số dư, giao dịch sẽ tự động hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _openSimulation(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Thử tạo giao dịch mẫu ngay'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSimulation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const SimulationSheet(),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử?'),
        content: const Text('Hành động này sẽ xóa các giao dịch đã lưu trong SQLite cục bộ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false).clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa sạch'),
          ),
        ],
      ),
    );
  }
}

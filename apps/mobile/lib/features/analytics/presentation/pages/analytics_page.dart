import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_video_guide_modal.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../../../transactions/domain/entities/normalized_transaction.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // 0: Doanh Nghiệp (Bán Hàng & Dòng Tiền), 1: Cá Nhân (Quản Lý Chi Tiêu)
  int _currentTab = 0;

  // 0: Hôm nay, 1: 7 ngày qua, 2: Tháng này, 3: Toàn bộ, 4: Tùy chọn ngày
  int _selectedPeriod = 0;
  DateTimeRange? _customDateRange;

  // Bộ lọc lịch sử trong tab Doanh Nghiệp (0: Tất cả, 1: Thu tiền, 2: Chi tiền)
  int _businessTxFilter = 0;

  // Bộ lọc lịch sử trong tab Cá Nhân (0: Tất cả, 1: Nhận tiền, 2: Trừ tiền)
  int _personalTxFilter = 0;

  // Danh mục đang lọc trong tab Cá Nhân (null = tất cả)
  String? _selectedExpenseCategory;

  // Ô tìm kiếm cho từng tab
  String _businessSearchQuery = '';
  String _personalSearchQuery = '';
  final TextEditingController _businessSearchCtrl = TextEditingController();
  final TextEditingController _personalSearchCtrl = TextEditingController();

  bool _isInitialized = false;

  void _confirmSwitchAppMode(BuildContext context, TransactionProvider txProvider, bool targetIsBusiness) {
    final currentIsBiz = _currentTab == 0;
    if (currentIsBiz == targetIsBusiness) return;

    final targetModeName = targetIsBusiness ? 'Doanh Nghiệp' : 'Cá Nhân';
    final currentModeName = currentIsBiz ? 'Doanh Nghiệp' : 'Cá Nhân';

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: targetIsBusiness ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: targetIsBusiness ? const Color(0xFFBAE6FD) : const Color(0xFFDDD6FE),
                ),
              ),
              child: Icon(
                targetIsBusiness ? Icons.domain_rounded : Icons.person_rounded,
                color: targetIsBusiness ? const Color(0xFF2563EB) : const Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chuyển sang $targetModeName?',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Khi chuyển sang chế độ $targetModeName:\n\n'
          '• Các thông báo nhận/trừ tiền tiếp theo sẽ được tự động ghi nhận vào sổ thu chi của $targetModeName.\n'
          '• Hệ thống vẫn lưu trữ 100% dữ liệu lịch sử cũ của $currentModeName, khi chuyển lại vẫn hiển thị đầy đủ như cũ.\n\n'
          'Bạn có chắc chắn muốn chuyển không?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetIsBusiness ? const Color(0xFF2563EB) : const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dCtx);
              setState(() {
                _currentTab = targetIsBusiness ? 0 : 1;
              });
              txProvider.setBusinessMode(targetIsBusiness);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã kích hoạt chế độ hoạt động $targetModeName!'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Xác nhận chuyển'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final txProvider = context.read<TransactionProvider>();
      _currentTab = txProvider.isBusinessMode ? 0 : 1;
    }
  }

  @override
  void dispose() {
    _businessSearchCtrl.dispose();
    _personalSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final txList = txProvider.transactions;

    // 1. TÍNH TOÁN KHOẢNG THỜI GIAN LỌC THỰC TẾ
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedPeriod == 0) {
      // Hôm nay
      startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    } else if (_selectedPeriod == 1) {
      // 7 ngày qua
      startDate = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
    } else if (_selectedPeriod == 2) {
      // Tháng này
      startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    } else if (_selectedPeriod == 3) {
      // Toàn bộ
      startDate = DateTime(2020, 1, 1);
    } else {
      // Tùy chọn ngày
      startDate = _customDateRange?.start ?? DateTime(now.year, now.month, now.day - 7, 0, 0, 0);
      endDate = _customDateRange != null
          ? DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59)
          : DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    // 2. LỌC DANH SÁCH GIAO DỊCH THẬT THEO NGÀY
    final filteredTx = txList.where((tx) {
      return tx.transactionTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          tx.transactionTime.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    // 3. TÍNH CÁC CHỈ SỐ DOANH NGHIỆP & CÁ NHÂN TỪ DỮ LIỆU THẬT
    final businessTx = filteredTx.where((t) {
      final cat = t.category ?? '';
      // Ưu tiên 1: Nhãn danh mục cụ thể
      if (cat.startsWith('[Cá Nhân]')) return false;
      if (cat.startsWith('[Doanh Nghiệp]')) return true;

      // Ưu tiên 2: Thuộc tính appMode
      if (t.appMode == 'personal') return false;
      if (t.appMode == 'business') return true;

      // Ưu tiên 3: Giao dịch tiền vào mặc định là kinh doanh / bán hàng
      return t.type == TransactionType.credit;
    }).toList();

    final personalTx = filteredTx.where((t) {
      final cat = t.category ?? '';
      // Ưu tiên 1: Nhãn danh mục cụ thể
      if (cat.startsWith('[Cá Nhân]')) return true;
      if (cat.startsWith('[Doanh Nghiệp]')) return false;

      // Ưu tiên 2: Thuộc tính appMode
      if (t.appMode == 'personal') return true;
      if (t.appMode == 'business') return false;

      // Ưu tiên 3: Giao dịch tiền ra (chi tiêu) không gắn nhãn [Doanh Nghiệp] mặc định thuộc chi tiêu cá nhân
      return t.type == TransactionType.debit;
    }).toList();

    final businessCreditTx = businessTx.where((t) => t.type == TransactionType.credit).toList();
    final businessDebitTx = businessTx.where((t) => t.type == TransactionType.debit).toList();

    final double totalRevenue = businessCreditTx.fold(0.0, (sum, t) => sum + t.amount);
    final double totalExpense = businessDebitTx.fold(0.0, (sum, t) => sum + t.amount);
    final double netCashFlow = totalRevenue - totalExpense;
    final int creditCount = businessCreditTx.length;
    final int debitCount = businessDebitTx.length;

    final double avgRevenue = creditCount > 0 ? totalRevenue / creditCount : 0.0;
    double maxRevenue = 0.0;
    for (final tx in businessCreditTx) {
      if (tx.amount > maxRevenue) maxRevenue = tx.amount;
    }

    // 4. PHÂN TÍCH THEO NGÂN HÀNG & CỔNG THANH TOÁN
    final Map<String, double> bankDistribution = {};
    final Map<String, int> bankCount = {};
    for (final tx in businessCreditTx) {
      bankDistribution[tx.bankCode] = (bankDistribution[tx.bankCode] ?? 0) + tx.amount;
      bankCount[tx.bankCode] = (bankCount[tx.bankCode] ?? 0) + 1;
    }

    // 5. PHÂN TÍCH KHUNG GIỜ BÁN HÀNG
    final Map<String, double> hourlySlots = {
      'Sáng\n06-11h': 0.0,
      'Trưa\n11-14h': 0.0,
      'Chiều\n14-18h': 0.0,
      'Tối\n18-22h': 0.0,
      'Đêm\n22-06h': 0.0,
    };
    for (final tx in businessCreditTx) {
      final hour = tx.transactionTime.hour;
      if (hour >= 6 && hour < 11) {
        hourlySlots['Sáng\n06-11h'] = (hourlySlots['Sáng\n06-11h'] ?? 0) + tx.amount;
      } else if (hour >= 11 && hour < 14) {
        hourlySlots['Trưa\n11-14h'] = (hourlySlots['Trưa\n11-14h'] ?? 0) + tx.amount;
      } else if (hour >= 14 && hour < 18) {
        hourlySlots['Chiều\n14-18h'] = (hourlySlots['Chiều\n14-18h'] ?? 0) + tx.amount;
      } else if (hour >= 18 && hour < 22) {
        hourlySlots['Tối\n18-22h'] = (hourlySlots['Tối\n18-22h'] ?? 0) + tx.amount;
      } else {
        hourlySlots['Đêm\n22-06h'] = (hourlySlots['Đêm\n22-06h'] ?? 0) + tx.amount;
      }
    }

    // 6. PHÂN TÍCH THU NHẬP & CHI TIÊU CÁ NHÂN
    final personalCreditTx = personalTx.where((t) => t.type == TransactionType.credit).toList();
    final personalDebitTx = personalTx.where((t) => t.type == TransactionType.debit).toList();
    final double personalTotalIncome = personalCreditTx.fold(0.0, (sum, t) => sum + t.amount);
    final double personalTotalExpense = personalDebitTx.fold(0.0, (sum, t) => sum + t.amount);
    final double personalNetFlow = personalTotalIncome - personalTotalExpense;
    final int personalCreditCount = personalCreditTx.length;
    final int personalDebitCount = personalDebitTx.length;

    final Map<String, double> categoryDistribution = {};
    final Map<String, int> categoryCount = {};
    for (final tx in personalDebitTx) {
      var cat = tx.category ?? 'Chưa phân loại';
      if (cat.startsWith('[Cá Nhân] ')) cat = cat.substring(10);
      categoryDistribution[cat] = (categoryDistribution[cat] ?? 0) + tx.amount;
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }

    double maxExpense = 0.0;
    for (final tx in personalDebitTx) {
      if (tx.amount > maxExpense) maxExpense = tx.amount;
    }

    // 7. CÁC CHỈ SỐ QUỸ CÁ NHÂN ĐƯỢC ĐỒNG BỘ 100% TỪ personalTx THEO ĐÚNG KỲ LỌC

    return Scaffold(
      backgroundColor: WebTheme.slateBg,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentTab == 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _currentTab == 0 ? Icons.analytics_rounded : Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: _currentTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _currentTab == 0 ? 'Báo Cáo Bán Hàng' : 'Quản Lý Thu Chi Cá Nhân',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: WebTheme.textHeading,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => _showAddExpenseModal(context, txProvider, initialIsBusiness: _currentTab == 0),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _currentTab == 0 ? const Color(0xFFF0F9FF) : const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: _currentTab == 0 ? const Color(0xFFBAE6FD) : const Color(0xFFA7F3D0)),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: _currentTab == 0 ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                  size: 19,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => _exportReportSummary(
                context,
                startDate: startDate,
                endDate: endDate,
                totalRevenue: totalRevenue,
                totalExpense: totalExpense,
                netCashFlow: netCashFlow,
                creditCount: creditCount,
                debitCount: debitCount,
                bankDistribution: bankDistribution,
                categoryDistribution: categoryDistribution,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Icon(Icons.ios_share_rounded, color: Color(0xFF0284C7), size: 17),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () {
                final sysConfig = context.read<SystemConfigProvider>();
                AppVideoGuideModal.showDirect(
                  context,
                  title: 'Hướng Dẫn Sử Dụng Trang Đọc Lại',
                  subtitle: 'Cách tra cứu, nghe lại thông báo nhận tiền và quản lý dòng tiền chi tiết',
                  videoUrl: sysConfig.videoGuideHistory,
                  badgeText: 'Trang Đọc Lại',
                  dismissButtonText: 'Đóng',
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFEF4444), size: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                txProvider.loadLocalTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã tính toán lại toàn bộ số liệu theo từng ngày!'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFF7C3AED), size: 18),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: WebTheme.cardBorder, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 130),
        children: [
          // 1. THANH CHỌN TAB: DOANH NGHIỆP VS CÁ NHÂN (FINTECH PILL SEGMENT)
          _buildMainTabSegment(txProvider),

          const SizedBox(height: 12),

          // 2. BỘ LỌC KỲ HẠN THỜI GIAN
          _buildPeriodSelector(),

          const SizedBox(height: 14),

          // 3. NỘI DUNG TƯƠNG ỨNG THEO TAB
          if (_currentTab == 0) ...[
            // TAB DOANH NGHIỆP: BÁO CÁO DÒNG TIỀN & BÁN HÀNG
            _buildBusinessHeroCard(totalRevenue, totalExpense, netCashFlow),
            const SizedBox(height: 12),
            _buildBusinessKpiGrid(creditCount, avgRevenue, maxRevenue),
            const SizedBox(height: 14),
            _buildBusinessFundsCard(txProvider, businessTx, totalRevenue, totalExpense),
            const SizedBox(height: 14),
            _buildBusinessTopOrders(businessCreditTx),
            const SizedBox(height: 14),
            _buildBusinessHourlyChart(hourlySlots, totalRevenue),
            const SizedBox(height: 14),
            _buildBankDistributionCard(bankDistribution, bankCount, totalRevenue),
            const SizedBox(height: 14),
            _buildBusinessTransactionHistory(businessTx, txProvider),
          ] else ...[
            // TAB CÁ NHÂN: QUẢN LÝ DÒNG TIỀN THU & CHI CÁ NHÂN
            _buildPersonalExpenseHeroCard(
              totalIncome: personalTotalIncome,
              totalExpense: personalTotalExpense,
              netFlow: personalNetFlow,
              creditCount: personalCreditCount,
              debitCount: personalDebitCount,
              maxExpense: maxExpense,
              start: startDate,
              end: endDate,
            ),
            const SizedBox(height: 12),
            _buildPersonalFundsCard(txProvider, personalTx, personalTotalIncome, personalTotalExpense),
            const SizedBox(height: 14),
            _buildPersonalCategoryDistribution(categoryDistribution, categoryCount, personalTotalExpense),
            const SizedBox(height: 14),
            _buildPersonalExpenseHistory(personalTx, txProvider),
          ],

          const SizedBox(height: 20),

          // NÚT CHUYỂN ĐỔI CHẾ ĐỘ Ở CUỐI TRANG VỚI HỘP THOẠI XÁC NHẬN
          _buildBottomModeSwitcher(context, txProvider),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBottomModeSwitcher(BuildContext context, TransactionProvider txProvider) {
    final isBiz = _currentTab == 0;
    final targetModeName = isBiz ? 'Cá Nhân' : 'Doanh Nghiệp';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBiz ? const Color(0xFFDDD6FE) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isBiz ? const Color(0xFFF5F3FF) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBiz ? Icons.person_rounded : Icons.domain_rounded,
                  size: 20,
                  color: isBiz ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn đang xem chế độ ${isBiz ? "Doanh Nghiệp" : "Cá Nhân"}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dữ liệu 2 chế độ được lưu trữ độc lập, không bị mất.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isBiz ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                isBiz ? Icons.swap_horiz_rounded : Icons.swap_horiz_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'Chuyển sang Chế độ $targetModeName',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _confirmSwitchAppMode(context, txProvider, !isBiz),
            ),
          ),
        ],
      ),
    );
  }

  // 1. THANH CHUYỂN ĐỔI TAB CHÍNH (DOANH NGHIỆP vs CÁ NHÂN) - THIẾT KẾ ĐA SẮC MÀU SỐNG ĐỘNG
  Widget _buildMainTabSegment(TransactionProvider txProvider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WebTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_currentTab != 0) {
                  _confirmSwitchAppMode(context, txProvider, true);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _currentTab == 0
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _currentTab == 0 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.domain_rounded,
                      size: 18,
                      color: _currentTab == 0 ? const Color(0xFFFDE047) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Doanh Nghiệp',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _currentTab == 0 ? Colors.white : const Color(0xFF475569),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () {
                if (_currentTab != 1) {
                  _confirmSwitchAppMode(context, txProvider, false);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _currentTab == 1
                      ? const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _currentTab == 1 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: _currentTab == 1 ? const Color(0xFFFDBA74) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Cá Nhân',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _currentTab == 1 ? Colors.white : const Color(0xFF475569),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. BỘ CHỌN KỲ HẠN THỜI GIAN
  Widget _buildPeriodSelector() {
    final periods = ['Hôm nay', '7 ngày', 'Tháng này', 'Toàn bộ'];
    final isCustom = _selectedPeriod == 4;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(WebTheme.radiusMd),
            border: Border.all(color: WebTheme.cardBorder),
          ),
          child: Row(
            children: [
              ...List.generate(periods.length, (idx) {
                final isSelected = _selectedPeriod == idx;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedPeriod = idx),
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (_currentTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF7C3AED))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        periods[idx],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : WebTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 2),
              // Nút Tùy chọn ngày
              InkWell(
                onTap: _pickCustomDateRange,
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCustom
                        ? (_currentTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF7C3AED))
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: isCustom ? Colors.white : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCustom && _customDateRange != null
                            ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                            : 'Chọn ngày',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCustom ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: now,
      initialDateRange: _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'CHỌN KHOẢNG THỜI GIAN THỐNG KÊ',
      cancelText: 'HỦY',
      confirmText: 'ÁP DỤNG',
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = 4;
        _customDateRange = picked;
      });
    }
  }

  // =========================================================================
  // PHẦN A: GIAO DIỆN TAB DOANH NGHIỆP (BÁN HÀNG & DÒNG TIỀN)
  // =========================================================================

  // HERO CARD DOANH NGHIỆP (TỔNG THU - TỔNG CHI - DÒNG TIỀN RÒNG & BIÊN LỢI NHUẬN)
  Widget _buildBusinessHeroCard(double totalRevenue, double totalExpense, double netFlow) {
    final txProvider = context.read<TransactionProvider>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WebTheme.radiusLg),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0284C7),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.query_stats_rounded, color: Color(0xFF0F172A), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'BÁO CÁO DÒNG TIỀN THỰC TẾ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF0F172A)),
                    SizedBox(width: 3),
                    Text(
                      'Sổ cái đối soát chuẩn',
                      style: TextStyle(fontSize: 9, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // DÒNG TIỀN RÒNG / LỢI NHUẬN + NÚT ĐIỀU CHỈNH DOANH THU
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                netFlow > 0 ? '+${CurrencyFormatter.formatVND(netFlow)}' : (netFlow < 0 ? '-${CurrencyFormatter.formatVND(netFlow.abs())}' : '0 ₫'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: netFlow >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  netFlow >= 0 ? '(Dương)' : '(Âm)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showAdjustRevenueModal(context, txProvider),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 12, color: Color(0xFF0F172A)),
                      SizedBox(width: 3),
                      Text(
                        '+/- Điều chỉnh',
                        style: TextStyle(fontSize: 10, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text('Dòng tiền ròng (Tổng Tiền Vào - Tổng Tiền Ra)', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),

          // TỶ SUẤT DÒNG TIỀN RÒNG
          if (totalRevenue > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    netFlow >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: const Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Biên dòng tiền ròng: ${((netFlow / totalRevenue) * 100).toStringAsFixed(1)}% doanh thu',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 2 CỘT TỔNG THU VÀ TỔNG CHI
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF0F172A)),
                          SizedBox(width: 4),
                          Text('TỔNG THU (TIỀN VÀO)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalRevenue > 0 ? '+${CurrencyFormatter.formatVND(totalRevenue)}' : '0 ₫',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF0F172A)),
                          SizedBox(width: 4),
                          Text('TỔNG CHI (TIỀN RA)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalExpense > 0 ? '-${CurrencyFormatter.formatVND(totalExpense)}' : '0 ₫',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF9F1239)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // KPI GRID DOANH NGHIỆP
  Widget _buildBusinessKpiGrid(int count, double avg, double max) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: WebTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Số đơn bán', style: TextStyle(fontSize: 10, color: WebTheme.textMuted)),
                const SizedBox(height: 2),
                Text('$count giao dịch', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: WebTheme.textHeading)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: WebTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trung bình/đơn', style: TextStyle(fontSize: 10, color: WebTheme.textMuted)),
                const SizedBox(height: 2),
                Text(CurrencyFormatter.formatVND(avg), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: WebTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đơn cao nhất', style: TextStyle(fontSize: 10, color: WebTheme.textMuted)),
                const SizedBox(height: 2),
                Text(CurrencyFormatter.formatVND(max), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // THẺ QUẢN LÝ QUỸ & PHÂN BỔ DÒNG TIỀN DOANH NGHIỆP
  // =========================================================================
  Widget _buildBusinessFundsCard(TransactionProvider txProvider, List<NormalizedTransaction> businessTx, double totalRevenue, double totalExpense) {
    final budgets = txProvider.businessBudgets;
    
    // Thống kê dòng tiền theo từng quỹ từ các giao dịch thực tế
    final Map<String, double> fundIn = {};
    final Map<String, double> fundOut = {};
    for (final tx in businessTx) {
      final rawCat = (tx.category ?? '').replaceFirst('[Doanh Nghiệp] ', '').replaceFirst('[Cá Nhân] ', '').trim();
      final cat = rawCat.isNotEmpty ? rawCat : 'Bán hàng';
      if (tx.type == TransactionType.credit) {
        fundIn[cat] = (fundIn[cat] ?? 0.0) + tx.amount;
      } else {
        fundOut[cat] = (fundOut[cat] ?? 0.0) + tx.amount;
      }
    }

    final totalInAllFunds = fundIn.values.fold(0.0, (sum, v) => sum + v);
    final totalOutAllFunds = fundOut.values.fold(0.0, (sum, v) => sum + v);
    final totalBalanceAllFunds = totalInAllFunds - totalOutAllFunds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WebTheme.radiusLg),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0284C7),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Các nút Thao tác Quỹ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showBudgetSettingsSheet(context, txProvider, isBusiness: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0F172A), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quỹ Doanh Nghiệp',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              budgets.isNotEmpty ? '${budgets.length} quỹ đang hoạt động' : 'Chưa thiết lập quỹ',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showAddCustomBudgetDialog(context, txProvider, isBusiness: true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'Thêm Quỹ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tóm tắt dòng tiền các quỹ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ĐÃ VÀO CÁC QUỸ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      const SizedBox(height: 2),
                      Text(
                        '+${CurrencyFormatter.formatVND(totalInAllFunds)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFBAE6FD)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ĐÃ CHI TỪ QUỸ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      const SizedBox(height: 2),
                      Text(
                        '-${CurrencyFormatter.formatVND(totalOutAllFunds)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFBAE6FD)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SỐ DƯ QUỸ CÒN', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatVND(totalBalanceAllFunds),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: totalBalanceAllFunds >= 0 ? const Color(0xFF0284C7) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách từng Quỹ Doanh Nghiệp
          if (budgets.isNotEmpty) ...[
            ...budgets.entries.map((entry) {
              final cat = entry.key;
              final budgetAmt = entry.value;
              final inAmt = fundIn[cat] ?? 0.0;
              final outAmt = fundOut[cat] ?? 0.0;
              final netAmt = inAmt - outAmt;
              final usedPct = budgetAmt > 0 ? (outAmt / budgetAmt) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Icon(Icons.wallet_rounded, size: 13, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: (netAmt >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Dư: ${CurrencyFormatter.formatVND(netAmt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: netAmt >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showEditBudgetDialog(context, txProvider, cat, budgetAmt, isBusiness: true),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () => _confirmDeleteBudget(context, txProvider, cat, isBusiness: true),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thu: +${CurrencyFormatter.formatVND(inAmt)}  |  Chi: -${CurrencyFormatter.formatVND(outAmt)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Text(
                          'Hạn mức: ${CurrencyFormatter.formatVND(budgetAmt)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (usedPct.clamp(0.0, 1.0)).toDouble(),
                        minHeight: 5,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          usedPct > 1.0
                              ? const Color(0xFFDC2626)
                              : (usedPct >= 0.8 ? const Color(0xFFEA580C) : const Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // Gợi ý tạo nhanh các quỹ doanh nghiệp chuẩn
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0F172A), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Gợi ý các Quỹ chuẩn cho Doanh nghiệp / Cửa hàng:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickFundChip('📦 Quỹ Nhập hàng', 20000000, txProvider),
                      _buildQuickFundChip('🏢 Quỹ Mặt bằng & Vận hành', 10000000, txProvider),
                      _buildQuickFundChip('👥 Quỹ Lương nhân viên', 15000000, txProvider),
                      _buildQuickFundChip('🛡️ Quỹ Dự phòng & Thuế', 5000000, txProvider),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFundChip(String name, double defaultAmt, TransactionProvider txProvider, {bool isBusiness = true}) {
    final primaryColor = isBusiness ? const Color(0xFF0F172A) : const Color(0xFF7C3AED);
    return ActionChip(
      avatar: Icon(Icons.add_rounded, size: 14, color: primaryColor),
      label: Text('$name (${CurrencyFormatter.formatVND(defaultAmt)})'),
      backgroundColor: isBusiness ? const Color(0xFFF1F5F9) : const Color(0xFFF5F3FF),
      side: BorderSide(color: isBusiness ? const Color(0xFFCBD5E1) : const Color(0xFFDDD6FE)),
      labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
      onPressed: () {
        if (isBusiness) {
          txProvider.setBusinessBudget(name, defaultAmt);
        } else {
          txProvider.setPersonalBudget(name, defaultAmt);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm $name vào danh sách Quỹ ${isBusiness ? "Doanh Nghiệp" : "Cá Nhân"}!'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  // TOP 3 ĐƠN HÀNG GIÁ TRỊ CAO NHẤT (TOP TRANSACTIONS)
  Widget _buildBusinessTopOrders(List<NormalizedTransaction> creditTx) {
    if (creditTx.isEmpty) return const SizedBox.shrink();

    final sorted = List<NormalizedTransaction>.from(creditTx)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top3 = sorted.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFF0F172A)),
                  SizedBox(width: 8),
                  Text(
                    'Đơn Hàng Giá Trị Cao Nhất (Top Giao Dịch)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Top 3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF854D0E))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...top3.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final tx = entry.value;
            final time = tx.transactionTime;
            final rankColor = rank == 1
                ? const Color(0xFFEAB308)
                : (rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFB45309));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#$rank',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: rankColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.orderCode != null && tx.orderCode!.isNotEmpty
                              ? 'Đơn #${tx.orderCode} (${tx.bankCode})'
                              : 'Nhận từ ${tx.bankCode}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} • ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${CurrencyFormatter.formatVND(tx.amount)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // BIỂU ĐỒ KHUNG GIỜ CAO ĐIỂM BÁN HÀNG THỰC TẾ
  Widget _buildBusinessHourlyChart(Map<String, double> hourlySlots, double total) {
    double maxSlotVal = 0.0;
    String peakSlot = '';
    hourlySlots.forEach((k, v) {
      if (v > maxSlotVal) {
        maxSlotVal = v;
        peakSlot = k.replaceAll('\n', ' ');
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Khung Giờ Cao Điểm Bán Hàng',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Text('Giờ thực tế', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                  ],
                ),
              ),
            ],
          ),
          if (peakSlot.isNotEmpty && maxSlotVal > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Giờ vàng đông khách nhất: $peakSlot (+${CurrencyFormatter.formatVND(maxSlotVal)})',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: hourlySlots.entries.map((entry) {
              final val = entry.value;
              final pct = maxSlotVal > 0 ? (val / maxSlotVal) : 0.0;
              final isTop = val == maxSlotVal && maxSlotVal > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(
                        CurrencyFormatter.formatVND(val).replaceAll(' đ', ''),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: isTop ? const Color(0xFF0284C7) : WebTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 70 * pct + 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isTop
                                ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                                : const [Color(0xFF93C5FD), Color(0xFFBFDBFE)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                          color: isTop ? const Color(0xFF0F172A) : WebTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // PHÂN BỔ THEO NGÂN HÀNG & CỔNG THANH TOÁN
  Widget _buildBankDistributionCard(Map<String, double> banks, Map<String, int> counts, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dòng Tiền Theo Ngân Hàng & Ví',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
              ),
              Text(
                '${banks.length} cổng thanh toán',
                style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (banks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('Chưa có giao dịch trong kỳ này', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
              ),
            )
          else
            ...banks.entries.map((entry) {
              final bankName = entry.key;
              final amount = entry.value;
              final count = counts[bankName] ?? 1;
              final pct = total > 0 ? (amount / total) : 0.0;
              final bankColor = _getBankBrandColor(bankName);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: bankColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: bankColor.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance_rounded, size: 12, color: bankColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    bankName,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: bankColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$count đơn', style: const TextStyle(fontSize: 11, color: WebTheme.textMuted)),
                          ],
                        ),
                        Text(
                          '${CurrencyFormatter.formatVND(amount)} (${(pct * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WebTheme.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.02, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: bankColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // LỊCH SỬ GIAO DỊCH DOANH NGHIỆP (KÈM TÌM KIẾM & BỘ LỌC TẤT CẢ / THU / CHI)
  Widget _buildBusinessTransactionHistory(List<NormalizedTransaction> txList, TransactionProvider txProvider) {
    List<NormalizedTransaction> displayed = txList;
    if (_businessTxFilter == 1) {
      displayed = txList.where((t) => t.type == TransactionType.credit).toList();
    } else if (_businessTxFilter == 2) {
      displayed = txList.where((t) => t.type == TransactionType.debit).toList();
    }

    if (_businessSearchQuery.isNotEmpty) {
      final q = _businessSearchQuery.toLowerCase();
      displayed = displayed.where((t) {
        return t.bankCode.toLowerCase().contains(q) ||
            t.content.toLowerCase().contains(q) ||
            (t.orderCode != null && t.orderCode!.toLowerCase().contains(q)) ||
            t.amount.toString().contains(q);
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch Sử Dòng Tiền Kỳ Này',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
              ),
              Text(
                '${displayed.length} giao dịch',
                style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Ô tìm kiếm giao dịch
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _businessSearchCtrl,
              onChanged: (val) => setState(() => _businessSearchQuery = val.trim()),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo ngân hàng, mã đơn, số tiền...',
                hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                suffixIcon: _businessSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFF64748B)),
                        onPressed: () {
                          _businessSearchCtrl.clear();
                          setState(() => _businessSearchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0284C7)),
                ),
              ),
            ),
          ),

          // Segment lọc Thu / Chi / Tất cả
          Row(
            children: [
              _buildSmallFilterChip('Tất cả', _businessTxFilter == 0, () => setState(() => _businessTxFilter = 0)),
              const SizedBox(width: 6),
              _buildSmallFilterChip('+ Tiền vào', _businessTxFilter == 1, () => setState(() => _businessTxFilter = 1)),
              const SizedBox(width: 6),
              _buildSmallFilterChip('- Tiền ra', _businessTxFilter == 2, () => setState(() => _businessTxFilter = 2)),
            ],
          ),
          const SizedBox(height: 12),

          if (displayed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Không có giao dịch nào thỏa mãn bộ lọc', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
              ),
            )
          else
            ...displayed.map((tx) {
              final isCredit = tx.type == TransactionType.credit;
              final time = tx.transactionTime;
              return InkWell(
                onTap: () => _showTransactionDetailSheet(context, tx, txProvider),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 14,
                          color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngân hàng ${tx.bankCode}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} • ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}',
                              style: const TextStyle(fontSize: 10.5, color: WebTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? '+' : '-'}${CurrencyFormatter.formatVND(tx.amount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // =========================================================================
  // PHẦN B: GIAO DIỆN TAB CÁ NHÂN (PHẦN MỀM QUẢN LÝ CHI TIÊU)
  // =========================================================================

  // HERO CARD DÒNG TIỀN THU & CHI CÁ NHÂN (THU MÀU XANH, CHI MÀU ĐỎ, DÒNG TIỀN RÒNG SỐNG ĐỘNG)
  Widget _buildPersonalExpenseHeroCard({
    required double totalIncome,
    required double totalExpense,
    required double netFlow,
    required int creditCount,
    required int debitCount,
    required double maxExpense,
    required DateTime start,
    required DateTime end,
  }) {
    final days = end.difference(start).inDays + 1;
    final effectiveDays = days > 0 ? days : 1;
    final dailyAvg = totalExpense / effectiveDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WebTheme.radiusLg),
        border: Border.all(
          color: netFlow >= 0 ? const Color(0xFFBAE6FD) : const Color(0xFFFECDD3),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0284C7),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF7C3AED), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DÒNG TIỀN CÁ NHÂN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  '${start.day}/${start.month} - ${end.day}/${end.month}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // DÒNG TIỀN RÒNG CÁ NHÂN (THU - CHI)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                netFlow > 0
                    ? '+${CurrencyFormatter.formatVND(netFlow)}'
                    : (netFlow < 0 ? '-${CurrencyFormatter.formatVND(netFlow.abs())}' : '0 ₫'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: netFlow >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  netFlow >= 0 ? 'Thặng dư' : 'Bội chi',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: netFlow >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text('Dòng tiền ròng cá nhân',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),

          const SizedBox(height: 14),

          // 2 CỘT TỔNG THU VÀ TỔNG CHI CÁ NHÂN (NHẬN XANH LÁ, CHI NỀN ĐỎ)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_downward_rounded, size: 12, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 6),
                          const Text('TỔNG TIỀN VÀO',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalIncome > 0 ? '+${CurrencyFormatter.formatVND(totalIncome)}' : '0 ₫',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDA4AF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 6),
                          const Text('TỔNG TIỀN RA',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalExpense > 0 ? '-${CurrencyFormatter.formatVND(totalExpense)}' : '0 ₫',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2 Ô THỐNG KÊ GIAO DỊCH
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.south_west_rounded, size: 13, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Khoản nhận vào',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                            Text('$creditCount giao dịch',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.north_east_rounded, size: 13, color: Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Khoản chi ra',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF9F1239))),
                            Text('$debitCount giao dịch',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFBE123C))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.speed_rounded, size: 15, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Chi tiêu TB / ngày:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.formatVND(dailyAvg),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.local_fire_department_rounded, size: 15, color: Color(0xFFEA580C)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Khoản chi lớn nhất:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.formatVND(maxExpense),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFBE123C)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // QUỸ NGÂN SÁCH CHI TIÊU HÀNG THÁNG & CÁC CẤP ĐỘ CẢNH BÁO
  // 🟢 Mức tốt (< 70%) | 🟡 Cảnh báo (70% - 90%) | 🟠 Nguy kịch (90% - 100%) | 🔴 Lố ngân sách (> 100%)
  // =========================================================================
  // =========================================================================
  // THẺ QUẢN LÝ QUỸ & PHÂN BỔ DÒNG TIỀN CÁ NHÂN
  // Đồng bộ 100% thời gian thực theo bộ lọc kỳ báo cáo & phân bổ chi tiêu
  // =========================================================================
  Widget _buildPersonalFundsCard(TransactionProvider txProvider, List<NormalizedTransaction> personalTx, double totalIncome, double totalExpense) {
    final budgets = txProvider.personalBudgets;

    // Thống kê dòng tiền theo từng quỹ cá nhân từ các giao dịch thực tế
    final Map<String, double> fundIn = {};
    final Map<String, double> fundOut = {};
    for (final tx in personalTx) {
      final rawCat = (tx.category ?? '').replaceFirst('[Cá Nhân] ', '').replaceFirst('[Doanh Nghiệp] ', '').trim();
      final cat = rawCat.isNotEmpty ? rawCat : 'Sinh hoạt';
      if (tx.type == TransactionType.credit) {
        fundIn[cat] = (fundIn[cat] ?? 0.0) + tx.amount;
      } else {
        fundOut[cat] = (fundOut[cat] ?? 0.0) + tx.amount;
      }
    }

    final totalInAllFunds = fundIn.values.fold(0.0, (sum, v) => sum + v);
    final totalOutAllFunds = fundOut.values.fold(0.0, (sum, v) => sum + v);
    final totalBalanceAllFunds = totalInAllFunds - totalOutAllFunds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WebTheme.radiusLg),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A7C3AED),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Các nút Thao tác Quỹ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showBudgetSettingsSheet(context, txProvider, isBusiness: false),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: const Icon(Icons.savings_rounded, color: Color(0xFF7C3AED), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quỹ Chi Tiêu & Tiết Kiệm Cá Nhân',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              budgets.isNotEmpty ? '${budgets.length} quỹ đang hoạt động' : 'Chưa thiết lập quỹ',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showAddCustomBudgetDialog(context, txProvider, isBusiness: false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'Thêm Quỹ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tóm tắt dòng tiền các quỹ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ĐÃ VÀO CÁC QUỸ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                      const SizedBox(height: 2),
                      Text(
                        '+${CurrencyFormatter.formatVND(totalInAllFunds)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFDDD6FE)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ĐÃ CHI TỪ QUỸ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                      const SizedBox(height: 2),
                      Text(
                        '-${CurrencyFormatter.formatVND(totalOutAllFunds)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFDDD6FE)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SỐ DƯ QUỸ CÒN', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatVND(totalBalanceAllFunds),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: totalBalanceAllFunds >= 0 ? const Color(0xFF7C3AED) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách từng Quỹ Cá Nhân
          if (budgets.isNotEmpty) ...[
            ...budgets.entries.map((entry) {
              final cat = entry.key;
              final budgetAmt = entry.value;
              final inAmt = fundIn[cat] ?? 0.0;
              final outAmt = fundOut[cat] ?? 0.0;
              final netAmt = inAmt - outAmt;
              final usedPct = budgetAmt > 0 ? (outAmt / budgetAmt) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFDDD6FE)),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, size: 13, color: Color(0xFF7C3AED)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: (netAmt >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Dư: ${CurrencyFormatter.formatVND(netAmt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: netAmt >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showEditBudgetDialog(context, txProvider, cat, budgetAmt, isBusiness: false),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () => _confirmDeleteBudget(context, txProvider, cat, isBusiness: false),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thu: +${CurrencyFormatter.formatVND(inAmt)}  |  Chi: -${CurrencyFormatter.formatVND(outAmt)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Text(
                          budgetAmt > 0
                              ? 'Hạn mức: ${CurrencyFormatter.formatVND(budgetAmt)} (${(usedPct * 100).toStringAsFixed(0)}%)'
                              : 'Chưa đặt hạn mức',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: usedPct > 1.0 ? const Color(0xFFDC2626) : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    if (budgetAmt > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (usedPct.clamp(0.0, 1.0)).toDouble(),
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usedPct > 1.0
                                ? const Color(0xFFDC2626)
                                : (usedPct >= 0.8 ? const Color(0xFFEA580C) : const Color(0xFF7C3AED)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else ...[
            // Gợi ý tạo nhanh các quỹ cá nhân chuẩn
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF7C3AED), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Gợi ý các Quỹ chuẩn cho Chi tiêu Cá nhân:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickFundChip('🍲 Ăn uống & Sinh hoạt', 5000000, txProvider, isBusiness: false),
                      _buildQuickFundChip('🏠 Tiền thuê nhà & Điện nước', 4000000, txProvider, isBusiness: false),
                      _buildQuickFundChip('🛵 Xăng xe & Đi lại', 1500000, txProvider, isBusiness: false),
                      _buildQuickFundChip('💰 Tiết kiệm & Đầu tư', 3000000, txProvider, isBusiness: false),
                      _buildQuickFundChip('🎁 Mua sắm & Giải trí', 2000000, txProvider, isBusiness: false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // CÁC HỘP THOẠI QUẢN LÝ QUỸ: THÊM, SỬA (TÊN & HẠN MỨC), XÓA, LẬP HẠN MỨC
  // Hỗ trợ tách biệt 100% giữa QUỸ DOANH NGHIỆP và QUỸ CÁ NHÂN
  // =========================================================================

  // 1. HỘP THOẠI THÊM QUỸ MỚI
  void _showAddCustomBudgetDialog(
    BuildContext context,
    TransactionProvider txProvider, {
    bool isBusiness = false,
    ValueChanged<String>? onCreated,
  }) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: isBusiness ? '5000000' : '1000000');
    final primaryColor = isBusiness ? const Color(0xFF0284C7) : const Color(0xFFE11D48);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(
                isBusiness ? Icons.account_balance_rounded : Icons.savings_rounded,
                color: primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBusiness ? 'Thêm Quỹ Doanh Nghiệp' : 'Thêm Quỹ Cá Nhân',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tên quỹ mới:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isBusiness ? 'VD: Quỹ Quảng Cáo, Quỹ CSKH...' : 'VD: Mua sắm, Du lịch, Tiền học...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Hạn mức mỗi tháng (VNĐ):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    suffixText: 'đ',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (isBusiness
                          ? [2000000, 5000000, 10000000, 20000000, 50000000]
                          : [500000, 1000000, 2000000, 3000000, 5000000])
                      .map((amt) {
                    return InkWell(
                      onTap: () => amountCtrl.text = amt.toString(),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          amt >= 1000000 ? '${(amt / 1000000).toStringAsFixed(0)}tr' : '${(amt / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final fundName = nameCtrl.text.trim();
                final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
                if (fundName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập tên quỹ!'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập hạn mức lớn hơn 0đ!'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (isBusiness) {
                  txProvider.setBusinessBudget(fundName, amt);
                } else {
                  txProvider.setPersonalBudget(fundName, amt);
                }

                if (onCreated != null) {
                  onCreated(fundName);
                }

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thêm quỹ "$fundName" (${isBusiness ? "Doanh Nghiệp" : "Cá Nhân"}): ${CurrencyFormatter.formatVND(amt)}/tháng!'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Tạo & Lưu Quỹ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 2. HỘP THOẠI CHỈNH SỬA TOÀN DIỆN (TÊN QUỸ & HẠN MỨC)
  void _showEditBudgetDialog(BuildContext context, TransactionProvider txProvider, String oldCategory, double currentBudget, {bool isBusiness = false}) {
    final nameCtrl = TextEditingController(text: oldCategory);
    final amountCtrl = TextEditingController(text: currentBudget.toInt().toString());
    final primaryColor = isBusiness ? const Color(0xFF0284C7) : const Color(0xFFE11D48);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isBusiness ? Icons.business_center_rounded : Icons.account_balance_wallet_rounded,
              color: primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sửa Quỹ: $oldCategory',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tên quỹ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WebTheme.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Hạn mức ngân sách (VNĐ/tháng):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WebTheme.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  suffixText: 'đ',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (isBusiness
                        ? [2000000, 5000000, 10000000, 20000000, 50000000]
                        : [1000000, 2000000, 3000000, 5000000, 10000000])
                    .map((amt) {
                  return InkWell(
                    onTap: () => amountCtrl.text = amt.toString(),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(amt / 1000000).toStringAsFixed(0)}tr',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF64748B)),
            label: const Text('Xóa Quỹ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _confirmDeleteBudget(context, txProvider, oldCategory, isBusiness: isBusiness);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newAmt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tên quỹ không được để trống!'), backgroundColor: Colors.red),
                );
                return;
              }
              if (newAmt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hạn mức phải lớn hơn 0đ!'), backgroundColor: Colors.red),
                );
                return;
              }

              if (newName != oldCategory) {
                if (isBusiness) {
                  txProvider.renameBusinessBudget(oldCategory, newName, newAmt);
                } else {
                  txProvider.renamePersonalBudget(oldCategory, newName, newAmt);
                }
              } else {
                if (isBusiness) {
                  txProvider.setBusinessBudget(oldCategory, newAmt);
                } else {
                  txProvider.setPersonalBudget(oldCategory, newAmt);
                }
              }

              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật quỹ "$newName": ${CurrencyFormatter.formatVND(newAmt)}/tháng!'),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Lưu Thay Đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. XÁC NHẬN XÓA QUỸ
  void _confirmDeleteBudget(BuildContext context, TransactionProvider txProvider, String category, {bool isBusiness = false}) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFF0F172A), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xóa Quỹ "$category"?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa quỹ "$category" khỏi Quỹ ${isBusiness ? "Doanh Nghiệp" : "Cá Nhân"} không?\nSau khi xóa, danh mục này sẽ không còn trong danh sách quản lý ngân sách.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(confirmCtx);
              if (isBusiness) {
                txProvider.deleteBusinessBudget(category);
              } else {
                txProvider.deletePersonalBudget(category);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa quỹ "$category" thành công!'),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Xác nhận Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4. BOTTOM SHEET THIẾT LẬP TOÀN BỘ HẠN MỨC QUỸ
  void _showBudgetSettingsSheet(BuildContext context, TransactionProvider txProvider, {bool isBusiness = false}) {
    final availableCategories = isBusiness
        ? (txProvider.businessBudgets.keys.toList())
        : txProvider.expenseCategories;
    
    if (availableCategories.isEmpty) {
      _showAddCustomBudgetDialog(context, txProvider, isBusiness: isBusiness);
      return;
    }

    String selectedCategory = availableCategories.first;
    final primaryColor = isBusiness ? const Color(0xFF0284C7) : const Color(0xFFE11D48);
    final initialBudget = isBusiness
        ? (txProvider.businessBudgets[selectedCategory] ?? 5000000.0)
        : txProvider.getCategoryBudget(selectedCategory);

    final amountCtrl = TextEditingController(text: initialBudget > 0 ? initialBudget.toInt().toString() : (isBusiness ? '5000000' : '3000000'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Icon(
                        isBusiness ? Icons.account_balance_rounded : Icons.savings_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBusiness ? 'Hạn Mức Quỹ Doanh Nghiệp' : 'Hạn Mức Quỹ Chi Tiêu Hàng Tháng',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBusiness
                        ? 'Đặt hạn mức trần hàng tháng cho từng quỹ để quản lý chi phí doanh nghiệp hiệu quả.'
                        : 'Đặt hạn mức tối đa mỗi tháng cho từng danh mục để theo dõi % chi tiêu và nhận cảnh báo.',
                    style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '1. Chọn quỹ cần chỉnh hạn mức:',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableCategories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        avatar: Icon(
                          isBusiness ? Icons.wallet_rounded : _getCategoryIconData(cat),
                          size: 14,
                          color: isSelected ? Colors.white : (isBusiness ? const Color(0xFF0284C7) : _getCategoryColor(cat)),
                        ),
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() {
                              selectedCategory = cat;
                              final existing = isBusiness
                                  ? (txProvider.businessBudgets[cat] ?? 0.0)
                                  : txProvider.getCategoryBudget(cat);
                              if (existing > 0) {
                                amountCtrl.text = existing.toInt().toString();
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '2. Hạn mức chi tiêu mỗi tháng (VNĐ):',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                    decoration: InputDecoration(
                      hintText: 'VD: 5000000',
                      suffixText: 'VNĐ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Gợi ý nhanh
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (isBusiness
                            ? [
                                {'label': '2 Tr', 'val': 2000000},
                                {'label': '5 Tr', 'val': 5000000},
                                {'label': '10 Tr', 'val': 10000000},
                                {'label': '20 Tr', 'val': 20000000},
                                {'label': '50 Tr', 'val': 50000000},
                              ]
                            : [
                                {'label': '500K', 'val': 500000},
                                {'label': '1 Triệu', 'val': 1000000},
                                {'label': '2 Triệu', 'val': 2000000},
                                {'label': '3 Triệu', 'val': 3000000},
                                {'label': '5 Triệu', 'val': 5000000},
                                {'label': '10 Triệu', 'val': 10000000},
                              ])
                        .map((item) {
                      return InkWell(
                        onTap: () {
                          setSheetState(() {
                            amountCtrl.text = (item['val'] as int).toString();
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            item['label'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
                        if (amt > 0) {
                          if (isBusiness) {
                            txProvider.setBusinessBudget(selectedCategory, amt);
                          } else {
                            txProvider.setPersonalBudget(selectedCategory, amt);
                          }
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã lưu hạn mức "$selectedCategory": ${CurrencyFormatter.formatVND(amt)}/tháng!'),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Lưu Hạn Mức Quỹ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // PHÂN BỔ CHI TIÊU THEO DANH MỤC
  Widget _buildPersonalCategoryDistribution(Map<String, double> categories, Map<String, int> counts, double totalExpense) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: Color(0xFFEA580C), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Phân Loại Danh Mục Chi Tiêu',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${categories.length} nhóm chi',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Chưa có khoản chi tiêu nào trong kỳ này', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
              ),
            )
          else
            ...categories.entries.map((entry) {
              final catName = entry.key;
              final amount = entry.value;
              final count = counts[catName] ?? 1;
              final pct = totalExpense > 0 ? (amount / totalExpense) : 0.0;
              final color = _getCategoryColor(catName);

              final isFiltered = _selectedExpenseCategory == catName;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedExpenseCategory == catName) {
                      _selectedExpenseCategory = null;
                    } else {
                      _selectedExpenseCategory = catName;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFiltered ? color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isFiltered ? Border.all(color: color, width: 1.2) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildCategoryBadge(catName, size: 14, padding: 4),
                              const SizedBox(width: 8),
                              Text(
                                catName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('$count lần', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                              ),
                            ],
                          ),
                          Text(
                            '${CurrencyFormatter.formatVND(amount)} (${(pct * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.02, 1.0),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // DANH SÁCH LỊCH SỬ GIAO DỊCH CÁ NHÂN (CHI TIÊU & THU NHẬP)
  Widget _buildPersonalExpenseHistory(List<NormalizedTransaction> personalList, TransactionProvider txProvider) {
    List<NormalizedTransaction> displayed = personalList;

    // Lọc theo loại giao dịch Thu / Chi
    if (_personalTxFilter == 1) {
      displayed = displayed.where((t) => t.type == TransactionType.credit).toList();
    } else if (_personalTxFilter == 2) {
      displayed = displayed.where((t) => t.type == TransactionType.debit).toList();
    }

    if (_selectedExpenseCategory != null) {
      displayed = displayed.where((t) {
        var cat = t.category ?? 'Chưa phân loại';
        if (cat.startsWith('[Cá Nhân] ')) cat = cat.substring(10);
        return cat == _selectedExpenseCategory;
      }).toList();
    }

    if (_personalSearchQuery.isNotEmpty) {
      final q = _personalSearchQuery.toLowerCase();
      displayed = displayed.where((t) {
        return t.content.toLowerCase().contains(q) ||
            t.bankCode.toLowerCase().contains(q) ||
            (t.category != null && t.category!.toLowerCase().contains(q)) ||
            (t.note != null && t.note!.toLowerCase().contains(q)) ||
            t.amount.toString().contains(q);
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Icon(Icons.history_rounded, color: Color(0xFF2563EB), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch Sử Giao Dịch Cá Nhân',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chạm vào giao dịch để đổi danh mục Cá Nhân / Doanh Nghiệp',
                            style: TextStyle(fontSize: 10, color: WebTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedExpenseCategory != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _selectedExpenseCategory = null),
                  child: const Text('Bỏ lọc', style: TextStyle(fontSize: 11, color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Ô tìm kiếm giao dịch
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _personalSearchCtrl,
              onChanged: (val) => setState(() => _personalSearchQuery = val.trim()),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo nội dung, danh mục, ngân hàng...',
                hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF2563EB)),
                suffixIcon: _personalSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFF64748B)),
                        onPressed: () {
                          _personalSearchCtrl.clear();
                          setState(() => _personalSearchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
            ),
          ),

          // Segment lọc Thu / Chi / Tất cả cho Cá Nhân
          Row(
            children: [
              _buildSmallFilterChip('Tất cả', _personalTxFilter == 0, () => setState(() => _personalTxFilter = 0)),
              const SizedBox(width: 6),
              _buildSmallFilterChip('+ Tiền vào', _personalTxFilter == 1, () => setState(() => _personalTxFilter = 1)),
              const SizedBox(width: 6),
              _buildSmallFilterChip('- Tiền ra', _personalTxFilter == 2, () => setState(() => _personalTxFilter = 2)),
            ],
          ),
          const SizedBox(height: 12),

          if (displayed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Không có giao dịch nào thỏa mãn bộ lọc', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
              ),
            )
          else
            ...displayed.map((tx) {
              final rawCat = tx.category ?? '';
              final isCredit = tx.type == TransactionType.credit;
              final cat = rawCat.startsWith('[Cá Nhân] ')
                  ? rawCat.substring(10)
                  : (rawCat.isNotEmpty ? rawCat : (isCredit ? 'Thu nhập' : 'Chưa phân loại'));
              final catColor = isCredit ? const Color(0xFF16A34A) : _getCategoryColor(cat);
              final time = tx.transactionTime;

              return InkWell(
                onTap: () => _showTransactionDetailSheet(context, tx, txProvider),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _buildCategoryBadge(cat, size: 16, padding: 8),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.content.isNotEmpty
                                  ? tx.content
                                  : (isCredit ? 'Nhận tiền qua ${tx.bankCode}' : 'Chi tiêu qua ${tx.bankCode}'),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: catColor.withValues(alpha: 0.4), width: 0.8),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: catColor),
                                  ),
                                ),
                                Text(
                                  '${tx.bankCode} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} (${time.day}/${time.month})',
                                  style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                                ),
                              ],
                            ),
                            if (tx.note != null && tx.note!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Ghi chú: ${tx.note}',
                                style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'}${CurrencyFormatter.formatVND(tx.amount)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isCredit ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // =========================================================================
  // CÁC HỘP THOẠI & MODAL TƯƠNG TÁC
  // =========================================================================



  // MODAL THÊM KHOẢN CHI TIÊU MỚI (HỖ TRỢ ĐẦY ĐỦ DOANH NGHIỆP & CÁ NHÂN THEO ĐÚNG CÁC QUỸ ĐÃ CÀI)
  void _showAddExpenseModal(BuildContext context, TransactionProvider txProvider, {bool? initialIsBusiness}) {
    bool isBusiness = initialIsBusiness ?? (_currentTab == 0);
    final amountCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedCat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final primaryColor = isBusiness ? const Color(0xFF0284C7) : const Color(0xFFE11D48);

          // 1. LẤY DANH SÁCH QUỸ NGƯỜI DÙNG ĐÃ CÀI ĐẶT
          final List<String> availableFunds;
          if (isBusiness) {
            availableFunds = txProvider.businessBudgets.isNotEmpty
                ? txProvider.businessBudgets.keys.toList()
                : ['📦 Quỹ Nhập hàng', '🏢 Quỹ Mặt bằng & Vận hành', '👥 Quỹ Lương nhân viên', '🛡️ Quỹ Dự phòng & Thuế', 'Khác'];
          } else {
            availableFunds = txProvider.personalBudgets.isNotEmpty
                ? txProvider.personalBudgets.keys.toList()
                : (txProvider.expenseCategories.isNotEmpty
                    ? txProvider.expenseCategories
                    : ['Tiền ăn', 'Tiền nhà', 'Xăng xe', 'Mua sắm', 'Hóa đơn', 'Khác']);
          }

          if (selectedCat == null || !availableFunds.contains(selectedCat)) {
            selectedCat = availableFunds.first;
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tiêu đề
                    Row(
                      children: [
                        Icon(
                          isBusiness ? Icons.domain_rounded : Icons.person_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBusiness ? 'Ghi Chi Tiêu Doanh Nghiệp' : 'Ghi Chi Tiêu Cá Nhân',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2 Tab chọn chuyển đổi Doanh Nghiệp vs Cá Nhân
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                isBusiness = true;
                                selectedCat = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isBusiness ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isBusiness ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.business_center_rounded, size: 15, color: isBusiness ? Colors.white : const Color(0xFF475569)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '🏢 Doanh Nghiệp',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isBusiness ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                isBusiness = false;
                                selectedCat = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isBusiness ? const Color(0xFFE11D48) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !isBusiness ? const Color(0xFFE11D48) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_rounded, size: 15, color: !isBusiness ? Colors.white : const Color(0xFF475569)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '👤 Cá Nhân',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: !isBusiness ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phần chọn loại quỹ đã cài + Nút Thêm Quỹ Mới
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Chọn Quỹ Chi Tiêu (${availableFunds.length}):',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        // NÚT THÊM LOẠI QUỸ MỚI TRỰC TIẾP
                        InkWell(
                          onTap: () {
                            _showAddCustomBudgetDialog(
                              context,
                              txProvider,
                              isBusiness: isBusiness,
                              onCreated: (newFundName) {
                                setSheetState(() {
                                  selectedCat = newFundName;
                                });
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBusiness ? const Color(0xFFE0F2FE) : const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isBusiness ? const Color(0xFFBAE6FD) : const Color(0xFFFECDD3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 14, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '+ Thêm loại quỹ',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Danh sách các Quỹ người dùng đã set
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableFunds.map((cat) {
                        final isSelected = selectedCat == cat;
                        return ChoiceChip(
                          avatar: Icon(
                            isBusiness ? Icons.account_balance_rounded : _getCategoryIconData(cat),
                            size: 14,
                            color: isSelected ? Colors.white : primaryColor,
                          ),
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedCat = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text('Số tiền chi (VNĐ):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                      decoration: InputDecoration(
                        hintText: 'VD: 50000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixText: 'VNĐ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Gợi ý nhanh số tiền chi
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (isBusiness
                              ? [100000, 200000, 500000, 1000000, 2000000, 5000000]
                              : [20000, 50000, 100000, 200000, 500000, 1000000])
                          .map((amt) {
                        return InkWell(
                          onTap: () => amountCtrl.text = amt.toString(),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              amt >= 1000000 ? '${(amt / 1000000).toStringAsFixed(0)}tr' : '${(amt / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    const Text('Nội dung chi tiêu:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contentCtrl,
                      decoration: InputDecoration(
                        hintText: isBusiness
                            ? 'VD: Chi tiền mặt nhập hàng, Tiền điện nước cửa hàng...'
                            : 'VD: Ăn phở bò, Mua cà phê, Đổ xăng...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Ghi chú thêm (tùy chọn):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú thêm hoá đơn / người nhận...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
                          if (amt > 0) {
                            final chosenFund = selectedCat ?? 'Khác';
                            final fullCat = isBusiness ? '[Doanh Nghiệp] $chosenFund' : '[Cá Nhân] $chosenFund';
                            final contentText = contentCtrl.text.trim().isNotEmpty
                                ? contentCtrl.text.trim()
                                : (isBusiness ? 'Chi quỹ $chosenFund' : 'Chi tiêu tiền mặt');

                            await txProvider.addManualTransaction(
                              amount: amt,
                              type: TransactionType.debit,
                              content: contentText,
                              category: fullCat,
                              note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                              bankCode: 'TIỀN MẶT',
                              appMode: isBusiness ? 'business' : 'personal',
                            );
                            if (context.mounted) {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã ghi chi -${CurrencyFormatter.formatVND(amt)} vào quỹ "$chosenFund"!'),
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập số tiền chi lớn hơn 0đ!'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Text(
                          isBusiness ? 'Lưu Khoản Chi Doanh Nghiệp' : 'Lưu Khoản Chi Cá Nhân',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // XEM CHI TIẾT GIAO DỊCH
  void _showTransactionDetailSheet(BuildContext context, NormalizedTransaction tx, TransactionProvider txProvider) {
    final existingCat = tx.category ?? '';
    String currentCat = existingCat.replaceFirst('[Cá Nhân] ', '').replaceFirst('[Doanh Nghiệp] ', '').trim();
    String currentScope = 'Cá Nhân';
    if (existingCat.startsWith('[Doanh Nghiệp]')) {
      currentScope = 'Doanh Nghiệp';
    } else if (existingCat.startsWith('[Cá Nhân]')) {
      currentScope = 'Cá Nhân';
    }

    if (txProvider.businessBudgets.containsKey(currentCat)) {
      currentScope = 'Doanh Nghiệp';
    } else if (txProvider.personalBudgets.containsKey(currentCat)) {
      currentScope = 'Cá Nhân';
    }

    if (currentCat.isEmpty) {
      currentCat = tx.type == TransactionType.credit
          ? (currentScope == 'Doanh Nghiệp' ? 'Bán hàng' : 'Tiền lương')
          : 'Tiền ăn';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // LẤY CHÍNH XÁC DANH SÁCH QUỸ NGƯỜI DÙNG ĐÃ CÀI ĐẶT
          final List<String> bizCategories = txProvider.businessBudgets.isNotEmpty
              ? [
                  ...txProvider.businessBudgets.keys,
                  if (currentCat.isNotEmpty && !txProvider.businessBudgets.containsKey(currentCat) && currentCat != 'Chưa phân loại' && currentCat != 'Khác') currentCat,
                ]
              : ['📦 Quỹ Nhập hàng', '🏢 Quỹ Mặt bằng & Vận hành', '👥 Quỹ Lương nhân viên', '🛡️ Quỹ Dự phòng & Thuế', 'Khác'];

          final List<String> personalCategories = txProvider.personalBudgets.isNotEmpty
              ? [
                  ...txProvider.personalBudgets.keys,
                  if (currentCat.isNotEmpty && !txProvider.personalBudgets.containsKey(currentCat) && currentCat != 'Chưa phân loại' && currentCat != 'Khác') currentCat,
                ]
              : (txProvider.expenseCategories.isNotEmpty
                  ? txProvider.expenseCategories
                  : ['Tiền ăn', 'Tiền nhà', 'Xăng xe', 'Khác']);

          final cats = currentScope == 'Doanh Nghiệp' ? bizCategories : personalCategories;
          if (!cats.contains(currentCat)) {
            currentCat = cats.isNotEmpty ? cats.first : 'Khác';
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tx.type == TransactionType.credit ? 'Chi Tiết Tiền Nhận Được' : 'Chi Tiết Khoản Chi Ra',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Số tiền giao dịch', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
                    subtitle: Text(
                      '${tx.type.isCredit ? '+' : '-'}${CurrencyFormatter.formatVND(tx.amount)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: tx.type.isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  _buildDetailRow('Ngân hàng / Cổng', tx.bankCode),
                  _buildDetailRow('Thời gian', '${tx.transactionTime.hour.toString().padLeft(2, '0')}:${tx.transactionTime.minute.toString().padLeft(2, '0')} ngày ${tx.transactionTime.day}/${tx.transactionTime.month}/${tx.transactionTime.year}'),
                  if (tx.content.isNotEmpty) _buildDetailRow('Nội dung', tx.content),
                  if (tx.orderCode != null && tx.orderCode!.isNotEmpty) _buildDetailRow('Mã đơn hàng', tx.orderCode!),
                  
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),

                  // KHỐI CHỌN PHÂN LOẠI CÁ NHÂN & DOANH NGHIỆP
                  const Text(
                    'Phân loại: Cá Nhân hoặc Doanh Nghiệp',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.domain_rounded, size: 16),
                          label: const Center(child: Text('🏢 Doanh Nghiệp')),
                          selected: currentScope == 'Doanh Nghiệp',
                          selectedColor: const Color(0xFF0284C7),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: currentScope == 'Doanh Nghiệp' ? Colors.white : const Color(0xFF334155),
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => currentScope = 'Doanh Nghiệp');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.person_rounded, size: 16),
                          label: const Center(child: Text('👤 Cá Nhân')),
                          selected: currentScope == 'Cá Nhân',
                          selectedColor: const Color(0xFFE11D48),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: currentScope == 'Cá Nhân' ? Colors.white : const Color(0xFF334155),
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => currentScope = 'Cá Nhân');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chọn danh mục / Quỹ ($currentScope):',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      InkWell(
                        onTap: () {
                          _showAddCustomBudgetDialog(
                            context,
                            txProvider,
                            isBusiness: currentScope == 'Doanh Nghiệp',
                            onCreated: (newFundName) {
                              setModalState(() {
                                currentCat = newFundName;
                              });
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 14,
                                color: currentScope == 'Doanh Nghiệp' ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+ Thêm quỹ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: currentScope == 'Doanh Nghiệp' ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...cats.map((cat) {
                        final isSel = currentCat == cat;
                        final chipColor = currentScope == 'Doanh Nghiệp' ? const Color(0xFF0284C7) : const Color(0xFFE11D48);
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: chipColor,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF334155),
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => currentCat = cat);
                          },
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentScope == 'Doanh Nghiệp' ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final fullCategory = '[$currentScope] $currentCat';
                        final targetAppMode = currentScope == 'Doanh Nghiệp' ? 'business' : 'personal';
                        await txProvider.updateTransactionCategory(tx.id, fullCategory, appMode: targetAppMode);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Đã phân loại giao dịch vào "$fullCategory"!'),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Lưu Phân Loại Giao Dịch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: WebTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallFilterChip(String label, bool isSelected, VoidCallback onTap) {
    Color bg;
    Color border;
    Color text;

    final isIncome = label.contains('Tiền vào');
    final isExpense = label.contains('Tiền ra');

    if (isIncome) {
      bg = isSelected ? const Color(0xFF16A34A) : const Color(0xFFF0FDF4);
      border = isSelected ? const Color(0xFF16A34A) : const Color(0xFFBBF7D0);
      text = isSelected ? Colors.white : const Color(0xFF15803D);
    } else if (isExpense) {
      bg = isSelected ? const Color(0xFFDC2626) : const Color(0xFFFFF1F2);
      border = isSelected ? const Color(0xFFDC2626) : const Color(0xFFFECDD3);
      text = isSelected ? Colors.white : const Color(0xFFBE123C);
    } else {
      final activeColor = _currentTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);
      bg = isSelected ? activeColor : const Color(0xFFF8FAFC);
      border = isSelected ? activeColor : const Color(0xFFE2E8F0);
      text = isSelected ? Colors.white : const Color(0xFF475569);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: text,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // XUẤT TÓM TẮT ĐỐI SOÁT BÁO CÁO (EXPORT FINANCIAL SUMMARY)
  // =========================================================================
  void _exportReportSummary(
    BuildContext context, {
    required DateTime startDate,
    required DateTime endDate,
    required double totalRevenue,
    required double totalExpense,
    required double netCashFlow,
    required int creditCount,
    required int debitCount,
    required Map<String, double> bankDistribution,
    required Map<String, double> categoryDistribution,
  }) {
    final startStr = '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
    final endStr = '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';

    final buffer = StringBuffer();
    buffer.writeln('====================================');
    buffer.writeln('   BÁO CÁO TÀI CHÍNH ĐỐI SOÁT DÒNG TIỀN');
    buffer.writeln('====================================');
    buffer.writeln('Thời gian thống kê: $startStr -> $endStr');
    buffer.writeln('');
    buffer.writeln('1. TỔNG QUAN DOANH NGHIỆP & BÁN HÀNG:');
    buffer.writeln('   - Tổng thu (Tiền vào): +${CurrencyFormatter.formatVND(totalRevenue)} ($creditCount giao dịch)');
    buffer.writeln('   - Tổng chi (Tiền ra): -${CurrencyFormatter.formatVND(totalExpense)} ($debitCount giao dịch)');
    buffer.writeln('   - Dòng tiền ròng: ${netCashFlow >= 0 ? '+' : ''}${CurrencyFormatter.formatVND(netCashFlow)}');
    if (totalRevenue > 0) {
      buffer.writeln('   - Tỷ suất dòng tiền: ${((netCashFlow / totalRevenue) * 100).toStringAsFixed(1)}%');
      buffer.writeln('   - Giá trị trung bình/đơn: ${CurrencyFormatter.formatVND(totalRevenue / (creditCount > 0 ? creditCount : 1))}');
    }
    buffer.writeln('');
    final txProvider = context.read<TransactionProvider>();
    final budgets = txProvider.monthlyBudgets;
    if (budgets.isNotEmpty) {
      buffer.writeln('2. THEO DÕI QUỸ NGÂN SÁCH DOANH NGHIỆP:');
      for (final entry in budgets.entries) {
        final fundName = entry.key;
        final budgetAmt = entry.value;
        final spentAmt = categoryDistribution[fundName] ?? 0.0;
        final pct = budgetAmt > 0 ? ((spentAmt / budgetAmt) * 100).toStringAsFixed(1) : '0';
        buffer.writeln('   • Quỹ "$fundName": Hạn mức ${CurrencyFormatter.formatVND(budgetAmt)} | Đã dùng: ${CurrencyFormatter.formatVND(spentAmt)} ($pct%)');
      }
      buffer.writeln('');
    }

    if (bankDistribution.isNotEmpty) {
      buffer.writeln('3. DÒNG TIỀN THEO CỔNG THANH TOÁN / NGÂN HÀNG:');
      for (final entry in bankDistribution.entries) {
        final pct = totalRevenue > 0 ? ((entry.value / totalRevenue) * 100).toStringAsFixed(1) : '0';
        buffer.writeln('   • ${entry.key}: ${CurrencyFormatter.formatVND(entry.value)} ($pct%)');
      }
      buffer.writeln('');
    }
    if (categoryDistribution.isNotEmpty) {
      buffer.writeln('4. PHÂN BỔ CHI TIÊU THEO DANH MỤC CÁ NHÂN:');
      for (final entry in categoryDistribution.entries) {
        final pct = totalExpense > 0 ? ((entry.value / totalExpense) * 100).toStringAsFixed(1) : '0';
        buffer.writeln('   • ${entry.key}: ${CurrencyFormatter.formatVND(entry.value)} ($pct%)');
      }
      buffer.writeln('');
    }
    buffer.writeln('Xuất từ AutoBank FinTech Engine lúc: ${DateTime.now()}');
    buffer.writeln('====================================');

    final text = buffer.toString();
    Clipboard.setData(ClipboardData(text: text));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF0F172A), size: 22),
            SizedBox(width: 8),
            Text('Đã Xuất Báo Cáo Thành Công', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bản tóm tắt đối soát tài chính đã được sao chép vào bộ nhớ tạm của máy. Bạn có thể dán vào Zalo, Excel, Gmail hoặc gửi cho kế toán.',
              style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
            label: const Text('Sao Chép Lại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép lại báo cáo vào clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER: MÀU SẮC & ICON CHUẨN VECTOR FINTECH (KHÔNG DÙNG EMOJI)
  // =========================================================================

  Color _getBankBrandColor(String bankCode) {
    final b = bankCode.toUpperCase();
    if (b.contains('VCB') || b.contains('VIETCOM')) return const Color(0xFF15803D);
    if (b.contains('MB') || b.contains('MILITARY')) return const Color(0xFF1D4ED8);
    if (b.contains('TECH') || b.contains('TCB')) return const Color(0xFFDC2626);
    if (b.contains('ACB')) return const Color(0xFF0284C7);
    if (b.contains('VP') || b.contains('VPB')) return const Color(0xFF059669);
    if (b.contains('TP') || b.contains('TPB')) return const Color(0xFF9333EA);
    if (b.contains('BIDV')) return const Color(0xFF0D9488);
    if (b.contains('MOMO')) return const Color(0xFFA21CAF);
    if (b.contains('ZALO')) return const Color(0xFF0284C7);
    return const Color(0xFF475569);
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Tiền ăn':
        return const Color(0xFF16A34A);
      case 'Tiền nhà':
        return const Color(0xFFD97706);
      case 'Đi chơi':
        return const Color(0xFF8B5CF6);
      case 'Du lịch':
        return const Color(0xFF0284C7);
      case 'Mua sắm':
        return const Color(0xFFEC4899);
      case 'Tiền điện nước':
        return const Color(0xFFF59E0B);
      case 'Xăng xe':
        return const Color(0xFF475569);
      case 'Học tập':
      case 'Giáo dục':
        return const Color(0xFF3B82F6);
      case 'Y tế':
      case 'Sức khỏe':
        return const Color(0xFFEF4444);
      case 'Lương / Thu nhập':
        return const Color(0xFF10B981);
      case 'Đầu tư':
        return const Color(0xFF6366F1);
      default:
        final lower = cat.toLowerCase();
        if (lower.contains('người yêu') || lower.contains('tình cảm')) {
          return const Color(0xFFEC4899);
        }
        if (lower.contains('đầu tư') || lower.contains('chứng khoán') || lower.contains('tiết kiệm')) {
          return const Color(0xFF10B981);
        }
        if (lower.contains('gym') || lower.contains('thể thao') || lower.contains('fitness')) {
          return const Color(0xFFF97316);
        }
        if (lower.contains('sách') || lower.contains('học')) {
          return const Color(0xFF0284C7);
        }
        if (lower.contains('quỹ đen') || lower.contains('bí mật')) {
          return const Color(0xFF8B5CF6);
        }
        return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIconData(String cat) {
    switch (cat) {
      case 'Tiền ăn':
        return Icons.restaurant_rounded;
      case 'Tiền nhà':
        return Icons.home_work_rounded;
      case 'Đi chơi':
        return Icons.celebration_rounded;
      case 'Du lịch':
        return Icons.flight_takeoff_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Tiền điện nước':
        return Icons.bolt_rounded;
      case 'Xăng xe':
        return Icons.local_gas_station_rounded;
      case 'Học tập':
      case 'Giáo dục':
        return Icons.school_rounded;
      case 'Y tế':
      case 'Sức khỏe':
        return Icons.medical_services_rounded;
      case 'Lương / Thu nhập':
        return Icons.payments_rounded;
      case 'Đầu tư':
        return Icons.trending_up_rounded;
      default:
        final lower = cat.toLowerCase();
        if (lower.contains('người yêu') || lower.contains('tình cảm')) {
          return Icons.favorite_rounded;
        }
        if (lower.contains('gym') || lower.contains('thể thao') || lower.contains('fitness')) {
          return Icons.fitness_center_rounded;
        }
        if (lower.contains('sách') || lower.contains('học')) {
          return Icons.menu_book_rounded;
        }
        if (lower.contains('đầu tư') || lower.contains('chứng khoán') || lower.contains('tiết kiệm')) {
          return Icons.savings_rounded;
        }
        if (lower.contains('quỹ đen') || lower.contains('bí mật')) {
          return Icons.vpn_key_rounded;
        }
        return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildCategoryBadge(
    String cat, {
    double size = 15,
    double padding = 6,
    Color? color,
    Color? bg,
  }) {
    final effectiveColor = color ?? _getCategoryColor(cat);
    final effectiveBg = bg ?? effectiveColor.withValues(alpha: 0.12);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getCategoryIconData(cat),
        size: size,
        color: effectiveColor,
      ),
    );
  }

  void _showAdjustRevenueModal(BuildContext context, TransactionProvider txProvider) {
    bool isAddition = true;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final double currentTotal = txProvider.todayTotal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final amt = double.tryParse(amountCtrl.text.replaceAll(',', '').replaceAll('.', '')) ?? 0.0;
          final previewTotal = isAddition
              ? (currentTotal + amt)
              : (currentTotal - amt).clamp(0.0, double.infinity);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: WebTheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'Tùy chỉnh Doanh Thu (+/-)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Điều chỉnh trực tiếp số liệu dòng tiền và doanh thu để khớp với thực tế.',
                    style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => isAddition = true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isAddition ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAddition ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                                width: isAddition ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_rounded, size: 18, color: isAddition ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  '+ THÊM DOANH THU',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isAddition ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => isAddition = false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isAddition ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !isAddition ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                                width: !isAddition ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.remove_circle_rounded, size: 18, color: !isAddition ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  '- TRỪ DOANH THU',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: !isAddition ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Số tiền cần ${isAddition ? 'cộng thêm' : 'trừ bớt'} (VNĐ)',
                      prefixIcon: Icon(
                        isAddition ? Icons.add_rounded : Icons.remove_rounded,
                        color: isAddition ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                      hintText: 'Ví dụ: 100000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [50000, 100000, 200000, 500000, 1000000].map((quickAmt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('${isAddition ? '+' : '-'}${CurrencyFormatter.formatVND(quickAmt.toDouble())}'),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAddition ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                            backgroundColor: isAddition ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            onPressed: () {
                              amountCtrl.text = quickAmt.toString();
                              setDialogState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Lý do điều chỉnh (Tùy chọn)',
                      hintText: isAddition ? 'Bù tiền mặt, đơn thanh toán ngoài...' : 'Sai lệch số liệu, hoàn tiền khách...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hiện tại:', style: TextStyle(fontSize: 11, color: WebTheme.textMuted)),
                            SizedBox(height: 2),
                            Text('Sau điều chỉnh:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.textHeading)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatVND(currentTotal),
                              style: const TextStyle(fontSize: 12, color: WebTheme.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatVND(previewTotal),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isAddition ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isAddition ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập số tiền lớn hơn 0đ')),
                          );
                          return;
                        }
                        Navigator.pop(sheetCtx);
                        await txProvider.adjustTodayRevenue(
                          amount: amt,
                          isAddition: isAddition,
                          note: noteCtrl.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: isAddition ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                              content: Text('Đã ${isAddition ? 'cộng thêm' : 'trừ bớt'} ${CurrencyFormatter.formatVND(amt)} vào doanh thu hôm nay!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Xác nhận ${isAddition ? 'Cộng' : 'Trừ'} ${amt > 0 ? CurrencyFormatter.formatVND(amt) : ''}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

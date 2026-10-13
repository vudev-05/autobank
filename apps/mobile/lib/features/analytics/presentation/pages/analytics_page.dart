import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
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

  // Danh mục đang lọc trong tab Cá Nhân (null = tất cả)
  String? _selectedExpenseCategory;

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

    // 3. TÍNH CÁC CHỈ SỐ DOANH NGHIỆP (THU & CHI) TỪ DỮ LIỆU THẬT
    final creditTx = filteredTx.where((t) => t.type == TransactionType.credit).toList();
    final debitTx = filteredTx.where((t) => t.type == TransactionType.debit).toList();

    final double totalRevenue = creditTx.fold(0.0, (sum, t) => sum + t.amount);
    final double totalExpense = debitTx.fold(0.0, (sum, t) => sum + t.amount);
    final double netCashFlow = totalRevenue - totalExpense;
    final int creditCount = creditTx.length;
    final int debitCount = debitTx.length;

    final double avgRevenue = creditCount > 0 ? totalRevenue / creditCount : 0.0;
    double maxRevenue = 0.0;
    for (final tx in creditTx) {
      if (tx.amount > maxRevenue) maxRevenue = tx.amount;
    }

    // 4. PHÂN TÍCH THEO NGÂN HÀNG & VÍ THỰC TẾ
    final Map<String, double> bankDistribution = {};
    final Map<String, int> bankCount = {};
    for (final tx in creditTx) {
      bankDistribution[tx.bankCode] = (bankDistribution[tx.bankCode] ?? 0) + tx.amount;
      bankCount[tx.bankCode] = (bankCount[tx.bankCode] ?? 0) + 1;
    }

    // 5. PHÂN TÍCH KHUNG GIỜ CAO ĐIỂM BÁN HÀNG THỰC TẾ
    final Map<String, double> hourlySlots = {
      'Sáng\n06-11h': 0.0,
      'Trưa\n11-14h': 0.0,
      'Chiều\n14-18h': 0.0,
      'Tối\n18-22h': 0.0,
      'Đêm\n22-06h': 0.0,
    };
    for (final tx in creditTx) {
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

    // 6. PHÂN TÍCH CHI TIÊU CÁ NHÂN THEO DANH MỤC THỰC TẾ
    final Map<String, double> categoryDistribution = {};
    final Map<String, int> categoryCount = {};
    for (final tx in debitTx) {
      final cat = tx.category ?? 'Chưa phân loại';
      categoryDistribution[cat] = (categoryDistribution[cat] ?? 0) + tx.amount;
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }

    double maxExpense = 0.0;
    for (final tx in debitTx) {
      if (tx.amount > maxExpense) maxExpense = tx.amount;
    }

    // 7. TÍNH TOÁN QUỸ NGÂN SÁCH THÁNG NÀY (BUDGET PLANNER)
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final monthDebitTx = txList.where((tx) =>
        tx.type == TransactionType.debit &&
        tx.transactionTime.isAfter(thisMonthStart.subtract(const Duration(seconds: 1)))).toList();

    final Map<String, double> monthCategorySpent = {};
    for (final tx in monthDebitTx) {
      final cat = tx.category ?? 'Chưa phân loại';
      monthCategorySpent[cat] = (monthCategorySpent[cat] ?? 0) + tx.amount;
    }
    final double totalMonthSpent = monthDebitTx.fold(0.0, (sum, tx) => sum + tx.amount);

    return Scaffold(
      backgroundColor: WebTheme.slateBg,
      appBar: AppBar(
        title: Text(
          _currentTab == 0 ? 'Báo Cáo Bán Hàng & Dòng Tiền' : 'Quản Lý Chi Tiêu Cá Nhân',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: WebTheme.textHeading,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_currentTab == 1)
            IconButton(
              tooltip: 'Thêm khoản chi mới',
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE11D48)),
              onPressed: () => _showAddExpenseModal(context, txProvider),
            ),
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: const Icon(Icons.refresh_rounded, color: WebTheme.primary),
            onPressed: () {
              txProvider.loadLocalTransactions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã tính toán lại toàn bộ số liệu theo từng ngày!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: WebTheme.cardBorder, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. THANH CHỌN TAB: DOANH NGHIỆP VS CÁ NHÂN
          _buildMainTabSegment(),

          const SizedBox(height: 12),

          // 2. BỘ LỌC KỲ HẠN THỜI GIAN (HÔM NAY / 7 NGÀY / THÁNG NÀY / TOÀN BỘ / CHỌN NGÀY)
          _buildPeriodSelector(),

          const SizedBox(height: 14),

          // 3. NỘI DUNG TƯƠNG ỨNG THEO TAB
          if (_currentTab == 0) ...[
            // TAB DOANH NGHIỆP: BÁO CÁO DÒNG TIỀN & BÁN HÀNG
            _buildBusinessHeroCard(totalRevenue, totalExpense, netCashFlow),
            const SizedBox(height: 12),
            _buildBusinessKpiGrid(creditCount, avgRevenue, maxRevenue),
            const SizedBox(height: 14),
            _buildBusinessHourlyChart(hourlySlots, totalRevenue),
            const SizedBox(height: 14),
            _buildBankDistributionCard(bankDistribution, bankCount, totalRevenue),
            const SizedBox(height: 14),
            _buildBusinessTransactionHistory(filteredTx, txProvider),
          ] else ...[
            // TAB CÁ NHÂN: PHẦN MỀM QUẢN LÝ CHI TIÊU & QUỸ NGÂN SÁCH
            _buildPersonalExpenseHeroCard(totalExpense, debitCount, maxExpense, startDate, endDate),
            const SizedBox(height: 12),
            _buildPersonalBudgetCard(monthCategorySpent, totalMonthSpent, txProvider),
            const SizedBox(height: 14),
            _buildPersonalCategoryDistribution(categoryDistribution, categoryCount, totalExpense),
            const SizedBox(height: 14),
            _buildPersonalExpenseHistory(debitTx, txProvider),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1. THANH CHUYỂN ĐỔI TAB CHÍNH (DOANH NGHIỆP vs CÁ NHÂN)
  Widget _buildMainTabSegment() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 0),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: _currentTab == 0
                      ? const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)])
                      : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 16,
                      color: _currentTab == 0 ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '🏢 Doanh Nghiệp',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _currentTab == 0 ? Colors.white : const Color(0xFF475569),
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
              onTap: () => setState(() => _currentTab = 1),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: _currentTab == 1
                      ? const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)])
                      : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_pin_rounded,
                      size: 16,
                      color: _currentTab == 1 ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '👤 Cá Nhân (Chi Tiêu)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _currentTab == 1 ? Colors.white : const Color(0xFF475569),
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
                            ? (_currentTab == 0 ? WebTheme.primary : const Color(0xFFE11D48))
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
                        ? (_currentTab == 0 ? WebTheme.primary : const Color(0xFFE11D48))
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

  // HERO CARD DOANH NGHIỆP (TỔNG THU - TỔNG CHI - DÒNG TIỀN RÒNG) - NỀN SÁNG CAO CẤP, KHÔNG CÓ NỀN ĐEN
  Widget _buildBusinessHeroCard(double totalRevenue, double totalExpense, double netFlow) {
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
                  Icon(Icons.query_stats_rounded, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BÁO CÁO DÒNG TIỀN THỰC TẾ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Text(
                  'Cộng dồn theo ngày ✓',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DÒNG TIỀN RÒNG / LỢI NHUẬN
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.formatVND(netFlow),
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: netFlow >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  netFlow >= 0 ? '(Dương dòng tiền)' : '(Âm dòng tiền)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: netFlow >= 0 ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text('Dòng tiền ròng (Tổng Tiền Vào - Tổng Tiền Ra)', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),

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
                          Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text('TỔNG THU (TIỀN VÀO)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatVND(totalRevenue),
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
                          Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFE11D48)),
                          SizedBox(width: 4),
                          Text('TỔNG CHI (TIỀN RA)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatVND(totalExpense),
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

  // BIỂU ĐỒ KHUNG GIỜ CAO ĐIỂM BÁN HÀNG THỰC TẾ
  Widget _buildBusinessHourlyChart(Map<String, double> hourlySlots, double total) {
    double maxSlotVal = 0.0;
    hourlySlots.forEach((k, v) {
      if (v > maxSlotVal) maxSlotVal = v;
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Dữ liệu giờ thực ⭐', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ),
            ],
          ),
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

  // PHÂN BỔ THEO NGÂN HÀNG & VÍ
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(bankName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
                        color: WebTheme.primary,
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

  // LỊCH SỬ GIAO DỊCH DOANH NGHIỆP (KÈM LỌC TẤT CẢ / THU / CHI)
  Widget _buildBusinessTransactionHistory(List<NormalizedTransaction> txList, TransactionProvider txProvider) {
    List<NormalizedTransaction> displayed = txList;
    if (_businessTxFilter == 1) {
      displayed = txList.where((t) => t.type == TransactionType.credit).toList();
    } else if (_businessTxFilter == 2) {
      displayed = txList.where((t) => t.type == TransactionType.debit).toList();
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

          // Segment lọc Thu / Chi / Tất cả
          Row(
            children: [
              _buildSmallFilterChip('Tất cả', _businessTxFilter == 0, () => setState(() => _businessTxFilter = 0)),
              const SizedBox(width: 6),
              _buildSmallFilterChip('+ Tiền vào (Thu)', _businessTxFilter == 1, () => setState(() => _businessTxFilter = 1)),
              const SizedBox(width: 6),
              _buildSmallFilterChip('- Tiền ra (Chi)', _businessTxFilter == 2, () => setState(() => _businessTxFilter = 2)),
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

  // HERO CARD CHI TIÊU CÁ NHÂN
  Widget _buildPersonalExpenseHeroCard(double totalExpense, int count, double maxExpense, DateTime start, DateTime end) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(WebTheme.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30E11D48),
            blurRadius: 14,
            offset: Offset(0, 6),
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
                  Icon(Icons.pie_chart_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'TỔNG TIỀN ĐÃ CHI TIÊU TRONG KỲ',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${start.day}/${start.month} - ${end.day}/${end.month}',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.formatVND(totalExpense),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Số khoản đã chi', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text('$count giao dịch', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Khoản chi lớn nhất', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(CurrencyFormatter.formatVND(maxExpense), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
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

  // =========================================================================
  // QUỸ NGÂN SÁCH CHI TIÊU HÀNG THÁNG & CÁC CẤP ĐỘ CẢNH BÁO
  // 🟢 Mức tốt (< 70%) | 🟡 Cảnh báo (70% - 90%) | 🟠 Nguy kịch (90% - 100%) | 🔴 Lố ngân sách (> 100%)
  // =========================================================================
  Widget _buildPersonalBudgetCard(Map<String, double> monthCategorySpent, double totalMonthSpent, TransactionProvider txProvider) {
    final budgets = txProvider.monthlyBudgets;
    final totalBudget = budgets.values.fold(0.0, (sum, v) => sum + v);
    final overallPct = totalBudget > 0 ? (totalMonthSpent / totalBudget) : 0.0;

    // Xác định trạng thái cảnh báo tổng thể
    Color statusColor;
    Color statusBg;
    Color statusBorder;
    String statusTitle;
    String statusDesc;
    IconData statusIcon;

    if (overallPct > 1.0) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECDD3);
      statusTitle = 'LỐ CHI TIÊU (+${((overallPct - 1.0) * 100).toStringAsFixed(0)}%)';
      statusDesc = 'Báo động! Bạn đã tiêu vượt hạn mức ${CurrencyFormatter.formatVND(totalMonthSpent - totalBudget)}.';
      statusIcon = Icons.crisis_alert_rounded;
    } else if (overallPct >= 0.90) {
      statusColor = const Color(0xFFEA580C);
      statusBg = const Color(0xFFFFF7ED);
      statusBorder = const Color(0xFFFED7AA);
      statusTitle = 'NGUY KỊCH (${(overallPct * 100).toStringAsFixed(0)}%)';
      statusDesc = 'Sắp cạn kiệt ngân sách tháng! Cần dừng ngay các khoản chi không cần thiết.';
      statusIcon = Icons.error_outline_rounded;
    } else if (overallPct >= 0.70) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusTitle = 'CẢNH BÁO (${(overallPct * 100).toStringAsFixed(0)}%)';
      statusDesc = 'Đã tiêu trên 70% ngân sách tháng. Nên tiết chế chi tiêu để giữ an toàn.';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFBBF7D0);
      statusTitle = 'MỨC TỐT (${(overallPct * 100).toStringAsFixed(0)}%)';
      statusDesc = 'Tài chính rất an toàn! Tốc độ chi tiêu tháng đang trong tầm kiểm soát.';
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & nút cấu hình hạn mức
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE11D48), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Quỹ Ngân Sách Chi Tiêu Tháng',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showBudgetSettingsSheet(context, txProvider),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 13, color: Color(0xFFE11D48)),
                      SizedBox(width: 4),
                      Text(
                        'Lập quỹ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Khung cảnh báo trạng thái
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusTitle,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã chi ${CurrencyFormatter.formatVND(totalMonthSpent)}',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: statusColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDesc,
                        style: TextStyle(fontSize: 11, color: statusColor.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Thanh tiến trình tổng thể % sắp đầy trên 1 tháng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ chi tiêu tháng: ${(overallPct * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              Text(
                'Tổng quỹ: ${CurrencyFormatter.formatVND(totalBudget)}',
                style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overallPct.clamp(0.02, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              color: statusColor,
            ),
          ),
          const SizedBox(height: 16),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi Tiết Từng Quỹ Danh Mục',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
              ),
              Text(
                '${budgets.length} quỹ đang theo dõi',
                style: const TextStyle(fontSize: 10.5, color: WebTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Danh sách từng quỹ danh mục (Ví dụ Tiền ăn 3tr 1 tháng...)
          ...budgets.entries.map((entry) {
            final cat = entry.key;
            final budgetAmt = entry.value;
            final spentAmt = monthCategorySpent[cat] ?? 0.0;
            final catPct = budgetAmt > 0 ? (spentAmt / budgetAmt) : 0.0;

            Color catColor;
            String catBadge;
            Color catBg;
            if (catPct > 1.0) {
              catColor = const Color(0xFFDC2626);
              catBg = const Color(0xFFFEE2E2);
              catBadge = 'Lố +${CurrencyFormatter.formatVND(spentAmt - budgetAmt)}';
            } else if (catPct >= 0.90) {
              catColor = const Color(0xFFEA580C);
              catBg = const Color(0xFFFFEDD5);
              catBadge = 'Nguy kịch (${(catPct * 100).toStringAsFixed(0)}%)';
            } else if (catPct >= 0.70) {
              catColor = const Color(0xFFD97706);
              catBg = const Color(0xFFFEF3C7);
              catBadge = 'Cảnh báo (${(catPct * 100).toStringAsFixed(0)}%)';
            } else {
              catColor = const Color(0xFF16A34A);
              catBg = const Color(0xFFDCFCE7);
              catBadge = 'Mức tốt (${(catPct * 100).toStringAsFixed(0)}%)';
            }

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(_getCategoryIcon(cat), style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: catBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: catColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              catBadge,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: catColor),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            tooltip: 'Chỉnh hạn mức quỹ $cat',
                            onPressed: () => _showSingleBudgetEditDialog(context, txProvider, cat, budgetAmt),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã chi: ${CurrencyFormatter.formatVND(spentAmt)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: catPct > 1.0 ? const Color(0xFFDC2626) : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        'Hạn mức: ${CurrencyFormatter.formatVND(budgetAmt)}',
                        style: const TextStyle(fontSize: 10.5, color: WebTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: catPct.clamp(0.02, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: catColor,
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

  // HỘP THOẠI CHỈNH SỬA NHANH HẠN MỨC 1 DANH MỤC
  void _showSingleBudgetEditDialog(BuildContext context, TransactionProvider txProvider, String category, double currentBudget) {
    final ctrl = TextEditingController(text: currentBudget.toInt().toString());
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(_getCategoryIcon(category), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Quỹ $category (Tháng)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hạn mức chi tiêu hàng tháng (VNĐ):', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
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
              children: [1000000, 2000000, 3000000, 5000000].map((amt) {
                return InkWell(
                  onTap: () => ctrl.text = amt.toString(),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newAmt = double.tryParse(ctrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
              if (newAmt > 0) {
                txProvider.setCategoryBudget(category, newAmt);
              }
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật quỹ "$category": ${CurrencyFormatter.formatVND(newAmt)}/tháng!'),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Lưu Hạn Mức', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // BOTTOM SHEET THIẾT LẬP TOÀN BỘ QUỸ CHI TIÊU HÀNG THÁNG
  void _showBudgetSettingsSheet(BuildContext context, TransactionProvider txProvider) {
    String selectedCategory = 'Tiền ăn';
    final amountCtrl = TextEditingController(text: '3000000');

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

                  const Row(
                    children: [
                      Icon(Icons.savings_rounded, color: Color(0xFFE11D48), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Thiết Lập Quỹ Chi Tiêu Hàng Tháng',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đặt hạn mức tối đa mỗi tháng cho từng danh mục để theo dõi % chi tiêu và nhận các cảnh báo kịp thời.',
                    style: TextStyle(fontSize: 11, color: WebTheme.textMuted),
                  ),
                  const SizedBox(height: 16),

                  const Text('1. Chọn danh mục cần lập quỹ:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: txProvider.expenseCategories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text('${_getCategoryIcon(cat)} $cat'),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE11D48),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() {
                              selectedCategory = cat;
                              final existing = txProvider.getCategoryBudget(cat);
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

                  const Text('2. Hạn mức chi tiêu mỗi tháng (VNĐ):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                    decoration: InputDecoration(
                      hintText: 'VD: 3000000',
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
                    children: [
                      {'label': '500K', 'val': 500000},
                      {'label': '1 Triệu', 'val': 1000000},
                      {'label': '2 Triệu', 'val': 2000000},
                      {'label': '3 Triệu', 'val': 3000000},
                      {'label': '5 Triệu', 'val': 5000000},
                      {'label': '10 Triệu', 'val': 10000000},
                    ].map((item) {
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
                        backgroundColor: const Color(0xFFE11D48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
                        if (amt > 0) {
                          txProvider.setCategoryBudget(selectedCategory, amt);
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thiết lập quỹ "$selectedCategory": ${CurrencyFormatter.formatVND(amt)}/tháng!'),
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
              const Text(
                'Phân Loại Danh Mục Chi Tiêu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
              ),
              Text(
                '${categories.length} nhóm chi',
                style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
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
              final icon = _getCategoryIcon(catName);

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
                              Text(icon, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
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

  // DANH SÁCH LỊCH SỬ TỪNG GIAO DỊCH CHI TIÊU (BẤM VÀO ĐỂ GÁN DANH MỤC)
  Widget _buildPersonalExpenseHistory(List<NormalizedTransaction> debitList, TransactionProvider txProvider) {
    List<NormalizedTransaction> displayed = debitList;
    if (_selectedExpenseCategory != null) {
      displayed = debitList.where((t) => (t.category ?? 'Chưa phân loại') == _selectedExpenseCategory).toList();
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch Sử Chi Tiêu Chi Tiết',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Chạm vào giao dịch để gán danh mục (tiền nhà, tiền ăn, đi chơi...)',
                      style: TextStyle(fontSize: 10, color: WebTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 12),

          if (displayed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Không có khoản chi nào trong danh mục này', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
              ),
            )
          else
            ...displayed.map((tx) {
              final cat = tx.category;
              final hasCat = cat != null && cat.isNotEmpty;
              final catColor = hasCat ? _getCategoryColor(cat) : const Color(0xFFD97706);
              final catIcon = hasCat ? _getCategoryIcon(cat) : '❓';
              final time = tx.transactionTime;

              return InkWell(
                onTap: () => _showCategorizeDialog(context, tx, txProvider),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(catIcon, style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.content.isNotEmpty ? tx.content : 'Chi tiêu qua ${tx.bankCode}',
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
                                    hasCat ? cat : 'Gán danh mục',
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
                            '-${CurrencyFormatter.formatVND(tx.amount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE11D48),
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

  // HỘP THOẠI GÁN / CHỌN DANH MỤC CHO 1 GIAO DỊCH (TIỀN NHÀ, TIỀN ĂN, ĐI CHƠI...)
  void _showCategorizeDialog(BuildContext context, NormalizedTransaction tx, TransactionProvider txProvider) {
    String? selectedCategory = tx.category;
    final noteCtrl = TextEditingController(text: tx.note ?? '');
    final customCatCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.category_rounded, color: Color(0xFFE11D48), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gán Danh Mục Quản Lý Chi Tiêu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text(
                              'Số tiền: -${CurrencyFormatter.formatVND(tx.amount)} (${tx.bankCode})',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFE11D48), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'Nội dung: ${tx.content}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Chọn danh mục chi tiêu:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),

                  // Danh sách các danh mục có sẵn
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: txProvider.expenseCategories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      final color = _getCategoryColor(cat);
                      final icon = _getCategoryIcon(cat);

                      return ChoiceChip(
                        label: Text('$icon $cat'),
                        selected: isSelected,
                        selectedColor: color,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                        onSelected: (selected) {
                          setSheetState(() {
                            selectedCategory = selected ? cat : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Thêm danh mục mới tự nhập
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customCatCtrl,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Nhập danh mục mới (VD: Cà phê, Học phí...)',
                            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final text = customCatCtrl.text.trim();
                          if (text.isNotEmpty) {
                            txProvider.addCustomCategory(text);
                            setSheetState(() {
                              selectedCategory = text;
                              customCatCtrl.clear();
                            });
                          }
                        },
                        child: const Text('Thêm mục', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Text('Ghi chú bổ sung:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      hintText: 'VD: Mua cho cả nhà, Tiền mặt đóng theo tháng...',
                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (selectedCategory != null) {
                          await txProvider.updateTransactionCategory(
                            tx.id,
                            selectedCategory!,
                            note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                          );
                          if (context.mounted) {
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã gán "$selectedCategory" cho khoản chi -${CurrencyFormatter.formatVND(tx.amount)}!'),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          Navigator.pop(sheetCtx);
                        }
                      },
                      child: const Text(
                        'Lưu Phân Loại Chi Tiêu',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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

  // MODAL THÊM KHOẢN CHI MỚI THỦ CÔNG (TIỀN MẶT)
  void _showAddExpenseModal(BuildContext context, TransactionProvider txProvider) {
    final amountCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedCat = 'Tiền ăn';

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

                  const Row(
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, color: Color(0xFFE11D48), size: 20),
                      SizedBox(width: 8),
                      Text('Ghi Chép Khoản Chi Tiêu Mới', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Số tiền (VNĐ):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                    decoration: InputDecoration(
                      hintText: 'VD: 50000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Nội dung chi tiêu:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contentCtrl,
                    decoration: InputDecoration(
                      hintText: 'VD: Ăn phở bò, Mua cà phê, Đổ xăng...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Danh mục chi tiêu:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: txProvider.expenseCategories.map((cat) {
                      final isSelected = selectedCat == cat;
                      return ChoiceChip(
                        label: Text('${_getCategoryIcon(cat)} $cat'),
                        selected: isSelected,
                        selectedColor: _getCategoryColor(cat),
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
                  const SizedBox(height: 14),

                  const Text('Ghi chú thêm:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ghi chú bổ sung nếu có',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '').trim()) ?? 0.0;
                        if (amt > 0) {
                          await txProvider.addManualTransaction(
                            amount: amt,
                            type: TransactionType.debit,
                            content: contentCtrl.text.trim().isNotEmpty ? contentCtrl.text.trim() : 'Chi tiêu tiền mặt',
                            category: selectedCat,
                            note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                          );
                          if (context.mounted) {
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm khoản chi -${CurrencyFormatter.formatVND(amt)} ($selectedCat)!'),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Lưu Khoản Chi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
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

  // XEM CHI TIẾT GIAO DỊCH
  void _showTransactionDetailSheet(BuildContext context, NormalizedTransaction tx, TransactionProvider txProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
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
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
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
            if (_currentTab != 0) _buildDetailRow('Nội dung', tx.content),
            if (_currentTab != 0 && tx.orderCode != null) _buildDetailRow('Mã đơn hàng', tx.orderCode!),
            if (tx.category != null) _buildDetailRow('Danh mục', tx.category!),
            const SizedBox(height: 10),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? (_currentTab == 0 ? const Color(0xFF0284C7) : const Color(0xFFE11D48)) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
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
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Tiền ăn':
        return '🍔';
      case 'Tiền nhà':
        return '🏠';
      case 'Đi chơi':
        return '🎉';
      case 'Du lịch':
        return '✈️';
      case 'Mua sắm':
        return '🛍️';
      case 'Tiền điện nước':
        return '💡';
      case 'Xăng xe':
        return '⛽';
      default:
        return '🏷️';
    }
  }
}

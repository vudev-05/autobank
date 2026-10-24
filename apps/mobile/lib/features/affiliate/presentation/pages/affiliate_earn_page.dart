import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_video_guide_modal.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../providers/affiliate_provider.dart';

class AffiliateEarnPage extends StatefulWidget {
  const AffiliateEarnPage({super.key});

  @override
  State<AffiliateEarnPage> createState() => _AffiliateEarnPageState();
}

class _AffiliateEarnPageState extends State<AffiliateEarnPage> with SingleTickerProviderStateMixin {
  late final TextEditingController _referredByController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AffiliateProvider>();
    _referredByController = TextEditingController(text: provider.savedReferredByCode);
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SystemConfigProvider>().fetchConfig();
    });
  }

  @override
  void dispose() {
    _referredByController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showWithdrawDialog() {
    final provider = context.read<AffiliateProvider>();
    if (provider.availableBalance < 200000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cần tối thiểu 200.000đ số dư khả dụng để rút tiền. Hiện tại bạn có: ${CurrencyFormatter.formatVND(provider.availableBalance)} đ.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final supportedBanks = [
      'MBBank (Quân Đội)',
      'Vietcombank',
      'Techcombank',
      'BIDV',
      'VietinBank',
      'Agribank',
      'VPBank',
      'ACB (Á Châu)',
      'TPBank',
      'Sacombank',
      'OCB (Phương Đông)',
      'VIB (Quốc Tế)',
      'MSB (Hàng Hải)',
      'HDBank',
      'SeABank',
      'Ngân hàng khác...',
    ];

    String selectedBank = supportedBanks[0];
    final customBankCtrl = TextEditingController();
    final accNumCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Rút hoa hồng tiếp thị AutoBank');
    final amountCtrl = TextEditingController(text: provider.availableBalance.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Yêu Cầu Rút Tiền Hoa Hồng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Khối số dư
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Khả dụng: ${CurrencyFormatter.formatVND(provider.availableBalance)} đ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Số tiền rút
                    const Text('1. Số tiền rút (Tối thiểu 200.000đ):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        suffixText: 'VND',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chip chọn nhanh tiền
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildQuickAmountChip('200k', 200000, amountCtrl, provider.availableBalance),
                        _buildQuickAmountChip('500k', 500000, amountCtrl, provider.availableBalance),
                        _buildQuickAmountChip('1 Triệu', 1000000, amountCtrl, provider.availableBalance),
                        _buildQuickAmountChip('Tất cả', provider.availableBalance.toInt(), amountCtrl, provider.availableBalance),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2. Ngân hàng nhận tiền
                    const Text('2. Ngân hàng nhận tiền:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBank,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: supportedBanks.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text(b, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedBank = val;
                          });
                        }
                      },
                    ),
                    if (selectedBank == 'Ngân hàng khác...') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customBankCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nhập tên ngân hàng của bạn...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 3. Số tài khoản ngân hàng
                    const Text('3. Số tài khoản ngân hàng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: accNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Nhập chính xác số tài khoản...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Họ và tên chủ tài khoản
                    const Text('4. Tên người nhận (In hoa không dấu):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (val) {
                        final upper = val.toUpperCase();
                        if (upper != val) {
                          nameCtrl.value = nameCtrl.value.copyWith(
                            text: upper,
                            selection: TextSelection.collapsed(offset: upper.length),
                          );
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'VD: NGUYEN VAN A',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Ghi chú chuyển tiền
                    const Text('5. Nội dung / Ghi chú rút tiền:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú cho ban quản trị...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  final bankFinal = selectedBank == 'Ngân hàng khác...'
                      ? customBankCtrl.text.trim()
                      : selectedBank;
                  final acc = accNumCtrl.text.trim();
                  final name = nameCtrl.text.trim();

                  if (amt < 200000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Số tiền rút tối thiểu là 200.000 VNĐ!')),
                    );
                    return;
                  }
                  if (amt > provider.availableBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Số tiền rút vượt quá số dư khả dụng hiện có!')),
                    );
                    return;
                  }
                  if (bankFinal.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn hoặc nhập tên ngân hàng nhận!')),
                    );
                    return;
                  }
                  if (acc.isEmpty || acc.length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đúng số tài khoản ngân hàng!')),
                    );
                    return;
                  }
                  if (name.isEmpty || !name.contains(' ')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ Họ và Tên chủ tài khoản!')),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final res = await provider.requestWithdrawal(
                    bankName: bankFinal,
                    accountNumber: acc,
                    accountHolder: name,
                    amount: amt,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Yêu cầu rút tiền thành công!'),
                        backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Gửi Yêu Cầu Rút'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, int value, TextEditingController controller, double maxBal) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFCBD5E1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        final target = value > maxBal.toInt() ? maxBal.toInt() : value;
        controller.text = target.toString();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final affiliate = context.watch<AffiliateProvider>();
    final sysConfig = context.watch<SystemConfigProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kiếm tiền cùng ứng dụng',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Video hướng dẫn kiếm tiền & rút hoa hồng',
            icon: const Icon(Icons.smart_display_rounded, color: Color(0xFFEF4444)),
            onPressed: () {
              AppVideoGuideModal.showDirect(
                context,
                title: 'Hướng Dẫn Tiếp Thị & Rút Tiền',
                subtitle: 'Cách lấy mã giới thiệu, chia sẻ cho bạn bè và rút tiền hoa hồng về ngân hàng',
                videoUrl: sysConfig.videoGuideAffiliate,
                badgeText: 'Giới Thiệu Bạn Bè',
                dismissButtonText: 'Đóng',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ==========================================
          // 1. TOP WALLET BANNER (Xanh Navy Gradient)
          // ==========================================
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C4A6E), Color(0xFF0369A1), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x260369A1),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      value: '${CurrencyFormatter.formatVND(affiliate.availableBalance)}đ',
                      label: 'Khả dụng',
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _buildStatCol(
                      value: '${CurrencyFormatter.formatVND(affiliate.pendingBalance)}đ',
                      label: 'Chờ duyệt',
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _buildStatCol(
                      value: '${affiliate.invitedCount}',
                      label: 'Đã mời',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white38),
                      ),
                    ),
                    onPressed: _showWithdrawDialog,
                    child: const Text(
                      'Rút tiền',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cần tối thiểu 200.000đ số dư khả dụng để rút tiền. Hiện tại: ${CurrencyFormatter.formatVND(affiliate.availableBalance)}đ.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // 2. NHẬP MÃ GIỚI THIỆU
          // ==========================================
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập mã giới thiệu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhập mã 6 số của người giới thiệu bạn. Mã được lưu và tự áp dụng khi bạn chọn gói và thanh toán thành công — người giới thiệu nhận hoa hồng.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded, color: Color(0xFF0284C7), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _referredByController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
                            decoration: const InputDecoration(
                              hintText: 'Nhập mã 6 số',
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (affiliate.savedReferredByCode.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Mã đang lưu: ${affiliate.savedReferredByCode}',
                          style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await affiliate.saveReferredByCode(_referredByController.text.trim());
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Đã lưu mã giới thiệu thành công!' : 'Mã không hợp lệ hoặc trùng với mã của bạn!'),
                              backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Lưu mã giới thiệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // 3. MÃ GIỚI THIỆU CỦA BẠN
          // ==========================================
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mã giới thiệu của bạn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: affiliate.myReferralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép mã giới thiệu vào bộ nhớ đệm!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            affiliate.myReferralCode.split('').join('  '),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0369A1),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.copy_rounded, color: Color(0xFF0284C7), size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Chia sẻ mã', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final shareText = 'Tải ứng dụng Đọc Thông Báo Nhận Tiền AutoBank tại https://docthongbaobank.com và nhập mã giới thiệu của mình: ${affiliate.myReferralCode} để nhận thêm 7 ngày VIP miễn phí nhé!';
                        Clipboard.setData(ClipboardData(text: shareText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép tin nhắn mời! Hãy dán vào Zalo/Facebook để gửi bạn bè.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // 4. BẢNG THƯỞNG & HOA HỒNG
          // ==========================================
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bảng thưởng & hoa hồng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hoa hồng khi người được giới thiệu thanh toán gói thành công',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  ...sysConfig.affiliateRewards.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isLast = idx == sysConfig.affiliateRewards.length - 1;
                    final rewardVal = (item['reward'] as num?)?.toDouble() ?? 0.0;
                    return Column(
                      children: [
                        _buildCommissionRow(
                          item['name']?.toString() ?? 'Gói bản quyền',
                          CurrencyFormatter.formatVND(rewardVal),
                        ),
                        if (!isLast) const Divider(height: 18, color: Color(0xFFF1F5F9)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // 5. TABS: LỊCH SỬ THU NHẬP & RÚT TIỀN
          // ==========================================
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF0284C7),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF0284C7),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Lịch sử thu nhập'),
                    Tab(text: 'Lệnh rút tiền'),
                  ],
                ),
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Thu nhập
                      affiliate.incomeHistory.isEmpty
                          ? const Center(
                              child: Text(
                                'Chưa có hoa hồng giới thiệu nào',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: affiliate.incomeHistory.length,
                              separatorBuilder: (_, index) => const Divider(height: 12),
                              itemBuilder: (ctx, i) {
                                final item = affiliate.incomeHistory[i];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text(item.date, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                      ],
                                    ),
                                    Text(
                                      '+${CurrencyFormatter.formatVND(item.amount)}đ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 14),
                                    ),
                                  ],
                                );
                              },
                            ),

                      // Tab 2: Rút tiền
                      affiliate.withdrawalHistory.isEmpty
                          ? const Center(
                              child: Text(
                                'Chưa có yêu cầu rút tiền nào',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: affiliate.withdrawalHistory.length,
                              separatorBuilder: (_, index) => const Divider(height: 12),
                              itemBuilder: (ctx, i) {
                                final item = affiliate.withdrawalHistory[i];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${item.bankName} · ${item.accountNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text('${item.date} · ${item.status}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                      ],
                                    ),
                                    Text(
                                      '-${CurrencyFormatter.formatVND(item.amount)}đ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 14),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCommissionRow(String package, String reward) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(package, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155))),
          Text(reward, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A))),
        ],
      ),
    );
  }
}

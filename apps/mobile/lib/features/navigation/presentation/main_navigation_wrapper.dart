import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../notification_listener/presentation/notification_service.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../analytics/presentation/pages/analytics_page.dart';
import '../../auth/presentation/providers/google_auth_provider.dart';
import '../../home/presentation/pages/home_app_page.dart';
import '../../notification_center/domain/models/app_notification_item.dart';
import '../../notification_center/presentation/providers/app_notification_provider.dart';
import '../../notification_center/presentation/widgets/floating_notification_banner.dart';
import '../../notification_center/presentation/widgets/notification_center_sheet.dart';
import '../../settings/presentation/pages/settings_guide_page.dart';
import '../../system/presentation/providers/system_config_provider.dart';
import '../../subscription/presentation/pages/register_subscription_page.dart';
import '../../transactions/domain/entities/normalized_transaction.dart';
import '../../transactions/presentation/providers/transaction_provider.dart';
import '../../voice_settings/presentation/pages/voice_settings_page.dart';
import '../../voice_settings/presentation/providers/voice_settings_provider.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _strobeController;
  late Animation<double> _strobeAnimation;
  VoidCallback? _syncAccountListener;
  GoogleAuthProvider? _googleAuth;

  @override
  void initState() {
    super.initState();
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);

    _strobeAnimation = Tween<double>(begin: 0.15, end: 0.95).animate(
      CurvedAnimation(parent: _strobeController, curve: Curves.easeInOut),
    );

    // Lắng nghe biến động số dư và đẩy thông báo vào Notification Center
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final txProvider = context.read<TransactionProvider>();
      final notifProvider = context.read<AppNotificationProvider>();
      final googleAuth = context.read<GoogleAuthProvider>();
      final sysConfig = context.read<SystemConfigProvider>();

      final voiceProvider = context.read<VoiceSettingsProvider>();

      void syncAccountContext() {
        sysConfig.updateAccountContext(
          email: googleAuth.isSignedIn ? googleAuth.email : null,
          activePackage: googleAuth.isSignedIn ? googleAuth.activePackageName : null,
        );
        txProvider.updatePlanStatus(
          isActive: googleAuth.isActivated && !googleAuth.isExpired,
        );
        if (googleAuth.isSignedIn && googleAuth.email.isNotEmpty) {
          voiceProvider.loadConfigFromBackend(googleAuth.email);
          txProvider.syncAccountTransactions(googleAuth.email);
        } else if (!googleAuth.isSignedIn) {
          txProvider.clearOnLogout();
        }
      }
      _googleAuth = googleAuth;
      _syncAccountListener = syncAccountContext;
      syncAccountContext();
      googleAuth.addListener(syncAccountContext);

      txProvider.onTransactionReceived = (tx) {
        final isCredit = tx.type.isCredit;
        final amountFormatted = CurrencyFormatter.formatVND(tx.amount);
        notifProvider.postNotification(
          title: isCredit ? '🔔 +$amountFormatted đ (${tx.bankCode})' : '⚡ -$amountFormatted đ (${tx.bankCode})',
          message: isCredit
              ? 'Đã nhận biến động số dư tiền về từ ${tx.bankCode}: +$amountFormatted đ.'
              : 'Phát hiện biến động trừ tiền/chi tiêu từ ${tx.bankCode}: -$amountFormatted đ.',
          category: NotificationCategory.transaction,
          showAndroidStatusNotification: true,
        );
      };

      googleAuth.onNotificationEvent = (title, message, type) {
        NotificationCategory cat = NotificationCategory.system;
        if (type == 'auth') cat = NotificationCategory.auth;
        if (type == 'promo') cat = NotificationCategory.promo;
        if (type == 'background') cat = NotificationCategory.background;
        notifProvider.postNotification(
          title: title,
          message: message,
          category: cat,
          showAndroidStatusNotification: false,
        );
      };
    });
  }

  @override
  void dispose() {
    if (_syncAccountListener != null && _googleAuth != null) {
      _googleAuth!.removeListener(_syncAccountListener!);
    }
    _strobeController.dispose();
    super.dispose();
  }

  void _navigateToIndex(int index) {
    if (_currentIndex == index) return;
    final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
    final isPlanExpired = googleAuth.isExpired || !googleAuth.isActivated;

    // Yêu cầu: Khi hết hạn gói, tùy chỉnh câu đọc phải yêu cầu đăng ký gói
    if (index == 1 && isPlanExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Gói cước đã hết hạn! Vui lòng đăng ký gói bản quyền để tùy chỉnh mẫu câu đọc.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _currentIndex = 2;
      });
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final activeAlert = txProvider.activeAlertTransaction;
    final isStrobe = txProvider.isLightStrobeActive;

    final pages = [
      HomeAppPage(
        onNavigateToVoiceSettings: () => _navigateToIndex(1),
        onNavigateToRegister: () => _navigateToIndex(2),
        onNavigateToGuide: () => _navigateToIndex(4),
      ),
      VoiceSettingsPage(
        onNavigateToRegister: () => _navigateToIndex(2),
      ),
      const RegisterSubscriptionPage(),
      const AnalyticsPage(),
      const SettingsGuidePage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),

          // 1. HIỆU ỨNG SÁNG ĐÈN CHỚP VIỀN TÍN HIỆU QUẦY THU NGÂN (STROBE LIGHT FLASH)
          if (isStrobe || activeAlert != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _strobeAnimation,
                  builder: (ctx, child) {
                    final alpha = _strobeAnimation.value;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: alpha),
                          width: 8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: alpha * 0.45),
                            blurRadius: 28,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // 2. MÀN HÌNH THÔNG BÁO TOÀN MÀN HÌNH (FULL-SCREEN TRANSACTION ALERT)
          if (activeAlert != null)
            _buildFullScreenTransactionAlert(context, activeAlert, txProvider),

          // 3. THÔNG BÁO ỨNG DỤNG NỔI (FLOATING IN-APP BANNER)
          if (!txProvider.isDimmedScreenActive)
            FloatingNotificationBanner(
              onTap: () => NotificationCenterSheet.show(context),
            ),

          // 4. MÀN HÌNH SIÊU TỐI MỜ CHẠY NGẦM TIẾT KIỆM PIN (ULTRA-DIMMED OLED STEALTH SCREEN)
          if (txProvider.isDimmedScreenActive)
            _buildUltraDimmedStealthScreen(context, txProvider),
        ],
      ),
      bottomNavigationBar: txProvider.isDimmedScreenActive
          ? null
          : Container(
              clipBehavior: Clip.none,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TRANG CHỦ (Chia đều 20%)
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Trang chủ',
                  ),
                ),

                // 2. CÂU THÔNG BÁO (Chia đều 20%)
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.campaign_rounded,
                    label: 'Câu đọc',
                  ),
                ),

                // 3. ĐĂNG KÝ (Nổi bật trung tâm - Chia đều 20%)
                Expanded(
                  child: _buildCenterRegisterNavItem(),
                ),

                // 4. BÁO CÁO (Chia đều 20%)
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.bar_chart_rounded,
                    label: 'Báo cáo',
                  ),
                ),

                // 5. CÀI ĐẶT (Chia đều 20%)
                Expanded(
                  child: _buildNavItem(
                    index: 4,
                    icon: Icons.settings_rounded,
                    label: 'Cài đặt',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// NÚT ĐĂNG KÝ TRUNG TÂM (CĂN CHÍNH GIỮA 20%, ICON KIM CƯƠNG VIP CHUYÊN NGHIỆP)
  Widget _buildCenterRegisterNavItem() {
    final isSelected = _currentIndex == 2;

    return GestureDetector(
      onTap: () => _navigateToIndex(2),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Nút tròn nổi lên trên thanh điều hướng
          Positioned(
            top: -14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? const [Color(0xFF0284C7), Color(0xFF0F172A)]
                          : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: isSelected ? 0.45 : 0.3),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.diamond_rounded, // Icon Kim Cương Pro sang trọng, chuẩn FinTech / Subscription
                      color: Colors.white,
                      size: isSelected ? 26 : 24,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Đăng ký',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _navigateToIndex(index),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MÀN HÌNH THÔNG BÁO TOÀN MÀN HÌNH KHI CÓ BIẾN ĐỘNG SỐ DƯ (ĐỌC TIỀN, CHỌN LOẠI TIÊU DÙNG & NÚT DỪNG ĐỌC)
  Widget _buildFullScreenTransactionAlert(
    BuildContext context,
    NormalizedTransaction tx,
    TransactionProvider txProvider,
  ) {
    final isCredit = tx.type.isCredit;
    final time = tx.transactionTime;
    final categories = txProvider.expenseCategories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: isDark ? 0.92 : 0.85),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark ? Border.all(color: const Color(0xFF334155), width: 1.2) : null,
                    boxShadow: [
                      BoxShadow(
                        color: (isCredit ? const Color(0xFF10B981) : const Color(0xFFE11D48)).withValues(alpha: 0.4),
                        blurRadius: 36,
                        spreadRadius: 6,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Icon vòng tròn phát sáng
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isCredit ? const Color(0xFF064E3B) : const Color(0xFF881337))
                              : (isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.notifications_active_rounded : Icons.payments_rounded,
                          size: 40,
                          color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFF43F5E),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Dòng trạng thái tiêu đề
                      Text(
                        isCredit ? '🔔 ĐÃ NHẬN TIỀN VỀ TÀI KHOẢN!' : '⚡ BIẾN ĐỘNG SỐ DƯ (CHI TIÊU)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFF43F5E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngân hàng ${tx.bankCode}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Khung số tiền cực lớn
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isCredit ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFF881337).withValues(alpha: 0.3))
                              : (isCredit ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? (isCredit ? const Color(0xFF059669) : const Color(0xFFBE123C))
                                : (isCredit ? const Color(0xFFBBF7D0) : const Color(0xFFFECDD3)),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${isCredit ? '+' : '-'}${CurrencyFormatter.formatVND(tx.amount)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFF43F5E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} • ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. CHỌN NHANH LOẠI TIÊU DÙNG / QUỸ CHI TIÊU
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.category_rounded, size: 16, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 6),
                                Text(
                                  'Bấm chọn loại chi tiêu / Quỹ quản lý:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: categories.map((cat) {
                                final isSelected = tx.category == cat;
                                return ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0284C7),
                                  backgroundColor: isDark ? const Color(0xFF0F172A) : null,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                  ),
                                  onSelected: (_) {
                                    txProvider.updateAlertCategory(cat);
                                  },
                                );
                              }).toList(),
                            ),
                            if (tx.category != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Đã phân loại vào: "${tx.category}"',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. NÚT ĐÓNG (KHI BẤM SẼ DỪNG ĐỌC THÔNG BÁO VÀ THÔI)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.volume_off_rounded, color: Colors.white, size: 22),
                          label: const Text(
                            'ĐÓNG',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          onPressed: () {
                            txProvider.dismissAlertAndStopTts();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// MÀN HÌNH SIÊU TỐI MỜ CHẠY NGẦM TIẾT KIỆM PIN (ULTRA-DIMMED OLED STEALTH SCREEN)
  /// Phủ 100% toàn màn hình màu đen OLED #000000, ẩn hoàn toàn bottom navigation,
  /// các chi tiết chỉ hiện mờ tối tuyệt đối để chống chói và tiết kiệm pin tối đa.
  Widget _buildUltraDimmedStealthScreen(
    BuildContext context,
    TransactionProvider txProvider,
  ) {
    void exitDimmed() {
      txProvider.setDimmedScreenActive(false);
      NotificationService.setScreenBrightness(-1.0);
      TtsService().speakTestFeedback('Đã thoát chế độ làm mờ màn hình.');
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: exitDimmed,
        child: Container(
          color: const Color(0xFF000000), // Đen OLED tuyệt đối 100%
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Header siêu mờ tối
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TRỰC NGẦM 24/24',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: const Color(0xFF475569).withValues(alpha: 0.35),
                        size: 20,
                      ),
                      onPressed: exitDimmed,
                    ),
                  ],
                ),

                // 2. Trung tâm: Biểu tượng & Đồng hồ mờ cực thấp
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF070B14),
                        border: Border.all(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.nights_stay_rounded,
                        size: 42,
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        final now = DateTime.now();
                        final timeStr =
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
                        return Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 2,
                            color: const Color(0xFF64748B).withValues(alpha: 0.35),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Màn hình đang ở chế độ làm mờ tối đa tiết kiệm pin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF475569).withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 13,
                            color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hôm nay: +${CurrencyFormatter.formatVND(txProvider.todayTotal.toDouble())} (${txProvider.todayCount} đơn)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B).withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 3. Dưới cùng: Nút chạm mở sáng mờ
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.35),
                        ),
                        color: const Color(0xFF050505),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 15,
                            color: const Color(0xFF475569).withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chạm vào màn hình để mở sáng',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF64748B).withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loa vẫn phát 100% âm lượng khi có thông báo nhận hoặc trừ tiền từ ngân hàng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: const Color(0xFF334155).withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

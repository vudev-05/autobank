import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../notification_listener/presentation/notification_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/security/app_pin_security_service.dart';
import '../../../../core/security/app_pin_dialog.dart';
import '../../../../core/security/app_lock_screen_overlay.dart';
import '../../../../core/widgets/app_permission_dialog.dart';
import '../../../../core/widgets/app_in_app_rating_dialog.dart';
import '../../../../core/widgets/app_video_guide_modal.dart';
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

class _MainNavigationWrapperState extends State<MainNavigationWrapper> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const MethodChannel _deepLinkChannel = MethodChannel('vn.autobank.mobile/deeplink');
  int _currentIndex = 0;
  String? _subscriptionInitialPackage;
  late AnimationController _strobeController;
  late Animation<double> _strobeAnimation;
  VoidCallback? _syncAccountListener;
  GoogleAuthProvider? _googleAuth;
  Timer? _inactivityTimer;
  Timer? _alertAutoDismissTimer;

  void _resetInactivityTimer() {
    if (!mounted) return;
    try {
      final txProvider = context.read<TransactionProvider>();
      if (txProvider.isDimmedScreenActive) {
        txProvider.setDimmedScreenActive(false);
        NotificationService.setScreenBrightness(-1.0);
      }
      _inactivityTimer?.cancel();
      // Trang chủ hoạt động bình thường, không làm mờ/tối màn hình
      // Chỉ khi vào Quầy Thu Ngân hoặc Chạy ngầm mới kích hoạt chế độ tiết kiệm pin
    } catch (_) {}
  }

  void _initDeepLinkHandling() {
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final rawUri = call.arguments as String?;
        if (rawUri != null && rawUri.isNotEmpty) {
          _processDeepLinkUri(rawUri);
        }
      }
    });

    _deepLinkChannel.invokeMethod<String>('getInitialDeepLink').then((rawUri) {
      if (rawUri != null && rawUri.isNotEmpty) {
        _processDeepLinkUri(rawUri);
      }
    }).catchError((_) {});
  }

  void _processDeepLinkUri(String rawUri) {
    try {
      final uri = Uri.tryParse(rawUri);
      if (uri == null) return;

      // Hỗ trợ autobank://register?package=1y hoặc autobank://subscribe?plan=1month
      final pkgParam = uri.queryParameters['package'] ?? 
                       uri.queryParameters['plan'] ?? 
                       uri.queryParameters['pkg'] ??
                       (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null);

      if (pkgParam != null && pkgParam.isNotEmpty) {
        String normalized = pkgParam.trim().toLowerCase();
        if (normalized == '1month' || normalized == '1thang') normalized = '1m';
        if (normalized == '3month' || normalized == '3thang') normalized = '3m';
        if (normalized == '6month' || normalized == '6thang') normalized = '6m';
        if (normalized == '9month' || normalized == '9thang') normalized = '9m';
        if (normalized == '1year' || normalized == '1nam') normalized = '1y';
        if (normalized == '2year' || normalized == '2nam') normalized = '2y';

        setState(() {
          _subscriptionInitialPackage = normalized;
          _currentIndex = 2; // Tự động mở ngay màn hình đăng ký gói
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Đã chọn gói từ website! Nhập mã NGUOIMOI để giảm ngay 10%.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0284C7),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Luôn giữ màn hình sáng 24/24, không cho phép tắt màn hình khi app đang mở
    NotificationService.setKeepScreenOn(true);
    _resetInactivityTimer();
    _initDeepLinkHandling();

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
        // Chỉ đọc tiếng qua loa TTS và hiện toàn màn hình, không bắn thêm thông báo lên khay hệ thống
        final isCredit = tx.type.isCredit;
        final amountFormatted = CurrencyFormatter.formatVND(tx.amount);
        notifProvider.postNotification(
          title: isCredit ? '🔔 +$amountFormatted đ · ${tx.bankCode}' : '⚡ -$amountFormatted đ · ${tx.bankCode}',
          message: isCredit
              ? 'Đã nhận biến động số dư tiền về từ ${tx.bankCode}: +$amountFormatted đ.'
              : 'Phát hiện biến động trừ tiền/chi tiêu từ ${tx.bankCode}: -$amountFormatted đ.',
          category: NotificationCategory.transaction,
          showAndroidStatusNotification: false,
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

      _initAppFlow();
    });
  }

  /// Bắt đầu chuỗi kiểm tra quyền, tín hiệu và video hướng dẫn sau khi app đã được mở khóa hợp lệ
  Future<void> _initAppFlow() async {
    if (!mounted) return;

    // Nếu đang trong màn hình khóa PIN, dừng lại không mở bất kỳ popup nào đè lên
    final pinService = AppPinSecurityService();
    if (pinService.isPinEnabled && pinService.isSessionExpired()) {
      return;
    }

    final notifProvider = Provider.of<AppNotificationProvider>(context, listen: false);

    // 1. Kiểm tra cấp quyền ứng dụng
    await AppPermissionDialog.showIfNeeded(context);
    if (!mounted) return;

    // 2. Thông báo báo hiệu tín hiệu hoạt động tốt khi bật app
    notifProvider.postNotification(
      title: '🟢 Tín hiệu AutoBank hoạt động tốt',
      message: 'Hệ thống đã sẵn sàng lắng nghe thông báo ngân hàng và đọc tiền tự động 24/7.',
      category: NotificationCategory.system,
      showAndroidStatusNotification: false,
    );

    // 3. Hướng dẫn sử dụng hệ thống cho người mới (hiển thị popup thông báo + Video YouTube trong app + nút Đóng)
    if (mounted) {
      final sysConfig = context.read<SystemConfigProvider>();
      await AppVideoGuideModal.showIfNeeded(
        context,
        prefKey: 'has_seen_guide_newbie_v2',
        title: 'Hướng Dẫn Sử Dụng AutoBank',
        subtitle: 'Video ngắn hướng dẫn thiết lập hệ thống phát loa và chạy ngầm mượt mà 24/7',
        videoUrl: sysConfig.videoGuideNewbie,
        badgeText: 'Dành Cho Người Mới',
        showNeverShowAgainCheckbox: true,
        dismissButtonText: 'Đóng',
      );
    }

    if (!mounted) return;

    // 4. Kiểm tra đánh giá trên Google Play cho gói dùng thử
    await AppInAppRatingDialog.checkAndShowRating(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final pinService = AppPinSecurityService();
      if (pinService.isPinEnabled && pinService.isSessionExpired() && mounted) {
        AppPinSecurityDialogs.showUnlockPinDialog(context);
      }

      // Khi thoát app ra lâu vào lại: luôn giữ hiển thị ở Trang chủ
      if (mounted) {
        setState(() {
          _currentIndex = 0;
        });
        NotificationService.setKeepScreenOn(true);
        _resetInactivityTimer();
      }
    }
  }

  @override
  void dispose() {
    _alertAutoDismissTimer?.cancel();
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
      _resetInactivityTimer();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    _resetInactivityTimer();

    // 1. Khi người dùng vào trang CÂU ĐỌC: Hiện thông báo hướng dẫn tối ưu & cá nhân hóa câu đọc
    if (index == 1) {
      final sysConfig = Provider.of<SystemConfigProvider>(context, listen: false);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || _currentIndex != 1) return;
        AppVideoGuideModal.showIfNeeded(
          context,
          prefKey: 'has_seen_guide_voice_page',
          title: 'Hướng Dẫn Tối Ưu & Cá Nhân Hóa Câu Đọc',
          subtitle: 'Cách thiết lập thứ tự đọc, gắn tên cửa hàng, rút gọn số tiền và lời cảm ơn riêng',
          videoUrl: sysConfig.videoGuideVoice,
          badgeText: 'Tối Ưu & Cá Nhân Hóa',
          showNeverShowAgainCheckbox: true,
          dismissButtonText: 'Đóng',
        );
      });
    }

    // 2. Khi người dùng vào trang ĐỌC LẠI / BÁO CÁO: Hiện thông báo hướng dẫn sử dụng trang đọc lại
    if (index == 3) {
      final sysConfig = Provider.of<SystemConfigProvider>(context, listen: false);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || _currentIndex != 3) return;
        AppVideoGuideModal.showIfNeeded(
          context,
          prefKey: 'has_seen_guide_history_page',
          title: 'Hướng Dẫn Sử Dụng Trang Đọc Lại',
          subtitle: 'Cách tra cứu, nghe lại thông báo nhận tiền và quản lý dòng tiền chi tiết',
          videoUrl: sysConfig.videoGuideHistory,
          badgeText: 'Trang Đọc Lại',
          showNeverShowAgainCheckbox: true,
          dismissButtonText: 'Đóng',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. LỚP BẢO MẬT TUYỆT ĐỐI CẤP ROOT: Nếu người dùng đã kích hoạt mã PIN và phiên bảo mật hết hạn/khởi động lại
    // Hiển thị trực tiếp AppLockScreenOverlay, chặn 100% việc dựng hay lộ bất kỳ giao diện nào bên trong app!
    final pinService = context.watch<AppPinSecurityService>();
    if (pinService.isPinEnabled && pinService.isSessionExpired()) {
      return AppLockScreenOverlay(
        onUnlocked: () {
          // Khi mở khóa thành công, kích hoạt chuỗi kiểm tra quyền và hướng dẫn
          Future.microtask(() => _initAppFlow());
        },
      );
    }

    final txProvider = context.watch<TransactionProvider>();
    final activeAlert = txProvider.activeAlertTransaction;
    final isStrobe = txProvider.isLightStrobeActive;
    final alertDuration = txProvider.alertDisplayDurationSeconds;

    if (activeAlert != null) {
      _alertAutoDismissTimer ??= Timer(Duration(seconds: alertDuration), () {
        if (mounted) {
          txProvider.dismissTransactionAlert();
          _alertAutoDismissTimer = null;
        }
      });
    } else {
      _alertAutoDismissTimer?.cancel();
      _alertAutoDismissTimer = null;
    }

    final pages = [
      HomeAppPage(
        onNavigateToVoiceSettings: () => _navigateToIndex(1),
        onNavigateToRegister: () => _navigateToIndex(2),
        onNavigateToGuide: () => _navigateToIndex(4),
      ),
      VoiceSettingsPage(
        onNavigateToRegister: () => _navigateToIndex(2),
      ),
      RegisterSubscriptionPage(
        key: ValueKey(_subscriptionInitialPackage ?? 'default_sub'),
        initialPackageKey: _subscriptionInitialPackage,
        onBackToHome: () => _navigateToIndex(0),
      ),
      const AnalyticsPage(),
      const SettingsGuidePage(),
    ];

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      child: Scaffold(
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

          // 4. LÀM TỐI MÀN HÌNH SAU 30S TẠI TRANG CHỦ (GIỮ NGUYÊN GIAO DIỆN TRANG CHỦ, KHÔNG HIỆN CHẠY NGẦM)
          if (txProvider.isDimmedScreenActive && _currentIndex == 0)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _resetInactivityTimer,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
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
          minimum: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
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
              size: 22,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
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

                      // 4. CHỌN NHANH QUỸ: DOANH NGHIỆP VS CÁ NHÂN
                      Builder(
                        builder: (context) {
                          final existingCat = tx.category ?? '';
                          String selectedScope;
                          if (existingCat.startsWith('[Cá Nhân]')) {
                            selectedScope = 'Cá Nhân';
                          } else if (existingCat.startsWith('[Doanh Nghiệp]')) {
                            selectedScope = 'Doanh Nghiệp';
                          } else {
                            // Tiền nhận (+) -> Mở sẵn Doanh Nghiệp, Tiền trừ (-) -> Mở sẵn Cá Nhân
                            selectedScope = isCredit ? 'Doanh Nghiệp' : 'Cá Nhân';
                          }

                          return StatefulBuilder(
                            builder: (context, setBlockState) {
                              final bizCats = txProvider.businessBudgets.keys.toList();
                              final personalCats = txProvider.personalBudgets.keys.toList();
                              final activeList = selectedScope == 'Doanh Nghiệp' ? bizCats : personalCats;

                              return Container(
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
                                    // Tab chuyển đổi Quỹ Doanh Nghiệp vs Cá Nhân
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => setBlockState(() => selectedScope = 'Doanh Nghiệp'),
                                            borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: selectedScope == 'Doanh Nghiệp'
                                                ? const Color(0xFF0284C7)
                                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.business_center_rounded, size: 14, color: selectedScope == 'Doanh Nghiệp' ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                                              const SizedBox(width: 4),
                                              Text(
                                                '🏢 Doanh Nghiệp (${bizCats.length})',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: selectedScope == 'Doanh Nghiệp' ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setBlockState(() => selectedScope = 'Cá Nhân'),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: selectedScope == 'Cá Nhân'
                                                ? const Color(0xFFE11D48)
                                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person_rounded, size: 14, color: selectedScope == 'Cá Nhân' ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                                              const SizedBox(width: 4),
                                              Text(
                                                '👤 Cá Nhân (${personalCats.length})',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: selectedScope == 'Cá Nhân' ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Danh sách chip quỹ
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: activeList.map((cat) {
                                    final fullCat = '[$selectedScope] $cat';
                                    final isSelected = (tx.category == fullCat) || (tx.category == cat);
                                    return ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      selectedColor: selectedScope == 'Doanh Nghiệp' ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                                      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                      ),
                                      onSelected: (_) {
                                        txProvider.updateAlertCategory(fullCat);
                                        setBlockState(() {});
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
                          );
                        },
                      );
                    },
                  ),
                      const SizedBox(height: 14),

                      // CẤU HÌNH THỜI GIAN ĐÓNG THÔNG BÁO (Mặc định 10s)
                      StatefulBuilder(
                        builder: (context, setTimerState) {
                          final alertDuration = txProvider.alertDisplayDurationSeconds;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, color: Color(0xFF0284C7), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tự đóng sau ${alertDuration}s:',
                                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 4,
                                children: [5, 10, 15, 30].map((sec) {
                                  final isCur = alertDuration == sec;
                                  return InkWell(
                                    onTap: () {
                                      txProvider.setAlertDisplayDuration(sec);
                                      _alertAutoDismissTimer?.cancel();
                                      _alertAutoDismissTimer = Timer(Duration(seconds: sec), () {
                                        if (mounted) {
                                          txProvider.dismissTransactionAlert();
                                          _alertAutoDismissTimer = null;
                                        }
                                      });
                                      setTimerState(() {});
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCur ? const Color(0xFF0284C7) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${sec}s',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: isCur ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // 5. NÚT ĐÓNG (KHI BẤM SẼ DỪNG ĐỌC THÔNG BÁO VÀ THÔI)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'XÁC NHẬN & ĐÓNG',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          onPressed: () {
                            _alertAutoDismissTimer?.cancel();
                            _alertAutoDismissTimer = null;
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
}

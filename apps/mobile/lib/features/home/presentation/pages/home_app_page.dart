import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../../../transactions/domain/entities/normalized_transaction.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../notification_center/presentation/providers/app_notification_provider.dart';
import '../../../notification_center/presentation/widgets/notification_center_sheet.dart';
import '../../../auth/presentation/providers/google_auth_provider.dart';
import '../../../pos/presentation/pages/pos_smart_cashier_page.dart';
import '../../../affiliate/presentation/pages/affiliate_earn_page.dart';

class HomeAppPage extends StatefulWidget {
  final VoidCallback? onNavigateToVoiceSettings;
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onNavigateToGuide;

  const HomeAppPage({
    super.key,
    this.onNavigateToVoiceSettings,
    this.onNavigateToRegister,
    this.onNavigateToGuide,
  });

  @override
  State<HomeAppPage> createState() => _HomeAppPageState();
}

class _HomeAppPageState extends State<HomeAppPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isSpeakerActive = false;
  bool _showTransactions = true;
  bool _isBatteryIgnored = true;
  String _sharePin = ''; // Mã 6 số bảo mật riêng biệt của mỗi người dùng (không ai trùng nhau)
  bool _hasConfiguredSharePin = false; // Phải thiết lập trong lần đầu chia sẻ

  // Cài đặt quyền & chức năng cho liên kết chia sẻ (Live Share)
  bool _shareCredit = true;       // Chia sẻ thông báo Tiền Vào (Đã nhận)
  bool _shareDebit = true;        // Chia sẻ thông báo Tiền Ra (Chuyển đi)
  bool _shareSpeech = true;       // Bật loa 24/7 trên link chia sẻ
  bool _shareShowAmount = true;   // Hiển thị số tiền giao dịch
  bool _shareShowContent = true;  // Hiển thị nội dung giao dịch
  bool _shareRepeatTwice = false; // Đọc nhắc lại x2 lần
  Timer? _promoCountdownTimer; // Đếm ngược thời gian thực cho banner mã giảm giá tân thủ 3 ngày

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().checkPermission();
        _checkBatteryOptimization();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Đồng hồ đếm ngược từng giây cho banner ưu đãi thành viên mới
    _promoCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Tải cấu hình mã PIN bảo mật 6 số từ bộ nhớ máy & đồng bộ lên backend
    _loadSharePinSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _promoCountdownTimer?.cancel();
    _pulseController.dispose();
    _particleController.dispose();
    NotificationService.setScreenBrightness(-1.0);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<TransactionProvider>().checkPermission();
      _checkBatteryOptimization();
    }
  }

  Future<void> _checkBatteryOptimization() async {
    if (kIsWeb) return;
    try {
      final ignored = await NotificationService.isBatteryOptimizationIgnored();
      if (mounted) {
        setState(() {
          _isBatteryIgnored = ignored;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSharePinSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasConfigured = prefs.getBool('has_configured_share_pin') ?? false;
      final savedPin = prefs.getString('share_pin_code') ?? prefs.getString('autobank_live_web_pin_code');
      String effectivePin = '';
      if (savedPin != null && savedPin.length == 6 && savedPin != '889922') {
        effectivePin = savedPin;
      } else {
        // Sinh mã 6 số DUY NHẤT riêng biệt cho thiết bị này (tuyệt đối không trùng 889922)
        final rand = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
        effectivePin = rand;
        await prefs.setString('share_pin_code', rand);
        await prefs.setString('autobank_live_web_pin_code', rand);
      }
      if (mounted) {
        setState(() {
          _hasConfiguredSharePin = hasConfigured;
          _sharePin = effectivePin;
        });
      }
      _syncPinToBackend(effectivePin);
    } catch (_) {
      if (_sharePin.isNotEmpty) {
        _syncPinToBackend(_sharePin);
      }
    }
  }

  Future<void> _saveSharePin(String pin) async {
    setState(() {
      _sharePin = pin;
      _hasConfiguredSharePin = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_configured_share_pin', true);
      await prefs.setString('share_pin_code', pin);
      await prefs.setString('autobank_live_web_pin_code', pin);
    } catch (_) {}
    _syncPinToBackend(pin);
  }

  Future<void> _syncPinToBackend(String pin, [String? userEmail]) async {
    final cleanPin = pin.trim();
    if (cleanPin.length < 4) return;

    String effectiveEmail = (userEmail ?? '').trim().toLowerCase();
    if (effectiveEmail.isEmpty) {
      try {
        final googleAuth = context.read<GoogleAuthProvider>();
        effectiveEmail = googleAuth.email.trim().toLowerCase();
      } catch (_) {}
    }
    if (effectiveEmail.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        effectiveEmail = (prefs.getString('last_signed_in_email') ?? '').trim().toLowerCase();
      } catch (_) {}
    }

    final hosts = <String>{
      AppConfig.apiBaseUrl,
      'https://api.docthongbaobank.com',
      'https://docthongbaobank.com',
    };

    final payload = jsonEncode({
      'pin': cleanPin,
      'email': effectiveEmail,
    });

    for (final host in hosts) {
      for (final ep in ['/admin/live-pin', '/api/admin/live-pin']) {
        try {
          final uri = Uri.parse('$host$ep');
          final resp = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          ).timeout(const Duration(seconds: 8));
          if (resp.statusCode == 200 || resp.statusCode == 201) {
            break;
          }
        } catch (_) {}
      }

      if (effectiveEmail.isNotEmpty) {
        try {
          final cfgUri = Uri.parse('$host/api/tts/user-config');
          await http.post(
            cfgUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': effectiveEmail,
              'sharePin': cleanPin,
            }),
          ).timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
    }
  }

  void _generateRandomPin() {
    final random = Random();
    final newPin = (100000 + random.nextInt(900000)).toString();
    _saveSharePin(newPin);
  }

  Future<void> _loadShareConfig(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = email.isNotEmpty ? 'share_cfg_$email' : 'share_cfg_default';
      final savedStr = prefs.getString(key);
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr);
        if (decoded is Map) {
          setState(() {
            _shareCredit = decoded['shareCredit'] ?? true;
            _shareDebit = decoded['shareDebit'] ?? true;
            _shareSpeech = decoded['shareSpeech'] ?? true;
            _shareShowAmount = decoded['shareShowAmount'] ?? true;
            _shareShowContent = decoded['shareShowContent'] ?? true;
            _shareRepeatTwice = decoded['shareRepeatTwice'] ?? false;
            if (decoded['sharePin'] != null && decoded['sharePin'].toString().length == 6) {
              _sharePin = decoded['sharePin'].toString();
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveAndSyncShareConfig(String email) async {
    final cfg = {
      'shareCredit': _shareCredit,
      'shareDebit': _shareDebit,
      'shareSpeech': _shareSpeech,
      'shareShowAmount': _shareShowAmount,
      'shareShowContent': _shareShowContent,
      'shareRepeatTwice': _shareRepeatTwice,
      'sharePin': _sharePin,
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = email.isNotEmpty ? 'share_cfg_$email' : 'share_cfg_default';
      await prefs.setString(key, jsonEncode(cfg));

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/tts/user-config');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.isNotEmpty ? email : 'anonymous',
          'shareConfig': cfg,
          'sharePin': _sharePin,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Widget _buildShareToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF0284C7),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSpeaker(TransactionProvider txProvider) async {
    final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
    if (googleAuth.isExpired || !googleAuth.isActivated) {
      _showUpgradePlanModal(context);
      return;
    }
    final nextState = !_isSpeakerActive;
    if (nextState) {
      if (!kIsWeb) {
        final isAppNotif = await NotificationService.isNotificationPermissionGranted();
        final isBattery = await NotificationService.isBatteryOptimizationIgnored();
        final isListener = await NotificationService.isListenerEnabled();
        final isPhoto = await NotificationService.isPhotoPermissionGranted();

        if (!isAppNotif || !isBattery || !isListener || !isPhoto) {
          if (mounted) {
            _showPermissionValidationModal(context, txProvider);
          }
          return;
        }
      }

      setState(() {
        _isSpeakerActive = true;
      });
      txProvider.toggleTts(true);
      HapticFeedback.heavyImpact();
      TtsService().speakTestFeedback('Đã bật hệ thống đọc thông báo nhận tiền tự động.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Đã bật hệ thống đọc thông báo nhận tiền tự động! Loa đang trực 24/7.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      setState(() {
        _isSpeakerActive = false;
      });
      txProvider.toggleTts(false);
      HapticFeedback.heavyImpact();
      TtsService().speakTestFeedback('Đã tắt hệ thống đọc thông báo nhận tiền.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.pause_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Đã tắt hệ thống đọc thông báo nhận tiền.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF475569),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUpgradePlanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gói Cước Đã Hết Hạn Sử Dụng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính năng Đọc Thông Báo Tự Động 24/7 đã tạm khóa do gói dịch vụ của bạn đã hết hạn. Vui lòng đăng ký hoặc gia hạn gói cước để tiếp tục sử dụng loa báo biến động số dư tốt nhất!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(bCtx);
                widget.onNavigateToRegister?.call();
              },
              icon: const Icon(Icons.diamond_rounded, color: Colors.white, size: 20),
              label: const Text(
                'NÂNG CẤP / GIA HẠN GÓI NGAY',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(bCtx),
              child: const Text(
                'ĐỂ SAU',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionValidationModal(BuildContext context, TransactionProvider txProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.security_update_good_rounded, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cấp quyền để bật hoạt động app',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Hoàn thiện các quyền dưới đây để loa hoạt động bền bỉ',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Quyền 1: Cho phép ứng dụng phát thông báo
                  FutureBuilder<bool>(
                    future: NotificationService.isNotificationPermissionGranted(),
                    builder: (context, snapshot) {
                      final granted = snapshot.data ?? false;
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: granted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: granted ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              granted ? Icons.check_circle_rounded : Icons.notifications_none_rounded,
                              color: granted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '1. Bật thông báo của ứng dụng',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    granted ? 'Đã cho phép gửi thông báo' : 'Cho phép app hiển thị thông báo trạng thái hoạt động trên thanh thông báo',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            if (!granted) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () async {
                                  await NotificationService.requestNotificationPermission();
                                  setModalState(() {});
                                },
                                child: const Text('Bật ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Quyền 2: Chạy ngầm & Mức sử dụng pin (Nút mở thông tin ứng dụng)
                  FutureBuilder<bool>(
                    future: NotificationService.isBatteryOptimizationIgnored(),
                    builder: (context, snapshot) {
                      final ignored = snapshot.data ?? false;
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: ignored ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ignored ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              ignored ? Icons.check_circle_rounded : Icons.battery_charging_full_rounded,
                              color: ignored ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '2. Cho app chạy nền & Mức sử dụng pin',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    ignored
                                        ? 'Đã cho phép hoạt động dưới nền (Hoạt động liên tục 24/7)'
                                        : 'Vào Thông tin ứng dụng → "Mức sử dụng pin" → Bật "Cho phép hoạt động dưới nền" & "Tự động khởi chạy"',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            if (!ignored) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onPressed: () async {
                                  await NotificationService.requestIgnoreBatteryOptimizations();
                                  setModalState(() {});
                                },
                                child: const Text('Mở Cài Đặt', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Quyền 3: Đọc thông báo ngân hàng
                  FutureBuilder<bool>(
                    future: NotificationService.isListenerEnabled(),
                    builder: (context, snapshot) {
                      final granted = snapshot.data ?? false;
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: granted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: granted ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              granted ? Icons.check_circle_rounded : Icons.notifications_active_outlined,
                              color: granted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '3. Quyền đọc thông báo ngân hàng',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    granted ? 'Đã kích hoạt sẵn sàng' : 'Cho phép app nhận biết khi có thông báo nhận tiền từ các app ngân hàng',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            if (!granted) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () async {
                                  await NotificationService.openSettings();
                                  setModalState(() {});
                                },
                                child: const Text('Bật ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Quyền 4: Quyền truy cập ảnh & quét mã QR
                  FutureBuilder<bool>(
                    future: NotificationService.isPhotoPermissionGranted(),
                    builder: (context, snapshot) {
                      final granted = snapshot.data ?? false;
                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: granted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: granted ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              granted ? Icons.check_circle_rounded : Icons.photo_library_outlined,
                              color: granted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '4. Quyền truy cập ảnh & mã QR quầy',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    granted ? 'Đã cấp quyền truy cập' : 'Cho phép chọn ảnh mã QR ngân hàng từ thư viện để hiển thị tại quầy thu ngân',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            if (!granted) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF475569),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () async {
                                  await NotificationService.requestPhotoPermission();
                                  setModalState(() {});
                                },
                                child: const Text('Cho phép', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // NÚT HOÀN TẤT BẬT HOẠT ĐỘNG
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      Navigator.pop(bCtx);
                      setState(() {
                        _isSpeakerActive = true;
                      });
                      txProvider.toggleTts(true);
                      HapticFeedback.heavyImpact();
                      TtsService().speakTestFeedback('Đã bật hệ thống đọc thông báo nhận tiền tự động.');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('Đã bật hệ thống đọc thông báo nhận tiền tự động! Loa đang trực 24/7.'),
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.power_settings_new_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ĐÃ HOÀN TẤT ➔ BẬT HOẠT ĐỘNG NGAY',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleReplay(TransactionProvider txProvider) {
    HapticFeedback.lightImpact();
    final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
    if (googleAuth.isExpired || !googleAuth.isActivated) {
      _showUpgradePlanModal(context);
      return;
    }

    final sentenceToReplay = txProvider.latestBankSentence;
    final hasSentence = sentenceToReplay.isNotEmpty;
    NotificationService.ensureMaxVolume();
    if (hasSentence) {
      TtsService().speakSentence(sentenceToReplay, isBankTransaction: true, bypassChecks: true);
    } else {
      TtsService().speakTestFeedback('Chưa có thông báo nhận tiền mới từ ngân hàng để đọc lại.');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
        content: Row(
          children: [
            const Icon(Icons.replay_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(hasSentence ? 'Đang phát lại thông báo nhận tiền gần nhất...' : 'Chưa có thông báo nhận tiền mới từ ngân hàng để đọc lại'),
          ],
        ),
      ),
    );
  }

  void _handleToggleRepeat(TransactionProvider txProvider) {
    HapticFeedback.lightImpact();
    final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
    if (googleAuth.isExpired || !googleAuth.isActivated) {
      _showUpgradePlanModal(context);
      return;
    }

    txProvider.toggleRepeatTwice();

    final isRepeat = txProvider.isRepeatTwiceEnabled;
    TtsService().speakTestFeedback(isRepeat ? 'Đã bật chế độ nhắc lại hai lần.' : 'Đã tắt chế độ nhắc lại, chỉ đọc một lần.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isRepeat ? WebTheme.emerald : const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
        content: Row(
          children: [
            Icon(isRepeat ? Icons.repeat_on_rounded : Icons.repeat_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(isRepeat ? 'Đã BẬT chế độ nhắc lại (Đọc 1 lần và nhắc lại x2)' : 'Đã TẮT nhắc lại (Chỉ đọc 1 lần)'),
          ],
        ),
      ),
    );
  }

  void _handleToggleHistory() {
    HapticFeedback.lightImpact();
    final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
    if (googleAuth.isExpired || !googleAuth.isActivated) {
      _showUpgradePlanModal(context);
      return;
    }

    setState(() {
      _showTransactions = !_showTransactions;
    });

    TtsService().speakTestFeedback(_showTransactions ? 'Đã hiển thị lịch sử giao dịch.' : 'Đã ẩn lịch sử giao dịch để bảo mật quầy thu ngân.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _showTransactions ? const Color(0xFF0284C7) : const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
        content: Row(
          children: [
            Icon(_showTransactions ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(_showTransactions ? 'Đã hiển thị lịch sử giao dịch' : 'Đã ẩn lịch sử giao dịch (Bảo mật quầy thu ngân)'),
          ],
        ),
      ),
    );
  }

  void _onShareButtonPressed(BuildContext context) {
    final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
    if (googleAuth.isExpired || !googleAuth.isActivated) {
      _showUpgradePlanModal(context);
      return;
    }

    if (!_hasConfiguredSharePin) {
      _showFirstTimePinSetupModal(context);
    } else {
      _showShareLiveModal(context);
    }
  }

  void _showFirstTimePinSetupModal(BuildContext context) {
    TtsService().speakTestFeedback('Thiết lập mã bảo mật 6 số cho liên kết chia sẻ.');
    final pinController = TextEditingController(text: _sharePin);
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security_rounded, color: Color(0xFF0284C7), size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Thiết lập mã bảo mật lần đầu',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: WebTheme.textMuted),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Để bảo mật số dư tài khoản, người khác muốn truy cập vào link chia sẻ bắt buộc phải nhập mã 6 số này. Sau 24 giờ, hệ thống sẽ yêu cầu người xem nhập lại mã bảo mật 1 lần.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ô NHẬP MÃ PIN 6 SỐ
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'NHẬP MÃ BẢO MẬT 6 SỐ CỦA BẠN:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pinController,
                            maxLength: 6,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 10,
                              color: Color(0xFF0284C7),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                errorMessage = '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final random = Random();
                            final newCode = (100000 + random.nextInt(900000)).toString();
                            pinController.text = newCode;
                            setModalState(() {
                              errorMessage = '';
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF0284C7)),
                          label: const Text('Mã mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                        ),
                      ],
                    ),

                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // NÚT XÁC NHẬN & BẮT ĐẦU CHIA SẺ
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final code = pinController.text.trim();
                          if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
                            setModalState(() {
                              errorMessage = 'Vui lòng nhập đúng 6 chữ số!';
                            });
                            return;
                          }

                          _saveSharePin(code);
                          Navigator.pop(modalCtx);

                          // Mở modal chia sẻ chính thức
                          _showShareLiveModal(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF059669),
                              content: Text('Đã thiết lập mã bảo mật 6 số thành công!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          'Xác nhận & Bắt đầu chia sẻ',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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

  void _showShareLiveModal(BuildContext context) {
    TtsService().speakTestFeedback('Mở tính năng chia sẻ phát loa cho máy tính và điện thoại khác.');
    final pinController = TextEditingController(text: _sharePin);
    final googleAuth = context.read<GoogleAuthProvider>();
    final cleanEmail = googleAuth.email.trim().toLowerCase();
    // Link share sạch 100% /live theo đúng yêu cầu (không kèm gmail phía sau)
    final shareUrl = '${AppConfig.webBaseUrl}/live';
    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(shareUrl)}';

    // Đảm bảo cấu hình quyền chia sẻ mới nhất đã được tải
    _loadShareConfig(cleanEmail);
    _syncPinToBackend(_sharePin);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phonelink_ring_rounded, color: Color(0xFF0284C7), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Chia sẻ phát loa (PC / iPhone)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: WebTheme.textMuted),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chia sẻ link để người khác mở trên máy tính hoặc iPhone/iPad. Người xem bắt buộc phải nhập mã bảo mật 6 số để truy cập.',
                    style: TextStyle(fontSize: 12, color: WebTheme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // 1. KHỐI MÃ BẢO MẬT 6 SỐ (TÁCH BIỆT SO VỚI LINK)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_rounded, size: 16, color: Color(0xFF0284C7)),
                                SizedBox(width: 6),
                                Text(
                                  'MÃ BẢO MẬT 6 SỐ (NHẬP ĐỂ MỞ LINK)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Hiệu lực 24h', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _sharePin,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                      color: Color(0xFF0284C7),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nút Copy Mã
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFE0F2FE),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.all(12),
                              ),
                              icon: const Icon(Icons.copy_rounded, color: Color(0xFF0284C7), size: 20),
                              tooltip: 'Sao chép mã bảo mật',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _sharePin));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF0284C7),
                                    content: Text('Đã sao chép mã bảo mật 6 số: $_sharePin'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            // Nút Đổi Mã Mới
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0284C7)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                _generateRandomPin();
                                pinController.text = _sharePin;
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF0284C7)),
                              label: const Text(
                                'Mã mới',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cung cấp mã này cho người xem. Người xem bắt buộc phải nhập mã khi mở link.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. KHỐI LINK CHIA SẺ (KHÔNG CHỨA MÃ TRONG LINK)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.link_rounded, size: 16, color: Color(0xFF166534)),
                                SizedBox(width: 6),
                                Text(
                                  'ĐƯỜNG DẪN CHIA SẺ (LINK SHARE):',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Link độc lập', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: SelectableText(
                            shareUrl,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Nút copy riêng Link Share
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF16A34A)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: shareUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF16A34A),
                                      content: Text('Đã sao chép link chia sẻ!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.link_rounded, size: 16, color: Color(0xFF16A34A)),
                                label: const Text('Sao chép Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A))),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nút copy Link + Mã (gửi tiện lợi)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WebTheme.emerald,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  final fullMessage = '🔗 Link share nghe loa: $shareUrl\n🔑 Mã bảo mật 6 số: $_sharePin\n(Mở link và nhập mã bảo mật 6 số để nghe loa. Sau 24h cần nhập lại mã 1 lần)';
                                  Clipboard.setData(ClipboardData(text: fullMessage));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: WebTheme.emerald,
                                      content: Text('Đã sao chép Link kèm Mã bảo mật 6 số!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                                label: const Text('Gửi Link & Mã', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. TÙY CHỈNH QUYỀN & CHỨC NĂNG CHO LINK CHIA SẺ
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
                                Icon(Icons.tune_rounded, size: 16, color: Color(0xFF0284C7)),
                                SizedBox(width: 6),
                                Text(
                                  'TÙY CHỈNH QUYỀN CHO LINK CHIA SẺ',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Tự động lưu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Switch Tiền Vào (Credit)
                        _buildShareToggleRow(
                          icon: Icons.south_west_rounded,
                          iconColor: const Color(0xFF059669),
                          title: 'Chia sẻ thông báo Đã Nhận (Tiền vào)',
                          subtitle: 'Hiển thị & phát loa biến động số dư tiền về',
                          value: _shareCredit,
                          onChanged: (val) {
                            setModalState(() {
                              _shareCredit = val;
                            });
                            setState(() {
                              _shareCredit = val;
                            });
                            _saveAndSyncShareConfig(cleanEmail);
                          },
                        ),
                        const Divider(height: 10, color: Color(0xFFF1F5F9)),

                        // Switch Tiền Ra (Debit)
                        _buildShareToggleRow(
                          icon: Icons.north_east_rounded,
                          iconColor: const Color(0xFFE11D48),
                          title: 'Chia sẻ thông báo Chuyển Đi (Tiền ra)',
                          subtitle: 'Hiển thị & phát loa biến động chi tiêu/trừ tiền',
                          value: _shareDebit,
                          onChanged: (val) {
                            setModalState(() {
                              _shareDebit = val;
                            });
                            setState(() {
                              _shareDebit = val;
                            });
                            _saveAndSyncShareConfig(cleanEmail);
                          },
                        ),
                        const Divider(height: 10, color: Color(0xFFF1F5F9)),

                        // Switch Phát Loa 24/7
                        _buildShareToggleRow(
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Phát loa đọc số tiền 24/7 trên link',
                          subtitle: 'Tự động phát giọng đọc khi mở link trên PC/iPhone',
                          value: _shareSpeech,
                          onChanged: (val) {
                            setModalState(() {
                              _shareSpeech = val;
                            });
                            setState(() {
                              _shareSpeech = val;
                            });
                            _saveAndSyncShareConfig(cleanEmail);
                          },
                        ),
                        const Divider(height: 10, color: Color(0xFFF1F5F9)),

                        // Switch Ẩn/Hiện Số Tiền
                        _buildShareToggleRow(
                          icon: Icons.visibility_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Hiển thị số tiền giao dịch',
                          subtitle: 'Nếu tắt, số tiền sẽ được bảo mật (***.***đ)',
                          value: _shareShowAmount,
                          onChanged: (val) {
                            setModalState(() {
                              _shareShowAmount = val;
                            });
                            setState(() {
                              _shareShowAmount = val;
                            });
                            _saveAndSyncShareConfig(cleanEmail);
                          },
                        ),
                        const Divider(height: 10, color: Color(0xFFF1F5F9)),

                        // Switch Ẩn/Hiện Nội Dung
                        _buildShareToggleRow(
                          icon: Icons.description_rounded,
                          iconColor: const Color(0xFFD97706),
                          title: 'Hiển thị nội dung chi tiết',
                          subtitle: 'Nếu tắt, nội dung giao dịch sẽ được ẩn',
                          value: _shareShowContent,
                          onChanged: (val) {
                            setModalState(() {
                              _shareShowContent = val;
                            });
                            setState(() {
                              _shareShowContent = val;
                            });
                            _saveAndSyncShareConfig(cleanEmail);
                          },
                        ),
                        const Divider(height: 10, color: Color(0xFFF1F5F9)),

                        // Switch Đọc Nhắc Lại x2 Lần
                        _buildShareToggleRow(
                          icon: Icons.repeat_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Đọc nhắc lại x2 lần trên web',
                          subtitle: 'Đọc 1 lần và nhắc lại thêm 1 lần để nghe rõ',
                          value: _shareRepeatTwice,
                          onChanged: (val) {
                            setModalState(() {
                              _shareRepeatTwice = val;
                            });
                            setState(() {
                              _shareRepeatTwice = val;
                            });
                            _saveAndSyncShareConfig(cleanEmail);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. MÃ QR QUÉT ĐƯỜNG DẪN TRUY CẬP
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                      border: Border.all(color: WebTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Mở camera iPhone / iPad quét mã QR bên dưới để mở link share:',
                          style: TextStyle(fontSize: 11.5, color: WebTheme.textMuted),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            qrImageUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.qr_code_2_rounded, size: 100, color: WebTheme.primary),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Khi quét mã vào web, người xem sẽ phải nhập mã bảo mật 6 số.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    '🔒 Link share và Mã bảo mật 6 số là 2 mục tách biệt. Người khác có link bắt buộc phải nhập mã bảo mật thì mới truy cập được. Sau 24h phải nhập lại mã bảo mật 1 lần.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: WebTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: () => Navigator.pop(modalCtx),
                      child: const Text('Đóng Lại', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sysConfig = context.watch<SystemConfigProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final googleAuth = context.watch<GoogleAuthProvider>();
    final transactions = txProvider.transactions;

    return Scaffold(
      backgroundColor: WebTheme.slateBg,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: WebTheme.primary,
              onRefresh: () async {
                await Future.wait([
                  sysConfig.fetchConfig(),
                  txProvider.loadLocalTransactions(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // Thông báo bảo trì nếu Admin cấu hình từ SQL
                if (sysConfig.maintenance)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.engineering_rounded, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sysConfig.maintenanceMsg.isNotEmpty
                                ? sysConfig.maintenanceMsg
                                : 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ. Vui lòng quay lại sau ít phút.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),



                // Thông báo quyền truy cập thông báo Android nếu chưa cấp (tự động ẩn khi đã cấp quyền hoặc xem trên web)
                if (!kIsWeb && !txProvider.isPermissionGranted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_paused_rounded, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Chưa cấp Quyền đọc thông báo ngân hàng',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ứng dụng cần quyền này để tự động đọc loa khi điện thoại nhận tiền.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => NotificationService.openSettings(),
                          child: const Text('Cấp quyền'),
                        ),
                      ],
                    ),
                  ),

                // Cảnh báo chưa tắt tiết kiệm pin (Chạy ngầm 24/24)
                if (!_isBatteryIgnored && !kIsWeb)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.battery_alert_rounded, color: Color(0xFFDC2626), size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Mức sử dụng pin: Bật "Cho phép hoạt động dưới nền"',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Vào Thông tin ứng dụng → Mục "Mức sử dụng pin" → Bật "Cho phép hoạt động dưới nền" & "Tự động khởi chạy". Nên khóa nền app (🔒) ở màn hình đa nhiệm để máy không tắt app khi tắt màn hình.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C), height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  await NotificationService.requestIgnoreBatteryOptimizations();
                                  await _checkBatteryOptimization();
                                },
                                child: const Text('Mở Thông Tin Ứng Dụng'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF16A34A),
                                  side: const BorderSide(color: Color(0xFF86EFAC)),
                                  backgroundColor: const Color(0xFFF0FDF4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final sm = ScaffoldMessenger.of(context);
                                  await NotificationService.setBatteryOptimizationIgnored(granted: true);
                                  await _checkBatteryOptimization();
                                  sm.showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Đã xác nhận quyền chạy nền & không giới hạn pin!'),
                                      backgroundColor: Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Tôi đã bật trong Cài đặt'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // 1. THANH HEADER THƯƠNG HIỆU CHUẨN WEB (LOGO + SLOGAN + STATUS)
                _buildBrandHeader(sysConfig),

                const SizedBox(height: 10),

                // 1.1 NÚT THÔNG BÁO CHẠY DƯỚI LOGO: MÃ GIẢM GIÁ NGUOIMOI GIẢM 10% VÀ ĐẾM NGƯỢC 3 NGÀY
                _buildNewcomerPromoTicker(googleAuth),

                const SizedBox(height: 12),

                // BANNER CẢNH BÁO KHI GÓI CƯỚC HẾT HẠN
                _buildExpiredPlanBanner(),

                // 2. NÚT TẮT BẬT TO ĐÙNG NẰM TRÊN ĐẦU (MASTER ON/OFF POWER BUTTON)
                _buildMasterPowerButton(txProvider),

                const SizedBox(height: 16),

                // 3. BỘ 4 NÚT HÀNH ĐỘNG DƯỚI NÚT ON/OFF: ĐỌC LẠI, NHẮC LẠI, ẨN/HIỆN LỊCH SỬ, CHIA SẺ
                _buildControlActionsRow(txProvider),

                const SizedBox(height: 16),

                // 4. THẺ DOANH THU HÔM NAY (PULSE CARD - KHÔNG CÓ NÚT TEST)
                _buildTodayPulseCard(txProvider),

                const SizedBox(height: 14),

                // 4.1. PHÍM TẮT TIỆN ÍCH QUẦY THU NGÂN & KIẾM TIỀN
                _buildSmartCashierAndAffiliateCards(),

                const SizedBox(height: 14),

                // 5. BỘ 4 PHÍM TẮT TIỆN ÍCH HỆ THỐNG
                _buildQuickActionsGrid(sysConfig),

                const SizedBox(height: 16),

                // 6. DANH SÁCH BIẾN ĐỘNG SỐ DƯ GẦN NHẤT (CÓ CHẾ ĐỘ ẨN/HIỆN)
                _buildTransactionFeedCard(transactions),

                const SizedBox(height: 14),

                // 7. THÔNG TIN HỆ THỐNG ĐỒNG BỘ TỪ SQL
                _buildSystemInfoFooter(sysConfig),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
}

  // 1. Header chuẩn thương hiệu
  Widget _buildBrandHeader(SystemConfigProvider sysConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: WebTheme.cardDecoration(
        color: Colors.white,
        border: Border.all(color: WebTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WebTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: WebTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(WebTheme.radiusMd),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: WebTheme.primary,
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sysConfig.brandName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.textHeading,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sysConfig.brandSlogan,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: WebTheme.badgeDecoration(
              bgColor: sysConfig.isServerConnected ? WebTheme.emeraldLight : const Color(0xFFFEF3C7),
              borderColor: sysConfig.isServerConnected ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: sysConfig.isServerConnected ? WebTheme.emerald : const Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  sysConfig.isServerConnected ? '24/7' : 'Đang kết nối',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sysConfig.isServerConnected ? WebTheme.emerald : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // NÚT CHUÔNG TRUNG TÂM THÔNG BÁO HỆ THỐNG & TÙY CHỌN
          Consumer<AppNotificationProvider>(
            builder: (ctx, notifProvider, _) {
              final unread = notifProvider.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      TtsService().speakTestFeedback('Mở trung tâm thông báo ứng dụng');
                      NotificationCenterSheet.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 1.1 THÔNG BÁO CHẠY DƯỚI LOGO: MÃ GIẢM GIÁ NGUOIMOI TRONG 3 NGÀY DÙNG THỬ VỚI ĐẾM NGƯỢC THỜI GIAN THỰC
  /// CHỈ HIỂN THỊ VỚI NGƯỜI MỚI DÙNG THỬ VÀ CÒN THỜI HẠN ĐẾM NGƯỢC 3 NGÀY
  Widget _buildNewcomerPromoTicker(GoogleAuthProvider googleAuth) {
    // 1. Nếu không phải người mới dùng thử hoặc đã mua các gói chính thức (1m, 3m, 1y, lifetime) thì KHÔNG hiển thị
    if (googleAuth.isLifetime) return const SizedBox.shrink();
    final planLower = googleAuth.activePackageName.toLowerCase();
    final isExplicitPaid = planLower.contains('1 năm') || 
                           planLower.contains('1 tháng') || 
                           planLower.contains('3 tháng') || 
                           planLower.contains('6 tháng') || 
                           planLower.contains('9 tháng') || 
                           planLower.contains('vĩnh viễn');
    if (isExplicitPaid) return const SizedBox.shrink();

    // 2. Tính thời gian đếm ngược 3 ngày (72 giờ) từ thời điểm bắt đầu dùng thử
    final startTime = googleAuth.trialStartedAt ?? googleAuth.createdAt;
    final expireTime = startTime.add(const Duration(hours: 72));
    final now = DateTime.now();
    final rawRemaining = expireTime.difference(now);
    final remaining = rawRemaining > const Duration(hours: 72)
        ? const Duration(hours: 72)
        : rawRemaining;

    // 3. Nếu đã hết 3 ngày dùng thử (remaining <= 0) thì ẩn đi, không hiển thị
    if (remaining.isNegative || remaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    final String countdownStr = days > 0
        ? '$days ngày ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF2F2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.lightImpact();
            // Lưu cờ auto_apply_coupon_code = 'NGUOIMOI' để trang Đăng ký tự động áp dụng
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('auto_apply_coupon_code', 'NGUOIMOI');
            });
            widget.onNavigateToRegister?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('🎉 Đã kích hoạt mã NGUOIMOI - Giảm ngay 10% các gói!')),
                  ],
                ),
                backgroundColor: Color(0xFFEA580C),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              children: [
                // Tag mã cố định bên trái (Nhỏ gọn, rõ ràng)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: Colors.yellowAccent, size: 13),
                      SizedBox(width: 3),
                      Text(
                        'NGUOIMOI (-10%)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Dải chữ chạy (Marquee Ticker) ở giữa: Đầy đủ thông tin, không bao giờ bị tràn/đè
                Expanded(
                  child: _MarqueeTickerText(
                    text: '⚡ Giảm 10% mọi gói khi nhập mã NGUOIMOI • Đếm ngược ưu đãi: $countdownStr • Chạm để áp dụng ngay!',
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Nút Áp dụng gọn gàng bên phải
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Áp dụng',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: Colors.white, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiredPlanBanner() {
    return Consumer<GoogleAuthProvider>(
      builder: (ctx, googleAuth, _) {
        if (!googleAuth.isExpired && googleAuth.isActivated) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x0C000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói cước đã hết hạn sử dụng',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Loa và các nút chức năng đã tạm khóa. Vui lòng gia hạn gói để tiếp tục sử dụng.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFFB91C1C), height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showUpgradePlanModal(context),
                child: const Text('Gia hạn', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // DẢI SÓNG ÂM THANH SỐNG ĐỘNG (EQUALIZER BARS) KHI BẬT THÔNG BÁO
  Widget _buildEqualizerSoundWave() {
    final colors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Sky blue
      const Color(0xFF10B981), // Emerald center
      const Color(0xFF84CC16), // Lime
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
    ];
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = _pulseController.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.graphic_eq_rounded, size: 14, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(colors.length, (i) {
                  final phase = (sin((t * 2 * pi) + (i * 0.95)) + 1) / 2;
                  final barHeight = 5.0 + (phase * 15.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.2),
                    width: 3.5,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: colors[i].withValues(alpha: 0.45),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE AUDIO',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF065F46),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. NÚT TẮT BẬT TO ĐÙNG NẰM TRÊN ĐẦU (MASTER ON/OFF POWER BUTTON - VỚI HỆ THỐNG HẠT BAY VÀ HÀO QUANG ĐA SẮC)
  Widget _buildMasterPowerButton(TransactionProvider txProvider) {
    final googleAuth = context.watch<GoogleAuthProvider>();
    final isPlanExpired = googleAuth.isExpired || !googleAuth.isActivated;
    final isSpeakerActive = _isSpeakerActive && txProvider.isTtsEnabled && !isPlanExpired;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSpeakerActive
            ? const LinearGradient(
                colors: [
                  Color(0xFFF0FDF4),
                  Color(0xFFECFDF5),
                  Color(0xFFF7FEE7),
                  Color(0xFFFFFFFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.35, 0.7, 1.0],
              )
            : null,
        color: isSpeakerActive ? null : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isPlanExpired
              ? const Color(0xFFFCA5A5)
              : (isSpeakerActive ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1)),
          width: isSpeakerActive ? 2.2 : 1.5,
        ),
        boxShadow: [
          if (isSpeakerActive) ...[
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.32),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.18),
              blurRadius: 48,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF84CC16).withValues(alpha: 0.12),
              blurRadius: 60,
              spreadRadius: 6,
              offset: const Offset(0, 16),
            ),
          ] else ...[
            BoxShadow(
              color: (isPlanExpired ? const Color(0xFFDC2626) : const Color(0xFF64748B)).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // LỚP HIỆU ỨNG HẠT BAY BAY ĐA SẮC XUNG QUANH KHI BẬT (FLOATING PARTICLES)
            if (isSpeakerActive)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ParticlesPainter(progress: _particleController.value),
                    );
                  },
                ),
              ),

            // NỘI DUNG CHÍNH CỦA THẺ NẰM ĐÈ TRÊN LỚP HẠT
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              child: Column(
                children: [
                  // HUY HIỆU TRỰC TUYẾN PHÁT SÁNG KHI BẬT
                  if (isSpeakerActive)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF0D9488)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.40),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) => Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: _pulseController.value),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'SẴN SÀNG PHÁT LOA 24/7',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // NÚT NGUỒN POWER TO ĐÙNG CÓ VÒNG SÓNG RADAR + CÁC HẠT NĂNG LƯỢNG XOAY QUANH
                  GestureDetector(
                    onTap: () {
                      if (isPlanExpired) {
                        _showUpgradePlanModal(context);
                        return;
                      }
                      _toggleSpeaker(txProvider);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // VÒNG SÓNG RADAR LAN TỎA ĐA SẮC KHI BẬT (CYAN & EMERALD)
                        if (isSpeakerActive) ...[
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              final scale = 1.0 + (_pulseController.value * 0.38);
                              final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0) * 0.45;
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(34),
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF06B6D4).withValues(alpha: opacity),
                                        const Color(0xFF10B981).withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              final scale = 1.0 + ((1.0 - _pulseController.value) * 0.22);
                              final opacity = (_pulseController.value * 0.65).clamp(0.0, 1.0);
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: const Color(0xFF34D399).withValues(alpha: opacity),
                                      width: 2.2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // 4 HẠT PHÁT SÁNG ORBIT XOAY VÒNG QUANH NÚT NGUỒN
                          AnimatedBuilder(
                            animation: _particleController,
                            builder: (context, _) {
                              final angle = _particleController.value * 2 * pi;
                              const colors = [
                                Color(0xFF10B981),
                                Color(0xFF06B6D4),
                                Color(0xFFF59E0B),
                                Color(0xFF84CC16),
                              ];
                              return Stack(
                                alignment: Alignment.center,
                                children: List.generate(4, (i) {
                                  final currentAngle = angle + (i * pi / 2);
                                  final radius = 60.0 + (sin((_particleController.value * 4 * pi) + i) * 5.0);
                                  final px = cos(currentAngle) * radius;
                                  final py = sin(currentAngle) * radius;
                                  return Transform.translate(
                                    offset: Offset(px, py),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colors[i],
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors[i].withValues(alpha: 0.85),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],

                        // NÚT CHÍNH (POWER BUTTON CHÍNH GIỮA)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isSpeakerActive ? _pulseAnimation.value : 1.0,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 98,
                            height: 98,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPlanExpired
                                    ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                                    : (isSpeakerActive
                                        ? const [Color(0xFF059669), Color(0xFF10B981), Color(0xFF0D9488)]
                                        : const [Color(0xFF94A3B8), Color(0xFF475569)]),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPlanExpired
                                          ? const Color(0xFFEF4444)
                                          : (isSpeakerActive ? const Color(0xFF10B981) : const Color(0xFF475569)))
                                      .withValues(alpha: isSpeakerActive ? 0.60 : 0.25),
                                  blurRadius: isSpeakerActive ? 28 : 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSpeakerActive ? const Color(0xFF86EFAC) : const Color(0xFFF1F5F9),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSpeakerActive
                                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                          : Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    isPlanExpired ? Icons.lock_clock_rounded : Icons.power_settings_new_rounded,
                                    size: 36,
                                    color: isPlanExpired
                                        ? const Color(0xFFDC2626)
                                        : (isSpeakerActive ? const Color(0xFF059669) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DẢI SÓNG ÂM THANH EQUALIZER BARS KHI BẬT
                  if (isSpeakerActive) ...[
                    const SizedBox(height: 14),
                    _buildEqualizerSoundWave(),
                  ],

                  const SizedBox(height: 14),

                  // DÒNG CHỮ TRẠNG THÁI TO ĐẬM DƯỚI NÚT NGUỒN
                  Column(
                    children: [
                      Text(
                        isPlanExpired
                            ? 'Gói cước đã hết hạn (Đã khóa)'
                            : (isSpeakerActive ? 'Thông báo đang bật' : 'Thông báo đang tắt'),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: isPlanExpired
                              ? const Color(0xFFDC2626)
                              : (isSpeakerActive ? const Color(0xFF065F46) : const Color(0xFFDC2626)),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          isPlanExpired
                              ? 'Chạm nút ở trên để nâng cấp / gia hạn gói dịch vụ'
                              : (isSpeakerActive
                                  ? 'Loa sẵn sàng đọc thông báo tức thì khi có biến động số dư'
                                  : 'Chạm nút nguồn to ở trên để bật phát loa thông báo'),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isPlanExpired ? const Color(0xFFDC2626) : WebTheme.textMuted,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await NotificationService.ensureMaxVolume();
                          TtsService().speakTestFeedback(
                            'Kiểm tra loa thành công. AutoBank đã nhận được tiền và sẵn sàng đọc thông báo!',
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSpeakerActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSpeakerActive
                                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                size: 16,
                                color: isSpeakerActive ? const Color(0xFF059669) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bấm để nghe thử loa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSpeakerActive ? const Color(0xFF065F46) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. BỘ 4 NÚT HÀNH ĐỘNG: ĐỌC LẠI, NHẮC LẠI, ẨN/HIỆN LỊCH SỬ, CHIA SẺ
  Widget _buildControlActionsRow(TransactionProvider txProvider) {
    final googleAuth = context.watch<GoogleAuthProvider>();
    final isPlanExpired = googleAuth.isExpired || !googleAuth.isActivated;

    return Row(
      children: [
        // 1. ĐỌC LẠI
        Expanded(
          child: _buildControlSquareBtn(
            icon: Icons.replay_rounded,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFEFF6FF),
            label: 'Đọc lại',
            subLabel: 'Nghe lại',
            isLocked: isPlanExpired,
            onTap: () => _handleReplay(txProvider),
          ),
        ),
        const SizedBox(width: 8),

        // 2. NHẮC LẠI (x2)
        Expanded(
          child: _buildControlSquareBtn(
            icon: txProvider.isRepeatTwiceEnabled ? Icons.repeat_on_rounded : Icons.repeat_rounded,
            iconColor: txProvider.isRepeatTwiceEnabled ? const Color(0xFF15803D) : const Color(0xFF7C3AED),
            bgColor: txProvider.isRepeatTwiceEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFF5F3FF),
            label: 'Nhắc lại',
            subLabel: txProvider.isRepeatTwiceEnabled ? 'Bật (x2)' : 'Tắt (x1)',
            isHighlighted: txProvider.isRepeatTwiceEnabled && !isPlanExpired,
            isLocked: isPlanExpired,
            onTap: () => _handleToggleRepeat(txProvider),
          ),
        ),
        const SizedBox(width: 8),

        // 3. ẨN / HIỆN LỊCH SỬ
        Expanded(
          child: _buildControlSquareBtn(
            icon: _showTransactions ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            iconColor: _showTransactions ? const Color(0xFFD97706) : const Color(0xFF64748B),
            bgColor: _showTransactions ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
            label: _showTransactions ? 'Ẩn L.Sử' : 'Hiện L.Sử',
            subLabel: _showTransactions ? 'Đang hiện' : 'Đang ẩn',
            isLocked: isPlanExpired,
            onTap: _handleToggleHistory,
          ),
        ),
        const SizedBox(width: 8),

        // 4. CHIA SẺ (PC / IPHONE)
        Expanded(
          child: _buildControlSquareBtn(
            icon: Icons.ios_share_rounded,
            iconColor: const Color(0xFF0D9488),
            bgColor: const Color(0xFFCCFBF1),
            label: 'Chia sẻ',
            subLabel: 'PC / iPhone',
            isLocked: isPlanExpired,
            onTap: () => _onShareButtonPressed(context),
          ),
        ),
      ],
    );
  }

  Widget _buildControlSquareBtn({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String subLabel,
    bool isHighlighted = false,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isLocked ? const Color(0xFFF8FAFC) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? const Color(0xFFFCA5A5)
                  : (isHighlighted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
              width: (isHighlighted || isLocked) ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isLocked ? const Color(0xFFFEF2F2) : bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_rounded : icon,
                        color: isLocked ? const Color(0xFFDC2626) : iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isLocked ? const Color(0xFF991B1B) : WebTheme.textHeading,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isLocked ? 'Khóa' : subLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? const Color(0xFFDC2626)
                            : (isHighlighted ? const Color(0xFF15803D) : WebTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                const Positioned(
                  top: -2,
                  right: 2,
                  child: Icon(Icons.lock_rounded, size: 12, color: Color(0xFFDC2626)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Thẻ thống kê doanh thu và giao dịch hôm nay (chạm vào để điều chỉnh nếu có sai sót)
  Widget _buildTodayPulseCard(TransactionProvider txProvider) {
    final googleAuth = context.watch<GoogleAuthProvider>();
    final isPlanExpired = googleAuth.isExpired || !googleAuth.isActivated;

    return InkWell(
      onTap: () {
        if (isPlanExpired) {
          _showUpgradePlanModal(context);
          return;
        }
        _showTodayManagementSheet(txProvider);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    const Text(
                      'Hôm nay nhận được',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WebTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isPlanExpired ? Icons.lock_outline_rounded : Icons.touch_app_outlined,
                      size: 14,
                      color: isPlanExpired ? const Color(0xFFDC2626) : WebTheme.primary,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: WebTheme.badgeDecoration(
                    bgColor: WebTheme.emeraldLight,
                    borderColor: const Color(0xFF86EFAC),
                  ),
                  child: Text(
                    _showTransactions ? '${txProvider.todayCount} giao dịch' : '** giao dịch',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.emerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Số tiền hiển thị (nếu ẩn lịch sử thì che bảo mật)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _showTransactions
                      ? '+${CurrencyFormatter.formatVND(txProvider.todayTotal)}'
                      : '****** đ',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.emerald,
                    letterSpacing: -0.5,
                  ),
                ),
                isPlanExpired
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Đã khóa',
                              style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w800),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.lock_rounded, size: 13, color: Color(0xFFDC2626)),
                          ],
                        ),
                      )
                    : const Row(
                        children: [
                          Text(
                            'Điều chỉnh',
                            style: TextStyle(fontSize: 11, color: WebTheme.primary, fontWeight: FontWeight.w700),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 16, color: WebTheme.primary),
                        ],
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTodayManagementSheet(TransactionProvider txProvider) {
    final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
    if (googleAuth.isExpired || !googleAuth.isActivated) {
      _showUpgradePlanModal(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
                      'Điều chỉnh doanh thu hôm nay',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng nhận hiện tại:', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
                      SizedBox(height: 4),
                      Text('Số lượng giao dịch:', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${CurrencyFormatter.formatVND(txProvider.todayTotal)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: WebTheme.emerald),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${txProvider.todayCount} giao dịch',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nếu số tiền hôm nay bị sai sót hoặc do vừa bấm thử nghiệm, bạn có thể thực hiện:',
              style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
            ),
            // Nút 1: Tùy chỉnh Thêm (+) hoặc Trừ (-) Doanh thu hôm nay
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.tune_rounded, size: 20),
                label: const Text(
                  'Tùy chỉnh Thêm (+) / Trừ (-) doanh thu hôm nay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAdjustTodayRevenueDialog(txProvider);
                },
              ),
            ),
            const SizedBox(height: 8),
            // Nút 2: Thêm giao dịch bù (nếu sót tiền mặt / khách chuyển ngoài)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: WebTheme.primary,
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  backgroundColor: const Color(0xFFF0F9FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Thêm giao dịch bù thủ công', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddManualDialog(txProvider);
                },
              ),
            ),
            const SizedBox(height: 8),
            // Nút 3: Đặt lại về 0 (Xóa dữ liệu test)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                label: const Text('Đặt lại hôm nay về 0đ (Xóa dữ liệu test)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmResetToday(txProvider);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmResetToday(TransactionProvider txProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt lại doanh thu hôm nay?'),
        content: const Text(
          'Toàn bộ các giao dịch test hoặc giao dịch đã ghi nhận sẽ được xóa và đưa về 0đ. Bạn có chắc chắn muốn thực hiện?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              await txProvider.clearHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đưa doanh thu hôm nay về 0đ thành công!')),
                );
              }
            },
            child: const Text('Xác nhận đặt lại 0đ'),
          ),
        ],
      ),
    );
  }

  void _showAddManualDialog(TransactionProvider txProvider) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Khách thanh toán trực tiếp');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm giao dịch thủ công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú / Nội dung', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;
              if (amt > 0) {
                Navigator.pop(ctx);
                await txProvider.addManualTransaction(
                  amount: amt,
                  type: TransactionType.credit,
                  content: noteCtrl.text.trim(),
                  bankCode: 'TIỀN MẶT',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm thành công: +${CurrencyFormatter.formatVND(amt)}')),
                  );
                }
              }
            },
            child: const Text('Lưu giao dịch'),
          ),
        ],
      ),
    );
  }

  void _showAdjustTodayRevenueDialog(TransactionProvider txProvider) {
    bool isAddition = true; // true: +, false: -
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
                            'Tùy chỉnh Doanh Thu Hôm Nay',
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
                    'Chọn Thêm (+) hoặc Trừ (-) để điều chỉnh doanh thu chính xác khi phát sinh sai lệch.',
                    style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Nút chuyển đổi + hoặc -
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
                                Icon(Icons.add_circle_rounded, size: 18, color: isAddition ? const Color(0xFF15803D) : const Color(0xFF64748B)),
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
                                Icon(Icons.remove_circle_rounded, size: 18, color: !isAddition ? const Color(0xFFB91C1C) : const Color(0xFF64748B)),
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

                  // Ô nhập số tiền
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

                  // Chip gợi ý số tiền nhanh
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

                  // Ghi chú lý do
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú lý do điều chỉnh (Tùy chọn)',
                      hintText: isAddition ? 'Khách trả thêm tiền mặt, bù sót đơn...' : 'Sai sót số liệu, khách hủy đơn...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Khung xem trước kết quả
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

                  // Nút Xác nhận
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
                        if (mounted) {
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

  // 4.1. Phím tắt Quầy thu ngân & Kiếm tiền (Nền trắng, sạch sẽ)
  Widget _buildSmartCashierAndAffiliateCards() {
    return Row(
      children: [
        // Nút 1: Quầy Thu Ngân
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PosSmartCashierPage()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF0284C7), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quầy Thu Ngân',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Bán hàng quét QR',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
          ),
        ),
        const SizedBox(width: 10),
        // Nút 2: Kiếm Tiền App
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AffiliateEarnPage()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kiếm Tiền',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Hoa hồng giới thiệu',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
          ),
        ),
      ],
    );
  }

  // 5. Bộ 4 phím tắt tiện ích
  Widget _buildQuickActionsGrid(SystemConfigProvider sysConfig) {
    final googleAuth = context.watch<GoogleAuthProvider>();
    final isPlanExpired = googleAuth.isExpired || !googleAuth.isActivated;

    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            icon: isPlanExpired ? Icons.lock_rounded : Icons.record_voice_over_rounded,
            iconColor: isPlanExpired ? const Color(0xFFDC2626) : const Color(0xFF8B5CF6),
            bgColor: isPlanExpired ? const Color(0xFFFEF2F2) : const Color(0xFFF5F3FF),
            label: isPlanExpired ? 'Câu đọc 🔒' : 'Câu đọc',
            onTap: () {
              if (isPlanExpired) {
                _showUpgradePlanModal(context);
                return;
              }
              TtsService().speakTestFeedback('Mở cài đặt câu đọc thông báo');
              widget.onNavigateToVoiceSettings?.call();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            icon: Icons.diamond_rounded,
            iconColor: WebTheme.primary,
            bgColor: WebTheme.primaryBg,
            label: 'Đăng ký gói',
            onTap: () {
              TtsService().speakTestFeedback('Mở bảng đăng ký gói bản quyền');
              widget.onNavigateToRegister?.call();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            icon: Icons.battery_charging_full_rounded,
            iconColor: WebTheme.emerald,
            bgColor: WebTheme.emeraldLight,
            label: 'Chạy ngầm',
            onTap: () async {
              final googleAuth = Provider.of<GoogleAuthProvider>(context, listen: false);
              if (googleAuth.isExpired || !googleAuth.isActivated) {
                _showUpgradePlanModal(context);
                return;
              }
              // Giữ màn hình luôn bật 24/24, không bao giờ tắt màn hình, làm mờ tối đa OLED để tiết kiệm pin
              await NotificationService.setKeepScreenOn(true);
              await NotificationService.setScreenBrightness(0.01);
              if (mounted) {
                context.read<TransactionProvider>().setDimmedScreenActive(true);
              }
              TtsService().speakTestFeedback('Chế độ chạy ngầm trực biến động hai tư trên hai tư đã kích hoạt. Màn hình duy trì bật liên tục và làm mờ tiết kiệm pin.');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
            label: 'Hotline 24/7',
            onTap: () {
              final spokenPhone = _convertPhoneToSpeechText(sysConfig.hotline);
              Clipboard.setData(ClipboardData(text: sysConfig.hotline));
              TtsService().speakTestFeedback('Đã sao chép số hotline hỗ trợ kỹ thuật hai tư trên bảy: $spokenPhone');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép hotline ${sysConfig.hotline}!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _convertPhoneToSpeechText(String phone) {
    const digitMap = {
      '0': 'không',
      '1': 'một',
      '2': 'hai',
      '3': 'ba',
      '4': 'bốn',
      '5': 'năm',
      '6': 'sáu',
      '7': 'bảy',
      '8': 'tám',
      '9': 'chín',
    };
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return phone;
    final words = digits.split('').map((d) => digitMap[d] ?? d).toList();
    if (words.length == 10) {
      return '${words.sublist(0, 4).join(' ')}, ${words.sublist(4, 7).join(' ')}, ${words.sublist(7).join(' ')}';
    } else if (words.length == 11) {
      return '${words.sublist(0, 4).join(' ')}, ${words.sublist(4, 7).join(' ')}, ${words.sublist(7).join(' ')}';
    }
    return words.join(' ');
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: WebTheme.cardDecoration(
          border: Border.all(color: WebTheme.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: WebTheme.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Danh sách biến động số dư gần nhất (có hỗ trợ Ẩn / Hiện)
  Widget _buildTransactionFeedCard(List<NormalizedTransaction> transactions) {
    if (!_showTransactions) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_rounded, size: 36, color: Color(0xFF64748B)),
            const SizedBox(height: 8),
            const Text(
              'Lịch sử giao dịch đang được ẩn',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chế độ riêng tư tại quầy thu ngân đang bật. Chạm nút "Hiện L.Sử" ở trên nếu bạn muốn xem lại chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: WebTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      );
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
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 18, color: WebTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Biến động số dư gần nhất',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WebTheme.textHeading,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${transactions.length} tin',
                    style: const TextStyle(fontSize: 12, color: WebTheme.textMuted),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final txProvider = context.read<TransactionProvider>();
                      _showAllTodayTransactionsSheet(context, txProvider);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded, size: 12, color: Color(0xFF0284C7)),
                          SizedBox(width: 3),
                          Text(
                            'Xem',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text(
                'Chưa có thông báo nhận tiền mới.\n(Ứng dụng đang chạy ngầm lắng nghe thông báo ngân hàng 24/7)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted, height: 1.4),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.take(4).length,
              separatorBuilder: (_, _) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return InkWell(
                  onTap: () {
                    final txProvider = context.read<TransactionProvider>();
                    _showTransactionDetailSheet(tx, txProvider);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: WebTheme.primaryBg,
                            borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                            border: Border.all(color: WebTheme.primaryLight),
                          ),
                          child: Text(
                            tx.bankCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: WebTheme.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: WebTheme.textHeading,
                                ),
                              ),
                              Text(
                                'Lúc ${tx.transactionTime.hour}:${tx.transactionTime.minute.toString().padLeft(2, '0')} (Chạm để xem/xóa)',
                                style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${CurrencyFormatter.formatVND(tx.amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: WebTheme.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // BOTTOM SHEET HIỂN THỊ TOÀN BỘ LỊCH SỬ BIẾN ĐỘNG TRONG NGÀY HÔM ĐÓ
  void _showAllTodayTransactionsSheet(BuildContext context, TransactionProvider txProvider) {
    final now = DateTime.now();
    final todayTx = txProvider.transactions.where((t) =>
      t.transactionTime.year == now.year &&
      t.transactionTime.month == now.month &&
      t.transactionTime.day == now.day
    ).toList();

    double totalIn = 0;
    double totalOut = 0;
    for (final t in todayTx) {
      if (t.type.isCredit) {
        totalIn += t.amount;
      } else {
        totalOut += t.amount;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.history_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lịch Sử Biến Động Hôm Nay',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} • ${todayTx.length} giao dịch',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thống kê nhanh
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TỔNG TIỀN VÀO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          const SizedBox(height: 2),
                          Text(
                            '+${CurrencyFormatter.formatVND(totalIn)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TỔNG TIỀN RA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          const SizedBox(height: 2),
                          Text(
                            '-${CurrencyFormatter.formatVND(totalOut)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Danh sách tất cả giao dịch trong ngày
              Expanded(
                child: todayTx.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có giao dịch nào được ghi nhận trong ngày hôm nay.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: todayTx.length,
                        separatorBuilder: (_, _) => const Divider(height: 14, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final tx = todayTx[idx];
                          final isCredit = tx.type.isCredit;

                          return InkWell(
                            onTap: () => _showTransactionDetailSheet(tx, txProvider),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tx.bankCode,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: isCredit ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.content,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Lúc ${tx.transactionTime.hour.toString().padLeft(2, '0')}:${tx.transactionTime.minute.toString().padLeft(2, '0')}:${tx.transactionTime.second.toString().padLeft(2, '0')} • ${tx.category ?? "Chưa phân loại"}',
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetailSheet(NormalizedTransaction tx, TransactionProvider txProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: WebTheme.primaryBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tx.bankCode, style: const TextStyle(fontWeight: FontWeight.bold, color: WebTheme.primaryDark)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Chi tiết giao dịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số tiền:', style: TextStyle(fontSize: 13, color: WebTheme.textMuted)),
                      Text(
                        '+${CurrencyFormatter.formatVND(tx.amount)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: WebTheme.emerald),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời gian:', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
                      Text('${tx.transactionTime.hour}:${tx.transactionTime.minute.toString().padLeft(2, '0')} ngày ${tx.transactionTime.day}/${tx.transactionTime.month}/${tx.transactionTime.year}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nội dung ck:', style: TextStyle(fontSize: 12, color: WebTheme.textMuted)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tx.content,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text('Xóa giao dịch này (nếu bị sai)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await txProvider.deleteTransaction(tx.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã xóa giao dịch +${CurrencyFormatter.formatVND(tx.amount)}. Doanh thu hôm nay đã cập nhật lại!'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // 7. Footer thông tin máy chủ từ SQL
  Widget _buildSystemInfoFooter(SystemConfigProvider sysConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WebTheme.radiusMd),
        border: Border.all(color: WebTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, size: 16, color: WebTheme.emerald),
              SizedBox(width: 6),
              Text(
                'Bảo mật và mã hóa',
                style: TextStyle(fontSize: 11, color: WebTheme.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            'Hỗ trợ: ${sysConfig.hotline}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: WebTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// HỆ THỐNG HẠT BAY BAY ĐA SẮC DẠNG CUSTOM PAINTER
class _ParticlesPainter extends CustomPainter {
  final double progress;
  static final List<_ParticleData> _particles = List.generate(24, (index) {
    final random = Random(index * 42 + 7);
    const colors = [
      Color(0xFF10B981), // Emerald
      Color(0xFF34D399), // Mint
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF59E0B), // Amber gold
      Color(0xFF84CC16), // Lime
      Color(0xFF38BDF8), // Light blue
    ];
    return _ParticleData(
      initialX: 0.08 + (random.nextDouble() * 0.84),
      initialY: random.nextDouble(),
      size: 2.5 + (random.nextDouble() * 4.0),
      speed: 0.6 + (random.nextDouble() * 0.7),
      wobbleSpeed: 1.2 + (random.nextDouble() * 2.0),
      color: colors[index % colors.length],
      isStar: index % 3 == 0,
    );
  });

  _ParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final currentY = (p.initialY - (progress * p.speed)) % 1.0;
      final y = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;
      final wobble = sin((progress * 2 * pi * p.wobbleSpeed) + (p.initialX * 10)) * 14.0;
      final x = (p.initialX * size.width) + wobble;

      final normY = (y / size.height).clamp(0.0, 1.0);
      final alpha = (sin(normY * pi) * 0.85).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: alpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      if (p.isStar) {
        final path = Path();
        final s = p.size * 1.5;
        path.moveTo(x, y - s);
        path.quadraticBezierTo(x, y, x + s, y);
        path.quadraticBezierTo(x, y, x, y + s);
        path.quadraticBezierTo(x, y, x - s, y);
        path.quadraticBezierTo(x, y, x, y - s);
        path.close();
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size * 1.6, glowPaint);
        canvas.drawCircle(Offset(x, y), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ParticleData {
  final double initialX;
  final double initialY;
  final double size;
  final double speed;
  final double wobbleSpeed;
  final Color color;
  final bool isStar;

  const _ParticleData({
    required this.initialX,
    required this.initialY,
    required this.size,
    required this.speed,
    required this.wobbleSpeed,
    required this.color,
    required this.isStar,
  });
}

class _MarqueeTickerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeTickerText({
    required this.text,
    required this.style,
  });

  @override
  State<_MarqueeTickerText> createState() => _MarqueeTickerTextState();
}

class _MarqueeTickerTextState extends State<_MarqueeTickerText> {
  late final ScrollController _scrollController;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTicker());
  }

  void _startTicker() {
    if (!mounted) return;
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxOffset = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      if (maxOffset <= 0) return;
      if (currentOffset >= maxOffset) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(currentOffset + 1.0);
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        '${widget.text}               ${widget.text}               ',
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}



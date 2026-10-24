import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notification_listener/presentation/notification_service.dart';

class AppPermissionDialog extends StatefulWidget {
  final VoidCallback onAllGranted;

  const AppPermissionDialog({
    super.key,
    required this.onAllGranted,
  });

  /// Kiểm tra xem 2 quyền hệ thống thiết yếu thật sự đã được cấp chưa
  static Future<bool> arePermissionsGranted() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getBool('perm_notification_web') ?? false) &&
          (prefs.getBool('perm_background_web') ?? false);
    }

    try {
      final notif = await NotificationService.isListenerEnabled();
      final bg = await NotificationService.isBatteryOptimizationIgnored();
      return notif && bg;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showIfNeeded(BuildContext context) async {
    final granted = await arePermissionsGranted();
    if (!granted && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AppPermissionDialog(
          onAllGranted: () {
            Navigator.of(ctx).pop();
          },
        ),
      );
    }
  }

  @override
  State<AppPermissionDialog> createState() => _AppPermissionDialogState();
}

class _AppPermissionDialogState extends State<AppPermissionDialog> with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _backgroundGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkRealPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Tự động kiểm tra lại quyền THẬT khi người dùng từ màn hình Cài đặt quay trở lại ứng dụng
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkRealPermissions();
    }
  }

  Future<void> _checkRealPermissions() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationGranted = prefs.getBool('perm_notification_web') ?? false;
        _backgroundGranted = prefs.getBool('perm_background_web') ?? false;
        _isLoading = false;
      });
      return;
    }

    // Kiểm tra trực tiếp từ hệ thống Android
    final notif = await NotificationService.isListenerEnabled();
    final bg = await NotificationService.isBatteryOptimizationIgnored();

    if (mounted) {
      setState(() {
        _notificationGranted = notif;
        _backgroundGranted = bg;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRequestPermission(int index) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (index == 1) {
          _notificationGranted = true;
          prefs.setBool('perm_notification_web', true);
        } else if (index == 2) {
          _backgroundGranted = true;
          prefs.setBool('perm_background_web', true);
        }
      });
      return;
    }

    // Mở cài đặt hệ thống thật trên Android
    if (index == 1) {
      await NotificationService.openSettings();
    } else if (index == 2) {
      await NotificationService.requestIgnoreBatteryOptimizations();
    }

    // Đợi 800ms rồi kiểm tra lại
    Future.delayed(const Duration(milliseconds: 800), _checkRealPermissions);
  }

  bool get _isAllGranted => _notificationGranted && _backgroundGranted;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Yêu Cầu Cấp Quyền Hoạt Động',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Để AutoBank bắt thông báo ngân hàng và đọc tiền tự động 24/7, bạn cần cấp đủ 2 quyền quan trọng nhất trong Cài đặt máy:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                // Quyền 1: Quyền đọc thông báo
                _buildPermissionTile(
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: '1. Quyền đọc thông báo',
                  desc: 'Bắt biến động số dư các app ngân hàng (MB, VCB, ACB...) ngay tức thì',
                  isGranted: _notificationGranted,
                  onGrant: () => _handleRequestPermission(1),
                ),
                const SizedBox(height: 10),

                // Quyền 2: Cho phép hoạt động dưới nền
                _buildPermissionTile(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: '2. Cho phép hoạt động dưới nền',
                  desc: 'Mở Thông tin ứng dụng → Vào "Mức sử dụng pin" → Bật "Cho phép hoạt động dưới nền" & "Tự động khởi chạy"',
                  isGranted: _backgroundGranted,
                  onGrant: () => _handleRequestPermission(2),
                ),
                const SizedBox(height: 10),

                // Hướng dẫn khóa ứng dụng dưới màn hình đa nhiệm (Recent Apps)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Khóa nền app: Vào màn hình đa nhiệm (vuốt lên giữ) → Bấm biểu tượng 3 chấm [⋮] góc thẻ app → Chọn "Khóa" (🔒) để không bị tắt khi dọn RAM.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D), height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Nút kiểm tra lại / bắt đầu dùng app
                ElevatedButton(
                  onPressed: _isAllGranted
                      ? () {
                          widget.onAllGranted();
                        }
                      : () {
                          _checkRealPermissions();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAllGranted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isAllGranted ? Icons.check_circle_rounded : Icons.refresh_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isAllGranted ? 'Bắt Đầu Sử Dụng AutoBank Ngay' : 'Kiểm Tra Lại Trạng Thái Cài Đặt',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
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

  Widget _buildPermissionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required bool isGranted,
    required VoidCallback onGrant,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGranted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isGranted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isGranted ? const Color(0xFF166534) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isGranted
              ? const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                    ],
                  ),
                )
              : OutlinedButton(
                  onPressed: onGrant,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cấp quyền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }
}

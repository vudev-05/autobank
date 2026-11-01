import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/system/presentation/providers/system_config_provider.dart';
import '../../features/auth/presentation/providers/google_auth_provider.dart';
import '../utils/app_store_launcher.dart';

class AppInAppRatingDialog extends StatefulWidget {
  final VoidCallback? onSubmitted;
  final bool isMandatory; // Nếu true: không thể tắt (bắt buộc đánh giá)

  const AppInAppRatingDialog({
    super.key,
    this.onSubmitted,
    this.isMandatory = false,
  });

  static const String prefKeyRated = 'has_submitted_5_star_rating';
  static const String prefKeyFirstLaunch = 'trial_first_launch_time';

  /// Mở trực tiếp trang CH Play từ bất kỳ đâu (nút trong cài đặt)
  static Future<void> openStoreDirectly(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyRated, true);

    String customAppId = 'com.docthongbaobank.app';
    if (context.mounted) {
      final sysConfig = context.read<SystemConfigProvider>();
      final link = sysConfig.ratingUrl.trim();
      if (link.contains('id=')) {
        final match = RegExp(r'id=([a-zA-Z0-9._]+)').firstMatch(link);
        if (match != null && match.group(1) != null) {
          customAppId = match.group(1)!;
        }
      }
    }
    await AppStoreLauncher.openPlayStore(appId: customAppId);
  }

  /// Kiểm tra điều kiện bắt buộc đánh giá khi người dùng dùng thử >= 24h
  static Future<void> checkAndShowRating(BuildContext context) async {
    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool(prefKeyRated) ?? false;
    if (hasRated) return; // Đã đánh giá -> không bao giờ hiện nữa

    if (!context.mounted) return;
    final sysConfig = context.read<SystemConfigProvider>();
    // Nếu admin tắt chức năng yêu cầu đánh giá -> không hiện
    if (!sysConfig.forceRating) return;

    final googleAuth = context.read<GoogleAuthProvider>();
    DateTime? accountCreationTime = googleAuth.isSignedIn ? googleAuth.createdAt : null;

    int diffHours = 0;
    if (accountCreationTime != null) {
      diffHours = DateTime.now().difference(accountCreationTime).inHours;
    } else {
      int? firstLaunch = prefs.getInt(prefKeyFirstLaunch);
      if (firstLaunch == null) {
        firstLaunch = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(prefKeyFirstLaunch, firstLaunch);
        return;
      }
      diffHours = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(firstLaunch)).inHours;
    }

    // Bắt buộc sau khi tài khoản tạo được từ 24h trở đi
    if (diffHours >= 24) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false, // Bắt buộc, không bấm ra ngoài để đóng
        builder: (ctx) => PopScope(
          canPop: false, // Chặn nút back Android
          child: AppInAppRatingDialog(
            isMandatory: true,
            onSubmitted: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    }
  }

  @override
  State<AppInAppRatingDialog> createState() => _AppInAppRatingDialogState();
}

class _AppInAppRatingDialogState extends State<AppInAppRatingDialog> {
  bool _opening = false;

  Future<void> _openRealPlayStore() async {
    setState(() => _opening = true);
    final prefs = await SharedPreferences.getInstance();
    // Đánh dấu đã thực hiện đánh giá trên Google Play
    await prefs.setBool(AppInAppRatingDialog.prefKeyRated, true);

    if (mounted) {
      final sysConfig = context.read<SystemConfigProvider>();
      String customAppId = 'com.docthongbaobank.app';
      final link = sysConfig.ratingUrl.trim();
      if (link.contains('id=')) {
        final match = RegExp(r'id=([a-zA-Z0-9._]+)').firstMatch(link);
        if (match != null && match.group(1) != null) {
          customAppId = match.group(1)!;
        }
      }

      await AppStoreLauncher.openPlayStore(appId: customAppId);

      // Sau khi mở CH Play, đóng dialog và tiếp tục dùng app
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Cảm ơn bạn đã đánh giá 5 sao cho ứng dụng trên Google Play!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Google Play Store chính thống
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.star_rate_rounded, color: Color(0xFFF59E0B), size: 40),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Đánh Giá 5 Sao Trên Google Play',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              widget.isMandatory
                  ? 'Bạn đã trải nghiệm ứng dụng hơn 24 giờ. Vui lòng gửi đánh giá 5 sao trên Google Play (CH Play) để ủng hộ đội ngũ phát triển và tiếp tục sử dụng miễn phí.'
                  : 'Hãy dành 10 giây gửi đánh giá 5 sao trên CH Play để giúp ứng dụng ngày càng hoàn thiện hơn!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 18),

            // Hiển thị 5 sao vàng nổi bật
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 36),
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 36),
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 36),
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 36),
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 36),
              ],
            ),
            const SizedBox(height: 6),

            const Text(
              'Tuyệt vời! Cực kỳ hài lòng ⭐⭐⭐⭐⭐',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 22),

            // Nút Mở trang CH Play ngay lập tức
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01875F), // Google Play Brand Color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _opening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.open_in_new_rounded, size: 20),
                label: Text(
                  _opening ? 'Đang mở CH Play...' : 'Đánh Giá Ngay Trên CH Play',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: _opening ? null : _openRealPlayStore,
              ),
            ),

            // Nếu không bắt buộc thì mới có nút đóng
            if (!widget.isMandatory) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Để sau',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/system/presentation/providers/system_config_provider.dart';
import '../utils/app_store_launcher.dart';

class AppInAppRatingDialog extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const AppInAppRatingDialog({super.key, this.onSubmitted});

  static const String prefKeyRated = 'has_submitted_5_star_rating';
  static const String prefKeyFirstLaunch = 'trial_first_launch_time';

  /// Kiểm tra nếu cần hiển thị popup đánh giá
  static Future<bool> shouldShowRating() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool(prefKeyRated) ?? false;
    if (hasRated) return false;

    int? firstLaunch = prefs.getInt(prefKeyFirstLaunch);
    if (firstLaunch == null) {
      firstLaunch = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(prefKeyFirstLaunch, firstLaunch);
      return false;
    }

    final diffHours = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(firstLaunch)).inHours;
    return diffHours >= 24;
  }

  static Future<void> showDirectRating(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppInAppRatingDialog(
        onSubmitted: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  static Future<void> checkAndShowRating(BuildContext context) async {
    // Không tự động popup làm phiền người dùng
  }

  @override
  State<AppInAppRatingDialog> createState() => _AppInAppRatingDialogState();
}

class _AppInAppRatingDialogState extends State<AppInAppRatingDialog> {
  int _rating = 5;
  bool _submittedInApp = false;

  Future<void> _submitInAppRating() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppInAppRatingDialog.prefKeyRated, true);
    await prefs.setInt('user_app_rating_stars', _rating);

    setState(() {
      _submittedInApp = true;
    });

    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      Navigator.of(context).pop();
      widget.onSubmitted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Cảm ơn bạn đã gửi đánh giá $_rating sao cho AutoBank!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openRealPlayStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppInAppRatingDialog.prefKeyRated, true);

    if (mounted) {
      final sysConfig = context.read<SystemConfigProvider>();
      final customLink = sysConfig.chplayLink.trim();
      Navigator.of(context).pop();
      widget.onSubmitted?.call();

      if (customLink.isNotEmpty) {
        AppStoreLauncher.openPlayStore(appId: 'com.docthongbaobank.app');
      } else {
        AppStoreLauncher.openPlayStore(appId: 'com.docthongbaobank.app');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedInApp) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đã Gửi Đánh Giá Thành Công!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
              ),
              const SizedBox(height: 8),
              Text(
                'Đánh giá $_rating sao của bạn đã được ghi nhận trực tiếp vào hệ thống Google Play. Chúc bạn kinh doanh phát đạt!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Google Play Store chính thống
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.shop_two_rounded, color: Color(0xFF01875F), size: 32),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Đánh Giá Google Play (CH Play)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),

            const Text(
              'Bạn có thể gửi xếp hạng 5 sao trực tiếp ngay trong app hoặc mở trang ứng dụng trên CH Play.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.35),
            ),
            const SizedBox(height: 16),

            // Chọn số sao
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 38,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),

            Text(
              _rating == 5 ? 'Tuyệt vời! Cực kỳ hài lòng ⭐⭐⭐⭐⭐' : '$_rating sao trên Google Play',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 20),

            // Nút 1: Đánh giá ngay trong app (In-App Review)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01875F), // Google Play Brand Color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Gửi Đánh Giá Ngay Trong App',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                onPressed: _submitInAppRating,
              ),
            ),
            const SizedBox(height: 10),

            // Nút 2: Mở CH Play Store trực tiếp
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF64748B)),
                label: const Text(
                  'Mở Trang CH Play Store',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: _openRealPlayStore,
              ),
            ),
            const SizedBox(height: 6),

            // Nút Để sau
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Để sau',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

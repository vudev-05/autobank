import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../auth/presentation/providers/google_auth_provider.dart';
import '../../../system/presentation/providers/system_config_provider.dart';

class RegisterSubscriptionPage extends StatefulWidget {
  final String? initialPackageKey;
  final VoidCallback? onBackToHome;
  const RegisterSubscriptionPage({super.key, this.initialPackageKey, this.onBackToHome});

  @override
  State<RegisterSubscriptionPage> createState() => _RegisterSubscriptionPageState();
}

class _RegisterSubscriptionPageState extends State<RegisterSubscriptionPage> {
  late final TextEditingController _shopController;
  late final TextEditingController _phoneController;
  Timer? _liveCountdownTimer;

  // Gói được chọn (Mặc định gói 1 năm hoặc gói truyền vào từ deep link)
  late String _selectedPackageKey;

  @override
  void initState() {
    super.initState();
    _selectedPackageKey = widget.initialPackageKey ?? '1year';
    final auth = context.read<GoogleAuthProvider>();
    _shopController = TextEditingController(text: auth.shopName);
    _phoneController = TextEditingController(text: auth.phone);

    // Bắt đầu đếm ngược thời gian thực từng giây cho gói dùng thử 3 ngày
    _liveCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    // Đồng bộ cấu hình bảng giá và gói cước mới nhất từ máy chủ Admin 24/24
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SystemConfigProvider>().fetchConfig();
      }
    });
  }

  @override
  void dispose() {
    _liveCountdownTimer?.cancel();
    _shopController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPackages(SystemConfigProvider sysConfig, [GoogleAuthProvider? googleAuth]) {
    final coupon = sysConfig.getBestCouponForUser(
      userCreatedAt: googleAuth?.createdAt,
      userEmail: googleAuth?.email,
    );

    int calcDiscount(int original) {
      if (coupon == null || original <= 0) return original;
      final minPrice = (coupon['minPrice'] as num?)?.toInt() ?? 0;
      if (minPrice > 0 && original < minPrice) return original;

      int discount = 0;
      final pct = (coupon['discountPercent'] as num?)?.toInt() ?? 0;
      final amt = (coupon['discountAmount'] as num?)?.toInt() ?? 0;
      if (pct > 0) {
        discount = ((original * pct / 100) / 1000).round() * 1000;
      } else if (amt > 0) {
        discount = amt;
      }
      return (original - discount).clamp(0, original);
    }

    final hasCoupon = coupon != null;
    final int couponPct = hasCoupon ? ((coupon['discountPercent'] as num?)?.toInt() ?? 0) : 0;
    final int couponAmt = hasCoupon ? ((coupon['discountAmount'] as num?)?.toInt() ?? 0) : 0;
    final String? couponBadge = hasCoupon
        ? (couponPct > 0
            ? 'Voucher -$couponPct% ⚡'
            : '-${CurrencyFormatter.formatVND(couponAmt.toDouble())} ⚡')
        : null;

    final p1m = calcDiscount(sysConfig.price1m);
    final p3m = calcDiscount(sysConfig.price3m);
    final p6m = calcDiscount(sysConfig.price6m);
    final p1y = calcDiscount(sysConfig.price1y);
    final pLife = calcDiscount(sysConfig.priceLifetime);

    if (sysConfig.packages.isNotEmpty) {
      final dynamicList = <Map<String, dynamic>>[];
      for (final p in sysConfig.packages) {
        if (p['isActive'] == false) continue;
        final rawPrice = (p['price'] as num?)?.toInt() ?? 0;
        final discountedPrice = calcDiscount(rawPrice);
        final key = (p['key'] ?? 'pkg_${p['durationDays']}').toString();
        final days = (p['durationDays'] as num?)?.toInt() ?? 30;
        final name = (p['name'] ?? 'Gói dịch vụ').toString();
        final badge = (p['badge'] ?? '').toString();
        final desc = (p['description'] ?? '').toString();

        IconData icon = Icons.card_membership_rounded;
        if (days <= 3) {
          icon = Icons.timer_outlined;
        } else if (days <= 30) {
          icon = Icons.calendar_today_rounded;
        } else if (days <= 90) {
          icon = Icons.calendar_month_rounded;
        } else if (days <= 365) {
          icon = Icons.stars_rounded;
        } else {
          icon = Icons.workspace_premium_rounded;
        }

        final isDiscounted = hasCoupon && discountedPrice < rawPrice && rawPrice > 0;
        final commission = sysConfig.getCommissionForPackage(
          key: key,
          name: name,
          durationDays: days,
          price: discountedPrice,
        );

        dynamicList.add({
          'key': key,
          'name': name,
          'duration': days >= 9999 ? 'Trọn đời không giới hạn' : 'Thời hạn $days ngày',
          'days': days,
          'originalPrice': isDiscounted ? rawPrice : null,
          'originalPriceText': isDiscounted ? CurrencyFormatter.formatVND(rawPrice.toDouble()) : null,
          'price': discountedPrice,
          'priceText': discountedPrice == 0 ? '0đ' : CurrencyFormatter.formatVND(discountedPrice.toDouble()),
          'commission': commission,
          'badge': badge.isNotEmpty ? badge : couponBadge,
          'desc': desc.isNotEmpty ? desc : 'Đọc thông báo nhận tiền VietQR 24/7 ổn định',
          'isFeatured': badge.contains('Khuyên dùng') || key == '1year' || key == '1y',
          'icon': icon,
        });
      }
      if (dynamicList.isNotEmpty) return dynamicList;
    }

    final is1mDiscounted = hasCoupon && p1m < sysConfig.price1m && sysConfig.price1m > 0;
    final is3mDiscounted = hasCoupon && p3m < sysConfig.price3m && sysConfig.price3m > 0;
    final is6mDiscounted = hasCoupon && p6m < sysConfig.price6m && sysConfig.price6m > 0;
    final is1yDiscounted = hasCoupon && p1y < sysConfig.price1y && sysConfig.price1y > 0;
    final is2yDiscounted = hasCoupon && pLife < sysConfig.priceLifetime && sysConfig.priceLifetime > 0;
    final String? voucherTag = hasCoupon
        ? (couponPct > 0 ? '-$couponPct% VOUCHER' : '-${CurrencyFormatter.formatVND(couponAmt.toDouble())}')
        : null;

    return [
      {
        'key': 'trial',
        'name': 'Dùng thử miễn phí',
        'duration': 'Thời hạn 3 ngày',
        'days': 3,
        'price': 0,
        'priceText': '0đ',
        'badge': 'Miễn phí',
        'desc': 'Trải nghiệm 100% tính năng cao cấp trong 3 ngày',
        'isFeatured': false,
        'icon': Icons.timer_outlined,
      },
      {
        'key': '1m',
        'name': '1 Tháng',
        'duration': 'Thời hạn 30 ngày',
        'days': 30,
        'originalPrice': is1mDiscounted ? sysConfig.price1m : null,
        'originalPriceText': is1mDiscounted ? CurrencyFormatter.formatVND(sysConfig.price1m.toDouble()) : null,
        'voucherTag': is1mDiscounted ? voucherTag : null,
        'price': p1m,
        'priceText': CurrencyFormatter.formatVND(p1m.toDouble()),
        'commission': sysConfig.getCommissionForPackage(key: '1m', name: '1 Tháng', durationDays: 30, price: p1m),
        'badge': couponBadge ?? 'Trải nghiệm',
        'desc': 'Bản quyền 30 ngày đầy đủ thông báo giọng nói',
        'isFeatured': false,
        'icon': Icons.calendar_today_rounded,
      },
      {
        'key': '3m',
        'name': '3 Tháng',
        'duration': 'Thời hạn 90 ngày',
        'days': 90,
        'originalPrice': is3mDiscounted ? sysConfig.price3m : null,
        'originalPriceText': is3mDiscounted ? CurrencyFormatter.formatVND(sysConfig.price3m.toDouble()) : null,
        'voucherTag': is3mDiscounted ? voucherTag : null,
        'price': p3m,
        'priceText': CurrencyFormatter.formatVND(p3m.toDouble()),
        'commission': sysConfig.getCommissionForPackage(key: '3m', name: '3 Tháng', durationDays: 90, price: p3m),
        'badge': couponBadge ?? 'Tiết kiệm',
        'desc': 'Bản quyền 90 ngày cho cửa hàng kinh doanh',
        'isFeatured': false,
        'icon': Icons.calendar_month_rounded,
      },
      {
        'key': '6m',
        'name': '6 Tháng',
        'duration': 'Thời hạn 180 ngày',
        'days': 180,
        'originalPrice': is6mDiscounted ? sysConfig.price6m : null,
        'originalPriceText': is6mDiscounted ? CurrencyFormatter.formatVND(sysConfig.price6m.toDouble()) : null,
        'voucherTag': is6mDiscounted ? voucherTag : null,
        'price': p6m,
        'priceText': CurrencyFormatter.formatVND(p6m.toDouble()),
        'commission': sysConfig.getCommissionForPackage(key: '6m', name: '6 Tháng', durationDays: 180, price: p6m),
        'badge': couponBadge ?? 'Phổ biến',
        'desc': 'Bản quyền 180 ngày ổn định 24/7',
        'isFeatured': false,
        'icon': Icons.date_range_rounded,
      },
      {
        'key': '1y',
        'name': '1 Năm (tặng 2T)',
        'duration': 'Thời hạn 425 ngày',
        'days': 425,
        'originalPrice': is1yDiscounted ? sysConfig.price1y : null,
        'originalPriceText': is1yDiscounted ? CurrencyFormatter.formatVND(sysConfig.price1y.toDouble()) : null,
        'voucherTag': is1yDiscounted ? voucherTag : null,
        'price': p1y,
        'priceText': CurrencyFormatter.formatVND(p1y.toDouble()),
        'commission': sysConfig.getCommissionForPackage(key: '1y', name: '1 Năm (tặng 2T)', durationDays: 425, price: p1y),
        'badge': couponBadge ?? 'Khuyên dùng',
        'desc': 'Tặng thêm 2 tháng + Hỗ trợ kỹ thuật 24/7',
        'isFeatured': true,
        'icon': Icons.workspace_premium_rounded,
      },
      {
        'key': '2y',
        'name': '2 Năm (tặng 6T)',
        'duration': 'Thời hạn 910 ngày',
        'days': 910,
        'originalPrice': is2yDiscounted ? sysConfig.priceLifetime : null,
        'originalPriceText': is2yDiscounted ? CurrencyFormatter.formatVND(sysConfig.priceLifetime.toDouble()) : null,
        'voucherTag': is2yDiscounted ? voucherTag : null,
        'price': pLife,
        'priceText': CurrencyFormatter.formatVND(pLife.toDouble()),
        'commission': sysConfig.getCommissionForPackage(key: '2y', name: '2 Năm (tặng 6T)', durationDays: 910, price: pLife),
        'badge': couponBadge ?? 'Tốt Nhất',
        'desc': 'Tặng thêm 6 tháng + Hỗ trợ kỹ thuật 24/7',
        'isFeatured': false,
        'icon': Icons.all_inclusive_rounded,
      },
    ];
  }

  /// DIALOG TẠO TÀI KHOẢN GOOGLE MỚI
  void _showCreateGoogleAccountDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final shopCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusLg)),
        title: const Row(
          children: [
            GoogleLogo(size: 22),
            SizedBox(width: 10),
            Text('Tạo tài khoản Google mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo tài khoản để đồng bộ bản quyền. Sau khi tạo, bạn sẽ được chọn gói dịch vụ & bắt đầu đếm ngược 3 ngày dùng thử miễn phí.',
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Họ và tên Google',
                  hintText: 'Ví dụ: Lê Hoàng Minh',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ Gmail',
                  hintText: 'hoangminh.shop@gmail.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shopCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên cửa hàng / Loa chào quán',
                  hintText: 'Ví dụ: Cà Phê Muối Sài Gòn',
                  prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Hủy', style: TextStyle(color: WebTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Người dùng Google';
              final email = emailCtrl.text.trim().isNotEmpty
                  ? emailCtrl.text.trim()
                  : 'user_${DateTime.now().millisecondsSinceEpoch % 10000}@gmail.com';
              final shop = shopCtrl.text.trim().isNotEmpty ? shopCtrl.text.trim() : 'Tiệm của $name';

              final auth = context.read<GoogleAuthProvider>();
              auth.createNewGoogleAccount(name: name, email: email, shop: shop);
              _shopController.text = shop;

              Navigator.pop(dlgCtx);

              // Ngay khi tạo tài khoản: Mở BẢNG CÁC GÓI ĐĂNG KÝ BẢN QUYỀN ĐẦY ĐỦ CÁC GÓI
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showAllSubscriptionPackagesModal(context, isNewAccount: true);
                }
              });
            },
            child: const Text('Tạo & Xem bảng gói', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// BẢNG CÁC GÓI ĐĂNG KÝ BẢN QUYỀN ĐẦY ĐỦ CÁC GÓI (KHI TẠO TÀI KHOẢN HOẶC BẤM XEM)
  void _showAllSubscriptionPackagesModal(BuildContext context, {bool isNewAccount = false}) {
    final sysConfig = context.read<SystemConfigProvider>();
    final googleAuth = context.read<GoogleAuthProvider>();
    final packages = _getPackages(sysConfig, googleAuth);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Thanh kéo
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Modal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: WebTheme.primaryBg,
                            borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                          ),
                          child: const Icon(Icons.table_chart_rounded, color: WebTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isNewAccount
                                    ? 'Bảng các gói đăng ký tài khoản mới'
                                    : 'Bảng các gói đăng ký bản quyền',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: WebTheme.textHeading,
                                ),
                              ),
                              Text(
                                'Tài khoản: ${googleAuth.displayName} • Tạo lúc ${googleAuth.createdAt.hour.toString().padLeft(2, '0')}:${googleAuth.createdAt.minute.toString().padLeft(2, '0')} (${googleAuth.createdAt.day}/${googleAuth.createdAt.month})',
                                style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: WebTheme.textMuted),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),

                  // Banner thông báo nếu là tài khoản mới
                  if (isNewAccount || !googleAuth.isTrialStarted)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, color: Color(0xFF1D4ED8), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chọn "Gói dùng thử 3 ngày" để kích hoạt và bắt đầu đếm ngược thời gian miễn phí ngay lúc này!',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 12, color: WebTheme.cardBorder),

                  // Danh sách bảng tất cả các gói
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: packages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final pkg = packages[index];
                        final isTrial = pkg['key'] == 'trial';
                        final isFeatured = pkg['isFeatured'] as bool;
                        final activePkg = googleAuth.activePackageName.toLowerCase();
                        final pkgName = (pkg['name'] as String).toLowerCase();
                        final pkgKey = (pkg['key'] as String).toLowerCase();

                        final isCurrentActivePackage = googleAuth.isActivated && !googleAuth.isExpired && (
                          (googleAuth.isLifetime && (pkgKey == 'lifetime' || pkgName.contains('vĩnh viễn'))) ||
                          (activePkg.contains('1 năm') && (pkgKey == '1year' || pkgKey == '1y' || pkgName.contains('1 năm'))) ||
                          (activePkg.contains('9 tháng') && (pkgKey == '9month' || pkgName.contains('9 tháng'))) ||
                          (activePkg.contains('6 tháng') && (pkgKey == '6month' || pkgName.contains('6 tháng'))) ||
                          (activePkg.contains('3 tháng') && (pkgKey == '3month' || pkgName.contains('3 tháng'))) ||
                          (activePkg.contains('1 tháng') && (pkgKey == '1month' || pkgName.contains('1 tháng'))) ||
                          (activePkg.contains('dùng thử') && isTrial)
                        );

                        String? displayBadge = pkg['badge'];
                        if (isCurrentActivePackage) {
                          displayBadge = 'Đang sử dụng ✓';
                        } else if (isTrial) {
                          if (googleAuth.isActivated && !googleAuth.activePackageName.contains('Dùng thử')) {
                            displayBadge = 'Đã hoàn thành dùng thử';
                          } else if (googleAuth.isExpired && googleAuth.activePackageName.contains('Dùng thử')) {
                            displayBadge = 'Đã hết hạn dùng thử';
                          } else if (googleAuth.isTrialStarted) {
                            displayBadge = 'Đang đếm ngược ⏳';
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrentActivePackage
                                ? const Color(0xFFF0FDF4)
                                : (isFeatured ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                            border: Border.all(
                              color: isCurrentActivePackage
                                  ? WebTheme.emerald
                                  : (isFeatured ? const Color(0xFF86EFAC) : WebTheme.cardBorder),
                              width: (isCurrentActivePackage || isFeatured) ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isTrial
                                      ? const Color(0xFFFEF3C7)
                                      : (isFeatured ? const Color(0xFFDCFCE7) : WebTheme.primaryBg),
                                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                                ),
                                child: Icon(
                                  pkg['icon'] as IconData,
                                  color: isTrial
                                      ? const Color(0xFFD97706)
                                      : (isFeatured ? WebTheme.emerald : WebTheme.primary),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            pkg['name'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (displayBadge != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isCurrentActivePackage
                                                  ? const Color(0xFFDCFCE7)
                                                  : (isFeatured ? const Color(0xFFFEF3C7) : WebTheme.emeraldLight),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isCurrentActivePackage
                                                    ? const Color(0xFF16A34A)
                                                    : (isFeatured ? const Color(0xFFF59E0B) : WebTheme.emerald),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              displayBadge,
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: isCurrentActivePackage
                                                    ? const Color(0xFF15803D)
                                                    : (isFeatured ? const Color(0xFFB45309) : WebTheme.emerald),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pkg['duration']} • ${pkg['desc']}',
                                      style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (pkg['originalPriceText'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            pkg['originalPriceText'],
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF94A3B8),
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: const Color(0xFFFECACA), width: 0.5),
                                            ),
                                            child: Text(
                                              (pkg['voucherTag'] ?? '-10% VOUCHER').toString(),
                                              style: const TextStyle(
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    pkg['priceText'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isTrial ? const Color(0xFFD97706) : WebTheme.emerald,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: isTrial
                                          ? const Color(0xFFD97706)
                                          : (isFeatured ? WebTheme.primary : const Color(0xFF0F172A)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(modalCtx);
                                      if (isTrial) {
                                        _handleActivateTrial(googleAuth);
                                      } else {
                                        setState(() {
                                          _selectedPackageKey = pkg['key'];
                                        });
                                        _openPaymentModal(context, pkg, sysConfig, googleAuth);
                                      }
                                    },
                                    child: Text(
                                      isTrial ? 'Chọn dùng thử' : 'Chọn gói',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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

  /// BOTTOM SHEET CHỌN TÀI KHOẢN GOOGLE HOẶC THÊM MỚI
  void _showGoogleAccountPicker(BuildContext context) {
    final googleAuth = context.read<GoogleAuthProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      GoogleLogo(size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Quản lý tài khoản Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: WebTheme.textHeading,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: WebTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Bản quyền và thời gian đếm ngược 3 ngày dùng thử được tính riêng cho từng tài khoản Google.',
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
              ),
              const SizedBox(height: 14),

              // Danh sách tài khoản hiện có
              ...googleAuth.accounts.asMap().entries.map((entry) {
                final idx = entry.key;
                final acc = entry.value;
                final isCurrent = googleAuth.email == acc.email;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? WebTheme.primaryBg : Colors.white,
                    borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                    border: Border.all(
                      color: isCurrent ? WebTheme.primary : WebTheme.cardBorder,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? WebTheme.primary : const Color(0xFF64748B),
                      child: Text(
                        acc.initial,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            acc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: acc.isTrialStarted ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            acc.isTrialStarted ? 'Đang dùng thử' : 'Chưa kích hoạt',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: acc.isTrialStarted ? const Color(0xFFB45309) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${acc.email} • Tạo lúc ${acc.createdAt.hour.toString().padLeft(2, '0')}:${acc.createdAt.minute.toString().padLeft(2, '0')} (${acc.createdAt.day}/${acc.createdAt.month})',
                      style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle_rounded, color: WebTheme.primary)
                        : null,
                    onTap: () {
                      googleAuth.selectAccountByIndex(idx);
                      _shopController.text = acc.shop;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: WebTheme.emerald,
                          content: Text('Đã chọn tài khoản: ${acc.email}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 10),

              // Nút tạo / thêm tài khoản Google mới
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: WebTheme.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: WebTheme.primary),
                  label: const Text(
                    '+ Thêm tài khoản Google mới (Đăng ký mới)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WebTheme.primary),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateGoogleAccountDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// KÍCH HOẠT GÓI DÙNG THỬ 3 NGÀY & BẮT ĐẦU ĐẾM NGƯỢC TỪ LÚC NÀY
  void _handleActivateTrial(GoogleAuthProvider googleAuth) async {
    if (googleAuth.isLifetime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD97706),
          content: Text('👑 Bạn đã sở hữu Gói Vĩnh Viễn VIP nhất hệ thống, không cần dùng thử!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (googleAuth.currentAccount.hasUsedTrial) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusLg)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Chỉ được dùng thử 1 lần', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Tài khoản Google (${googleAuth.email}) đã sử dụng quyền dùng thử 3 ngày trước đó.\n\n'
            'Mỗi tài khoản chỉ được hưởng chính sách dùng thử 1 lần duy nhất. Vui lòng đăng ký gói cước 1 tháng, 3 tháng, 6 tháng hoặc 1 năm để tiếp tục sử dụng đầy đủ tính năng!',
            style: const TextStyle(fontSize: 13, height: 1.5, color: WebTheme.textBody),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WebTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Xem các gói cước', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final success = await googleAuth.startTrial(); // Bắt đầu tính giờ đếm ngược từ khoảnh khắc người dùng chọn gói!
    if (!success || !mounted) return;

    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusLg)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: WebTheme.emerald, size: 28),
            SizedBox(width: 8),
            Text('Kích hoạt dùng thử thành công!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chúc mừng ${googleAuth.displayName}!\n\n'
              'Tài khoản Google (${googleAuth.email}) đã kích hoạt thành công 3 ngày dùng thử miễn phí 100% tính năng.',
              style: const TextStyle(fontSize: 13, height: 1.5, color: WebTheme.textBody),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đồng hồ 72 giờ đã bắt đầu đếm ngược từ lúc này (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}). Hãy trải nghiệm đọc thông báo ngay!',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bắt đầu sử dụng ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openPaymentModal(BuildContext context, Map<String, dynamic> pkg, SystemConfigProvider sysConfig, GoogleAuthProvider googleAuth) {
    if (googleAuth.isLifetime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD97706),
          content: Text('👑 Bạn đã sở hữu Gói Vĩnh Viễn VIP nhất hệ thống, không cần mua thêm gói nào khác!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final randomSuffix = (1000 + Random().nextInt(9000)).toString();
    final orderCode = 'AB${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}$randomSuffix';
    final amount = pkg['price'] as int;
    final bankCode = sysConfig.bankCode;
    final bankAcc = sysConfig.bankAcc;
    final bankName = sysConfig.bankName;

    final qrUrl = 'https://img.vietqr.io/image/$bankCode-$bankAcc-compact2.png?amount=$amount&addInfo=$orderCode&accountName=${Uri.encodeComponent(bankName)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PaymentModalSheet(
        pkg: pkg,
        orderCode: orderCode,
        amount: amount,
        bankCode: bankCode,
        bankAcc: bankAcc,
        bankName: bankName,
        qrUrl: qrUrl,
        customerName: googleAuth.displayName,
        customerEmail: googleAuth.email,
        onPaymentSuccess: () {
          Navigator.pop(sheetContext);
          final days = pkg['days'] as int;
          googleAuth.activatePackage(pkg['name'], days);
          final isLifetime = pkg['key'] == 'lifetime';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: WebTheme.emerald,
              content: Text(isLifetime
                  ? '👑 Chúc mừng ${googleAuth.displayName}! Gói Vĩnh Viễn Trọn Đời đã được kích hoạt thành công!'
                  : '🎉 Chúc mừng ${googleAuth.displayName}! Gói ${pkg['name']} đã được kích hoạt và cộng dồn thời hạn thành công!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sysConfig = context.watch<SystemConfigProvider>();
    final googleAuth = context.watch<GoogleAuthProvider>();
    final packages = _getPackages(sysConfig, googleAuth);

    final currentSelectedPkg = packages.firstWhere(
      (p) => p['key'] == _selectedPackageKey,
      orElse: () {
        final fallback = packages.firstWhere(
          (p) => p['key'] == '1y' || p['key'] == '1year',
          orElse: () => packages.firstWhere((p) => (p['price'] as int? ?? 0) > 0, orElse: () => packages.first),
        );
        _selectedPackageKey = fallback['key'];
        return fallback;
      },
    );

    return Scaffold(
      backgroundColor: WebTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: WebTheme.textHeading),
          tooltip: 'Quay lại Trang chủ',
          onPressed: () {
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Đăng ký & Nâng cấp gói',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: WebTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              if (widget.onBackToHome != null) {
                widget.onBackToHome!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER BRANDING & TRẠNG THÁI BẢN QUYỀN + ĐẾM NGƯỢC
              _buildHeaderCard(sysConfig, googleAuth),

              const SizedBox(height: 14),

              // 2. KHU VỰC 100% TÀI KHOẢN GOOGLE (THAY THẾ FORM THỦ CÔNG)
              _buildGoogleAccountSection(googleAuth),

              const SizedBox(height: 16),

              // NẾU TÀI KHOẢN ĐÃ SỞ HỮU GÓI VĨNH VIỄN TRỌN ĐỜI -> KHÓA KHÔNG CHO MUA NỮA
              if (googleAuth.isLifetime) ...[
                const SizedBox(height: 12),
                _buildLifetimeLockedCard(googleAuth),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 16),
                // BANNER THÔNG BÁO MÃ GIẢM GIÁ ĐẾM NGƯỢC TỪ ADMIN CHO TÀI KHOẢN MỚI
                _buildWelcomeDiscountBanner(sysConfig, googleAuth),
                const SizedBox(height: 14),

                // 3. TIÊU ĐỀ CHỌN GÓI THỜI HẠN & NÚT BẢNG CÁC GÓI
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: WebTheme.primaryBg,
                              borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                            ),
                            child: const Icon(Icons.price_change_rounded, color: WebTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Chọn gói thời hạn (Tháng / Năm)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: WebTheme.textHeading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showAllSubscriptionPackagesModal(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WebTheme.primaryBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: WebTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.table_chart_rounded, size: 13, color: WebTheme.primary),
                            SizedBox(width: 4),
                            Text(
                              'Bảng các gói',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bản quyền tự động kích hoạt cho tài khoản Google hiện tại. Đăng ký thêm sẽ tự động cộng dồn thời gian dùng!',
                  style: TextStyle(fontSize: 11, color: WebTheme.textMuted),
                ),

                const SizedBox(height: 12),

                // 4. DANH SÁCH 6 GÓI DỊCH VỤ CHUẨN WEB
                ...packages.map((pkg) => _buildPackageCard(pkg, googleAuth)),

                const SizedBox(height: 16),

                // 5. NÚT KÍCH HOẠT / THANH TOÁN VIETQR
                _buildActionSubmitButton(currentSelectedPkg, sysConfig, googleAuth),

                const SizedBox(height: 16),
              ],

              // 6. CAM KẾT CHẤT LƯỢNG & TÍNH NĂNG
              _buildFeatureHighlights(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // VOUCHER TÂN THỦ ĐẾM NGƯỢC THỜI GIAN THỰC TỪ ADMIN (1 NGÀY, 2 NGÀY, 3 NGÀY...)
  Widget _buildWelcomeDiscountBanner(SystemConfigProvider sysConfig, GoogleAuthProvider googleAuth) {
    final coupon = sysConfig.getBestCouponForUser(
      userCreatedAt: googleAuth.createdAt,
      userEmail: googleAuth.email,
    ) ?? {
      'code': 'NGUOIMOI',
      'discountPercent': 10,
      'discountAmount': 0,
      'targetAudience': 'NEW_3DAYS',
      'description': 'Giảm 10% cho thành viên mới trong vòng 3 ngày',
    };

    final now = DateTime.now();
    final target = (coupon['targetAudience'] ?? 'NEW_3DAYS').toString().toUpperCase();
    int targetHours = 72;
    String targetDurationBadge = '3 NGÀY';

    if (target == 'NEW_1DAY') {
      targetHours = 24;
      targetDurationBadge = '24 GIỜ';
    } else if (target == 'NEW_2DAYS') {
      targetHours = 48;
      targetDurationBadge = '48 GIỜ';
    } else if (target == 'NEW_3DAYS') {
      targetHours = 72;
      targetDurationBadge = '3 NGÀY';
    } else {
      targetHours = 72;
      targetDurationBadge = 'ƯU ĐÃI';
    }

    // Đếm ngược chính xác theo giờ cài đặt từ thời điểm tạo tài khoản (không phải lúc đăng nhập)
    final startTime = googleAuth.trialStartedAt ?? googleAuth.createdAt;
    final expireAt = startTime.add(Duration(hours: targetHours));
    final rawRemaining = expireAt.difference(now);
    final remaining = rawRemaining > Duration(hours: targetHours)
        ? Duration(hours: targetHours)
        : (rawRemaining.isNegative ? Duration.zero : rawRemaining);
    final isExpired = rawRemaining.isNegative;

    if (isExpired && googleAuth.hasUsedTrial) {
      return const SizedBox.shrink();
    }

    final days = isExpired ? 0 : remaining.inDays;
    final hours = isExpired ? 0 : remaining.inHours % 24;
    final minutes = isExpired ? 0 : remaining.inMinutes % 60;
    final seconds = isExpired ? 0 : remaining.inSeconds % 60;

    final createdDateStr =
        '${googleAuth.createdAt.hour.toString().padLeft(2, '0')}:${googleAuth.createdAt.minute.toString().padLeft(2, '0')} ngày ${googleAuth.createdAt.day.toString().padLeft(2, '0')}/${googleAuth.createdAt.month.toString().padLeft(2, '0')}';

    final int couponPct = (coupon['discountPercent'] as num?)?.toInt() ?? 10;
    final int couponAmt = (coupon['discountAmount'] as num?)?.toInt() ?? 0;
    final String discountTitle = couponPct > 0
        ? 'VOUCHER TÂN THỦ GIẢM $couponPct%'
        : 'VOUCHER GIẢM ${CurrencyFormatter.formatVND(couponAmt.toDouble())}';
    final String discountDesc = couponPct > 0
        ? 'Đã trừ thẳng $couponPct% vào giá tất cả các gói. Bấm kích hoạt nhận ngay giá ưu đãi!'
        : 'Đã trừ thẳng ${CurrencyFormatter.formatVND(couponAmt.toDouble())} vào giá tất cả các gói. Bấm kích hoạt nhận ngay!';
    final String couponCode = (coupon['code'] ?? 'NGUOIMOI').toString().toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF2F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(WebTheme.radiusLg),
        border: Border.all(color: const Color(0xFFF97316), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Voucher
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFE11D48)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              discountTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF9A3412),
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              targetDurationBadge,
                              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tính từ lúc tạo tài khoản ($createdDateStr) • Áp dụng tất cả các gói',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Khung đếm ngược thời gian thực với 4 ô số
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 6),
                    Text(
                      'Thời hạn ưu đãi còn lại:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildVoucherDigitBox(days.toString().padLeft(2, '0'), 'ngày'),
                    _buildVoucherDigitSeparator(),
                    _buildVoucherDigitBox(hours.toString().padLeft(2, '0'), 'giờ'),
                    _buildVoucherDigitSeparator(),
                    _buildVoucherDigitBox(minutes.toString().padLeft(2, '0'), 'phút'),
                    _buildVoucherDigitSeparator(),
                    _buildVoucherDigitBox(seconds.toString().padLeft(2, '0'), 'giây', isSeconds: true),
                  ],
                ),
              ],
            ),
          ),

          // Footer thông báo áp dụng
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    discountDesc,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                  ),
                  child: Text(
                    'MÃ: $couponCode',
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          ),

          // NÚT HÀNH ĐỘNG MARKETING TỨC THÌ
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
                label: Text(
                  '⚡ ÁP DỤNG MÃ $couponCode & CHỌN GÓI 1 NĂM (GIẢM $couponPct%)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedPackageKey = '1year';
                  });
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setString('auto_apply_coupon_code', couponCode);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Đã chọn mã $couponCode (-$couponPct%) và gói 1 Năm!'),
                      backgroundColor: const Color(0xFFEA580C),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherDigitBox(String val, String lbl, {bool isSeconds = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: isSeconds ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSeconds ? const Color(0xFFFCA5A5) : const Color(0xFFFDBA74),
              width: 0.9,
            ),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isSeconds ? const Color(0xFFDC2626) : const Color(0xFF9A3412),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          lbl,
          style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
        ),
      ],
    );
  }

  Widget _buildVoucherDigitSeparator() {
    return const Padding(
      padding: EdgeInsets.only(left: 3, right: 3, bottom: 8),
      child: Text(
        ':',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFC2410C)),
      ),
    );
  }

  // HEADER CARD VỚI ĐẾM NGƯỢC THỜI GIAN THỰC
  Widget _buildHeaderCard(SystemConfigProvider sysConfig, GoogleAuthProvider googleAuth) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: WebTheme.cardDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    color: WebTheme.primary,
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sysConfig.brandName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: WebTheme.textHeading,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: WebTheme.badgeDecoration(
                            bgColor: WebTheme.emeraldLight,
                            borderColor: WebTheme.emerald,
                          ),
                          child: const Text(
                            'Chính hãng',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: WebTheme.emerald),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sysConfig.brandSlogan,
                      style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: WebTheme.cardBorder),
          const SizedBox(height: 10),

          // DÒNG TRẠNG THÁI BẢN QUYỀN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    googleAuth.isActivated
                        ? Icons.verified_user_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: googleAuth.isActivated ? WebTheme.emerald : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    googleAuth.isActivated
                        ? 'Đang dùng: ${googleAuth.activePackageName}'
                        : 'Trạng thái: Chưa kích hoạt gói',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: googleAuth.isActivated ? WebTheme.emerald : const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              Text(
                googleAuth.isActivated
                    ? (googleAuth.isLifetime
                        ? 'HSD: Vĩnh viễn (Trọn đời)'
                        : 'HSD: ${googleAuth.expireDate.day}/${googleAuth.expireDate.month}/${googleAuth.expireDate.year}')
                    : 'Tạo: ${googleAuth.createdAt.hour.toString().padLeft(2, '0')}:${googleAuth.createdAt.minute.toString().padLeft(2, '0')} (${googleAuth.createdAt.day}/${googleAuth.createdAt.month})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
              ),
            ],
          ),

          // KHỐI ĐẾM NGƯỢC THỜI GIAN THỰC HOẶC KHỐI KÍCH HOẠT DÙNG THỬ
          const SizedBox(height: 10),
          if (googleAuth.isLifetime)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.all_inclusive_rounded,
                      size: 18,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👑 BẢN QUYỀN VĨNH VIỄN TRỌN ĐỜI (VIP)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFBBF24),
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Đặc quyền VIP cao nhất • Sử dụng mãi mãi không giới hạn thời gian',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TRỌN ĐỜI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (googleAuth.isActivated && !googleAuth.activePackageName.contains('Dùng thử'))
            // GÓI TRẢ PHÍ (1 THÁNG, 3 THÁNG, 6 THÁNG, 1 NĂM... CÓ CỘNG DỒN)
            Builder(
              builder: (context) {
                final remaining = googleAuth.expireDate.difference(DateTime.now());
                final isExpired = remaining.isNegative;
                final days = isExpired ? 0 : remaining.inDays;
                final hours = isExpired ? 0 : remaining.inHours % 24;
                final minutes = isExpired ? 0 : remaining.inMinutes % 60;
                final seconds = isExpired ? 0 : remaining.inSeconds % 60;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isExpired
                          ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
                          : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                    border: Border.all(
                      color: isExpired ? const Color(0xFFFECACA) : const Color(0xFF86EFAC),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: (isExpired ? const Color(0xFFDC2626) : WebTheme.emerald).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpired ? Icons.warning_amber_rounded : Icons.timer_rounded,
                          size: 16,
                          color: isExpired ? const Color(0xFFDC2626) : WebTheme.emerald,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isExpired ? 'Gói bản quyền đã hết hạn:' : 'Thời hạn bản quyền còn lại:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isExpired ? const Color(0xFFDC2626) : const Color(0xFF166534),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isExpired
                                  ? 'Vui lòng gia hạn thêm gói'
                                  : 'HSD: ${googleAuth.expireDate.day}/${googleAuth.expireDate.month}/${googleAuth.expireDate.year}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isExpired ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                              ),
                            ),
                            if (!isExpired)
                              const Text(
                                '(Cộng dồn khi mua thêm)',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Hộp 4 ô số đếm ngược thời gian thực
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTimerDigitBox(days.toString().padLeft(2, '0'), 'ngày'),
                          _buildTimerSeparator(),
                          _buildTimerDigitBox(hours.toString().padLeft(2, '0'), 'giờ'),
                          _buildTimerSeparator(),
                          _buildTimerDigitBox(minutes.toString().padLeft(2, '0'), 'phút'),
                          _buildTimerSeparator(),
                          _buildTimerDigitBox(seconds.toString().padLeft(2, '0'), 'giây', isSeconds: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          else if (googleAuth.isTrialStarted)
            Builder(
              builder: (context) {
                final rawRemaining = googleAuth.expireDate.difference(DateTime.now());
                final remaining = rawRemaining > const Duration(hours: 72)
                    ? const Duration(hours: 72)
                    : (rawRemaining.isNegative ? Duration.zero : rawRemaining);
                final isExpired = rawRemaining.isNegative;
                final days = isExpired ? 0 : remaining.inDays;
                final hours = isExpired ? 0 : remaining.inHours % 24;
                final minutes = isExpired ? 0 : remaining.inMinutes % 60;
                final seconds = isExpired ? 0 : remaining.inSeconds % 60;

                final started = googleAuth.trialStartedAt ?? googleAuth.createdAt;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isExpired ? 'Đã hết hạn 3 ngày dùng thử:' : 'Đếm ngược dùng thử 3 ngày:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isExpired ? const Color(0xFFDC2626) : const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isExpired
                                  ? 'Vui lòng gia hạn gói để tiếp tục'
                                  : 'Bắt đầu: ${started.hour.toString().padLeft(2, '0')}:${started.minute.toString().padLeft(2, '0')} (${started.day}/${started.month})',
                              style: TextStyle(
                                fontSize: 9,
                                color: isExpired ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hộp 4 ô số đếm ngược thời gian thực
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTimerDigitBox(days.toString().padLeft(2, '0'), 'ngày'),
                          _buildTimerSeparator(),
                          _buildTimerDigitBox(hours.toString().padLeft(2, '0'), 'giờ'),
                          _buildTimerSeparator(),
                          _buildTimerDigitBox(minutes.toString().padLeft(2, '0'), 'phút'),
                          _buildTimerSeparator(),
                          _buildTimerDigitBox(seconds.toString().padLeft(2, '0'), 'giây', isSeconds: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          else
            // TRƯỜNG HỢP TÀI KHOẢN MỚI TẠO CHƯA CHỌN GÓI DÙNG THỬ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_empty_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tài khoản tạo lúc ${googleAuth.createdAt.hour.toString().padLeft(2, '0')}:${googleAuth.createdAt.minute.toString().padLeft(2, '0')} (${googleAuth.createdAt.day}/${googleAuth.createdAt.month})',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                            const Text(
                              'Chọn gói dùng thử 3 ngày để bắt đầu đếm ngược thời gian!',
                              style: TextStyle(fontSize: 9.5, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flash_on_rounded, size: 14, color: Colors.white),
                          label: const Text(
                            'Kích hoạt dùng thử ngay (Bắt đầu đếm ngược)',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _handleActivateTrial(googleAuth),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => _showAllSubscriptionPackagesModal(context),
                        child: const Text(
                          'Bảng các gói',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
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

  Widget _buildTimerDigitBox(String value, String label, {bool isSeconds = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSeconds ? const Color(0xFFE11D48) : const Color(0xFFFCD34D),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isSeconds ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Color(0xFF92400E),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSeparator() {
    return Padding(
      padding: const EdgeInsets.only(left: 3, right: 3, bottom: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF92400E).withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // KHU VỰC 100% TÀI KHOẢN GOOGLE
  Widget _buildGoogleAccountSection(GoogleAuthProvider googleAuth) {
    if (!googleAuth.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: WebTheme.cardDecoration(),
        child: Column(
          children: [
            const GoogleLogo(size: 32),
            const SizedBox(height: 10),
            const Text(
              'Đăng nhập bằng tài khoản Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tự động nhận 3 ngày dùng thử miễn phí 100% tính năng khi đăng nhập Google lần đầu trên thiết bị.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: WebTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                ),
                onPressed: () => _showGoogleAccountPicker(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLogo(size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Tiếp tục với Google Account',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  GoogleLogo(size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tài khoản Google liên kết (100%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: WebTheme.textHeading,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: WebTheme.badgeDecoration(
                  bgColor: WebTheme.emeraldLight,
                  borderColor: WebTheme.emerald,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: WebTheme.emerald, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Xác thực 100%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: WebTheme.emerald),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(WebTheme.radiusMd),
              border: Border.all(color: WebTheme.cardBorder),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF4285F4),
                      child: Text(
                        googleAuth.avatarInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.white,
                        child: GoogleLogo(size: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              googleAuth.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: WebTheme.textHeading,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF4285F4)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        googleAuth.email,
                        style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 12, color: WebTheme.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${googleAuth.deviceName} • v${googleAuth.appVersion}',
                              style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                InkWell(
                  onTap: () => _showGoogleAccountPicker(context),
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync_alt_rounded, size: 16, color: WebTheme.primary),
                        SizedBox(height: 2),
                        Text(
                          'Đổi nick',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: WebTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shopController,
                  style: const TextStyle(fontSize: 12, color: WebTheme.textHeading),
                  onChanged: (val) => googleAuth.setShopName(val),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Tên cửa hàng / Kinh doanh (Loa chào quán)',
                    labelStyle: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                    hintText: 'Ví dụ: Tiệm Bánh Mì Kim Anh',
                    hintStyle: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                    prefixIcon: const Icon(Icons.storefront_rounded, size: 18, color: WebTheme.primary),
                    prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                      borderSide: const BorderSide(color: WebTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                      borderSide: const BorderSide(color: WebTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                      borderSide: const BorderSide(color: WebTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // THẺ KHÓA KHI ĐÃ SỞ HỮU GÓI VĨNH VIỄN TRỌN ĐỜI (VIP CAO NHẤT)
  Widget _buildLifetimeLockedCard(GoogleAuthProvider googleAuth) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(WebTheme.radiusLg),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BẢN QUYỀN VĨNH VIỄN TRỌN ĐỜI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFBBF24),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tài khoản đã đạt cấp độ VIP cao nhất',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Text(
                  'ĐÃ KHÓA MUA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(WebTheme.radiusSm),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👑 Bạn đã sở hữu gói Vĩnh Viễn! Hệ thống tự động khóa tính năng mua gói vì tài khoản của bạn đã có đặc quyền trọn đời cao nhất.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFF1F5F9), height: 1.4, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                _LifetimeFeatureRow(text: 'Sử dụng trọn đời vô thời hạn cho tài khoản Google hiện tại'),
                SizedBox(height: 5),
                _LifetimeFeatureRow(text: 'Lắng nghe & đọc biến động từ tất cả 65+ ứng dụng ngân hàng & ví điện tử'),
                SizedBox(height: 5),
                _LifetimeFeatureRow(text: 'Miễn phí 100% cập nhật tính năng mới & hỗ trợ kỹ thuật ưu tiên'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // THẺ GÓI CƯỚC
  Widget _buildPackageCard(Map<String, dynamic> pkg, GoogleAuthProvider googleAuth) {
    final isSelected = _selectedPackageKey == pkg['key'];
    final isFeatured = pkg['isFeatured'] as bool;
    final isTrial = pkg['key'] == 'trial';
    final activePkg = googleAuth.activePackageName.toLowerCase();
    final pkgName = (pkg['name'] as String).toLowerCase();
    final pkgKey = (pkg['key'] as String).toLowerCase();

    // Nhận diện chính xác gói người dùng đang kích hoạt sử dụng
    final isCurrentActivePackage = googleAuth.isActivated && !googleAuth.isExpired && (
      (googleAuth.isLifetime && (pkgKey == 'lifetime' || pkgName.contains('vĩnh viễn'))) ||
      (activePkg.contains('1 năm') && (pkgKey == '1year' || pkgKey == '1y' || pkgName.contains('1 năm'))) ||
      (activePkg.contains('9 tháng') && (pkgKey == '9month' || pkgName.contains('9 tháng'))) ||
      (activePkg.contains('6 tháng') && (pkgKey == '6month' || pkgName.contains('6 tháng'))) ||
      (activePkg.contains('3 tháng') && (pkgKey == '3month' || pkgName.contains('3 tháng'))) ||
      (activePkg.contains('1 tháng') && (pkgKey == '1month' || pkgName.contains('1 tháng'))) ||
      (activePkg.contains('dùng thử') && isTrial)
    );

    String? customBadge = pkg['badge'];
    if (isCurrentActivePackage) {
      customBadge = 'Đang sử dụng ✓';
    } else if (isTrial) {
      if (googleAuth.isActivated && !googleAuth.activePackageName.contains('Dùng thử')) {
        customBadge = 'Đã hoàn thành dùng thử';
      } else if (googleAuth.isExpired && googleAuth.activePackageName.contains('Dùng thử')) {
        customBadge = 'Đã hết hạn dùng thử';
      } else if (googleAuth.isTrialStarted) {
        customBadge = 'Đang đếm ngược ⏳';
      } else {
        customBadge = 'Chưa kích hoạt • Chọn để đếm ngược';
      }
    }

    final String voucherTag = (pkg['voucherTag'] ?? '-10% VOUCHER').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentActivePackage
            ? const Color(0xFFF0FDF4)
            : (isSelected ? WebTheme.primaryBg : Colors.white),
        borderRadius: BorderRadius.circular(WebTheme.radiusMd),
        border: Border.all(
          color: isCurrentActivePackage
              ? WebTheme.emerald
              : (isSelected
                  ? WebTheme.primary
                  : (isFeatured ? const Color(0xFFBAE6FD) : WebTheme.cardBorder)),
          width: (isCurrentActivePackage || isSelected) ? 1.8 : 1,
        ),
        boxShadow: [
          if (isSelected || isFeatured || isCurrentActivePackage)
            BoxShadow(
              color: (isCurrentActivePackage ? WebTheme.emerald : WebTheme.primary).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(WebTheme.radiusMd),
          onTap: () {
            setState(() {
              _selectedPackageKey = pkg['key'];
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentActivePackage
                        ? const Color(0xFFDCFCE7)
                        : (isSelected ? WebTheme.primaryLight : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  ),
                  child: Icon(
                    pkg['icon'] as IconData,
                    size: 22,
                    color: isCurrentActivePackage
                        ? WebTheme.emerald
                        : (isSelected ? WebTheme.primary : WebTheme.textMuted),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            pkg['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCurrentActivePackage
                                  ? const Color(0xFF166534)
                                  : (isSelected ? WebTheme.primaryDark : WebTheme.textHeading),
                            ),
                          ),
                          if (customBadge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrentActivePackage
                                    ? const Color(0xFFDCFCE7)
                                    : (isFeatured
                                        ? const Color(0xFFFEF3C7)
                                        : (isTrial ? const Color(0xFFF1F5F9) : WebTheme.emeraldLight)),
                                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                                border: Border.all(
                                  color: isCurrentActivePackage
                                      ? const Color(0xFF16A34A)
                                      : (isFeatured
                                          ? const Color(0xFFF59E0B)
                                          : (isTrial ? const Color(0xFFCBD5E1) : WebTheme.emerald)),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                customBadge,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrentActivePackage
                                      ? const Color(0xFF15803D)
                                      : ((isFeatured || (isTrial && customBadge.contains('đếm ngược')))
                                          ? const Color(0xFFB45309)
                                          : (isTrial ? const Color(0xFF64748B) : WebTheme.emerald)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pkg['desc'],
                        style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pkg['commission'] != null && (pkg['commission'] as num) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.card_giftcard_rounded, size: 12, color: Color(0xFF16A34A)),
                              const SizedBox(width: 3),
                              Text(
                                'Thưởng người giới thiệu: +${CurrencyFormatter.formatVND((pkg['commission'] as num).toDouble())}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (pkg['originalPriceText'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pkg['originalPriceText'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: const Color(0xFFFECACA), width: 0.6),
                              ),
                              child: Text(
                                voucherTag,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      pkg['priceText'],
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: isCurrentActivePackage
                            ? const Color(0xFF15803D)
                            : (isSelected ? WebTheme.primaryDark : WebTheme.emerald),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pkg['duration'],
                      style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? WebTheme.primary : const Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NÚT HÀNH ĐỘNG
  Widget _buildActionSubmitButton(Map<String, dynamic> pkg, SystemConfigProvider sysConfig, GoogleAuthProvider googleAuth) {
    final isTrial = pkg['key'] == 'trial';

    String buttonLabel;
    if (isTrial) {
      if (!googleAuth.isTrialStarted) {
        buttonLabel = 'Kích hoạt 3 ngày dùng thử & Bắt đầu đếm ngược (0đ)';
      } else {
        buttonLabel = 'Gói dùng thử đang chạy đếm ngược (0đ)';
      }
    } else {
      buttonLabel = 'Kích hoạt ${pkg['name']} (${pkg['priceText']})';
    }

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTrial
              ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
              : const [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(WebTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: (isTrial ? const Color(0xFF0F172A) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(WebTheme.radiusMd),
          onTap: () {
            if (!googleAuth.isSignedIn) {
              _showGoogleAccountPicker(context);
              return;
            }

            if (isTrial) {
              _handleActivateTrial(googleAuth);
            } else {
              _openPaymentModal(context, pkg, sysConfig, googleAuth);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTrial ? Icons.auto_awesome_rounded : Icons.workspace_premium_rounded,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CAM KẾT CHẤT LƯỢNG & TÍNH NĂNG
  Widget _buildFeatureHighlights() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quyền lợi khi kích hoạt bản quyền ứng dụng',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
          ),
          const SizedBox(height: 10),
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'Tài khoản Google được đồng bộ bảo mật 100%, đổi máy không lo mất bản quyền'),
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'Hỗ trợ toàn bộ 65+ ứng dụng ngân hàng & ví điện tử tại Việt Nam'),
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'Đọc thông báo nhận tiền tức thì bằng giọng đọc chuẩn (rõ ràng, không vấp)'),
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'Chạy ngầm liên tục 24/7 ngay cả khi tắt màn hình điện thoại'),
          _buildBenefitRow(Icons.check_circle_outline_rounded, 'Tự động kích hoạt bản quyền trong 5 giây sau khi chuyển khoản VietQR'),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: WebTheme.emerald),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, color: WebTheme.textBody, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MODAL THANH TOÁN: 1 LÀ CHUYỂN KHOẢN VIETQR, 2 LÀ THANH TOÁN QUA GOOGLE PAY
// KÈM TÍCH HỢP MÃ GIẢM GIÁ (COUPON MARKETING) TỪ ADMIN
// =========================================================================
class _PaymentModalSheet extends StatefulWidget {
  final Map<String, dynamic> pkg;
  final String orderCode;
  final int amount;
  final String bankCode;
  final String bankAcc;
  final String bankName;
  final String qrUrl;
  final String customerName;
  final String customerEmail;
  final VoidCallback onPaymentSuccess;

  const _PaymentModalSheet({
    required this.pkg,
    required this.orderCode,
    required this.amount,
    required this.bankCode,
    required this.bankAcc,
    required this.bankName,
    required this.qrUrl,
    required this.customerName,
    required this.customerEmail,
    required this.onPaymentSuccess,
  });

  @override
  State<_PaymentModalSheet> createState() => _PaymentModalSheetState();
}

class _PaymentModalSheetState extends State<_PaymentModalSheet> {
  // 0: Chuyển khoản VietQR, 1: Google Pay
  int _selectedPaymentMethod = 0;

  Timer? _countdownTimer;
  Timer? _statusPollingTimer;
  int _secondsLeft = 15 * 60;
  bool _isProcessing = false;

  // Xử lý mã giảm giá Coupon Marketing
  final TextEditingController _couponCtrl = TextEditingController();
  int _discount = 0;
  String _appliedCouponCode = '';
  String _couponMessage = '';
  bool _isApplyingCoupon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SystemConfigProvider>().fetchConfig();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
        // Đồng bộ song song tức thì cấu hình bảo trì từ Admin mỗi 2 giây
        if (_secondsLeft % 2 == 0 && mounted) {
          context.read<SystemConfigProvider>().fetchConfig();
        }
      }
    });

    _registerOrderToBackend();
    _startStatusPolling();

    // Tự động kiểm tra và áp dụng mã giảm giá tân thủ NGUOIMOI nếu có
    SharedPreferences.getInstance().then((prefs) {
      final autoCode = prefs.getString('auto_apply_coupon_code');
      if (mounted && autoCode != null && autoCode.isNotEmpty) {
        _couponCtrl.text = autoCode;
        _applyCoupon();
        prefs.remove('auto_apply_coupon_code');
      }
    });
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    // Tự động kiểm tra tín hiệu thanh toán từ Backend/Ngân hàng mỗi 4 giây
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _selectedPaymentMethod == 0 && !_isProcessing) {
        _checkPaymentStatus(isManual: false);
      }
    });
  }

  Future<void> _registerOrderToBackend() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/admin/orders');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderCode': widget.orderCode,
          'amount': widget.amount,
          'pkg': widget.pkg['name'],
          'description': 'Đăng ký ${widget.pkg['name']} (${widget.customerEmail})',
          'customer': widget.customerEmail,
          'customerName': widget.customerName,
          'customerPhone': widget.customerEmail,
          'status': 'PENDING',
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _countdownTimer?.cancel();
    _couponCtrl.dispose();
    super.dispose();
  }

  String _formatTimer(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get _googlePayFee => (widget.amount * 0.15).round();

  int get _finalPayableAmount {
    if (_selectedPaymentMethod == 1) {
      return (widget.amount + _googlePayFee - _discount).clamp(0, 99999999);
    }
    return (widget.amount - _discount).clamp(0, 99999999);
  }

  String get _dynamicQrUrl {
    return 'https://img.vietqr.io/image/${widget.bankCode}-${widget.bankAcc}-compact2.png?amount=$_finalPayableAmount&addInfo=${widget.orderCode}&accountName=${Uri.encodeComponent(widget.bankName)}';
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isApplyingCoupon = true);

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/coupons/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'amount': widget.amount}),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _appliedCouponCode = code;
          _discount = (data['discount'] as num).toInt();
          _couponMessage = '✓ Áp dụng mã $code thành công! Đã giảm -${CurrencyFormatter.formatVND(_discount.toDouble())}';
        });
      } else {
        _applyLocalCouponFallback(code);
      }
    } catch (_) {
      _applyLocalCouponFallback(code);
    } finally {
      setState(() => _isApplyingCoupon = false);
    }
  }

  void _applyLocalCouponFallback(String code) {
    if (code == 'NGUOIMOI') {
      setState(() {
        _appliedCouponCode = code;
        _discount = (widget.amount * 0.10).round();
        _couponMessage = '✓ Áp dụng mã NGUOIMOI thành công! Giảm ngay 10% (-${CurrencyFormatter.formatVND(_discount.toDouble())})';
      });
    } else if (code == 'AUTOBANK20') {
      setState(() {
        _appliedCouponCode = code;
        _discount = (widget.amount * 0.20).round();
        _couponMessage = '✓ Áp dụng mã $code thành công! Giảm 20% (-${CurrencyFormatter.formatVND(_discount.toDouble())})';
      });
    } else if (code == 'TET2026') {
      setState(() {
        _appliedCouponCode = code;
        _discount = (widget.amount * 0.30).round();
        _couponMessage = '✓ Áp dụng mã $code thành công! Giảm 30% (-${CurrencyFormatter.formatVND(_discount.toDouble())})';
      });
    } else if (code == 'VIP50K' || code == 'VIPPRO') {
      setState(() {
        _appliedCouponCode = code;
        _discount = 50000;
        _couponMessage = '✓ Áp dụng mã $code thành công! Giảm ngay 50.000đ trực tiếp';
      });
    } else {
      setState(() {
        _appliedCouponCode = '';
        _discount = 0;
        _couponMessage = 'Mã giảm giá không hợp lệ hoặc đã hết hạn.';
      });
    }
  }

  /// Kiểm tra trạng thái đơn hàng thật từ server (chỉ kích hoạt khi có tín hiệu tiền về thành công)
  Future<void> _checkPaymentStatus({bool isManual = false}) async {
    if (_isProcessing) return;
    if (isManual) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      final statusUri = Uri.parse('${AppConfig.apiBaseUrl}/orders/${widget.orderCode}/status');
      final res = await http.get(statusUri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bool isPaid = data['isPaid'] == true ||
            data['status'] == 'PAID' ||
            data['status'] == 'OVERPAID' ||
            data['status'] == 'APPROVED';

        if (isPaid) {
          _statusPollingTimer?.cancel();
          _countdownTimer?.cancel();

          if (mounted) {
            setState(() {
              _isProcessing = false;
            });

            // Đọc giọng nói chúc mừng
            TtsService().speakTestFeedback(
              'Tài khoản ${widget.customerEmail} đã nhận được tiền từ ngân hàng và nâng cấp thành công lên gói ${widget.pkg['name']}!'
            );

            // Hiển thị Popup chúc mừng đã nhận được tín hiệu bank và nâng cấp ngay
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dCtx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.all(22),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'THANH TOÁN THÀNH CÔNG!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Text(
                        'Tín hiệu Bank: ĐÃ NHẬN TIỀN TỰ ĐỘNG',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tài khoản: ${widget.customerEmail}\nĐã nâng cấp lên gói: ${widget.pkg['name']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(dCtx);
                        },
                        child: const Text('Bắt đầu sử dụng ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (mounted) {
              widget.onPaymentSuccess();
            }
          }
          return;
        }
      }

      if (isManual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF334155),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chưa nhận được tín hiệu tiền vào cho mã ${widget.orderCode}. Vui lòng chuyển khoản đúng nội dung, hệ thống sẽ tự động kích hoạt.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (isManual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Lỗi kiểm tra trạng thái: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (isManual && mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleGooglePayCheckout() async {
    final sysConfig = context.read<SystemConfigProvider>();
    if (sysConfig.googlePayMaintenance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(sysConfig.googlePayMaintenanceMsg),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Hiển thị popup xác thực Google Pay 1 chạm bảo mật
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoogleLogo(size: 24),
                SizedBox(width: 8),
                Text('Google Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4285F4)),
            const SizedBox(height: 16),
            const Text(
              'Đang xử lý giao dịch qua Google Play...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
            ),
            const SizedBox(height: 4),
            Text(
              'Thanh toán an toàn 1 chạm: ${CurrencyFormatter.formatVND(_finalPayableAmount.toDouble())}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: WebTheme.textMuted),
            ),
          ],
        ),
      ),
    );

    // Chờ 1.5 giây mô phỏng xác thực thanh toán của Google Play Console
    await Future.delayed(const Duration(milliseconds: 1500));

    // Đóng popup Google Pay
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Kiểm tra trạng thái đơn hàng
    await _checkPaymentStatus(isManual: true);
  }

  @override
  Widget build(BuildContext context) {
    final sysConfig = context.watch<SystemConfigProvider>();
    final bool isGpayMaintenance = sysConfig.googlePayMaintenance;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pkg['name'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tài khoản: ${widget.customerEmail}',
                      style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: WebTheme.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 1. THANH CHỌN PHƯƠNG THỨC THANH TOÁN (1: VIETQR, 2: GOOGLE PAY)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context.read<SystemConfigProvider>().fetchConfig();
                        setState(() => _selectedPaymentMethod = 0);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedPaymentMethod == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedPaymentMethod == 0
                              ? const [BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 16,
                              color: _selectedPaymentMethod == 0 ? WebTheme.primary : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '1. Chuyển khoản VietQR',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _selectedPaymentMethod == 0 ? FontWeight.bold : FontWeight.w600,
                                color: _selectedPaymentMethod == 0 ? WebTheme.primaryDark : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context.read<SystemConfigProvider>().fetchConfig();
                        setState(() => _selectedPaymentMethod = 1);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedPaymentMethod == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedPaymentMethod == 1
                              ? const [BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GoogleLogo(size: 14),
                            const SizedBox(width: 6),
                            Text(
                              isGpayMaintenance ? '2. Google Pay (Bảo trì)' : '2. Google Pay (+15%)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _selectedPaymentMethod == 1 ? FontWeight.bold : FontWeight.w600,
                                color: isGpayMaintenance
                                    ? const Color(0xFFDC2626)
                                    : (_selectedPaymentMethod == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                              ),
                            ),
                            if (isGpayMaintenance) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.build_rounded, size: 11, color: Color(0xFFDC2626)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. KHUNG NHẬP MÃ GIẢM GIÁ (MARKETING COUPON)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_num_outlined, size: 14, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      const Text(
                        'MÃ GIẢM GIÁ (ÁP DỤNG MÃ AUTOBANK20, TET2026, VIP50K)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Nhập mã giảm giá...',
                            hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: _isApplyingCoupon ? null : _applyCoupon,
                        child: _isApplyingCoupon
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Áp dụng', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_couponMessage.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      _couponMessage,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _discount > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. NỘI DUNG THANH TOÁN THEO PHƯƠNG THỨC ĐƯỢC CHỌN
            if (_selectedPaymentMethod == 0) ...[
              // === TAB 1: CHUYỂN KHOẢN VIETQR ===
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                  border: Border.all(color: WebTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                      child: Image.network(
                        _dynamicQrUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: const Icon(Icons.qr_code_2_rounded, size: 90, color: WebTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thời gian giữ mã: ${_formatTimer(_secondsLeft)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  border: Border.all(color: WebTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildPaymentRow('Ngân hàng nhận:', widget.bankCode, null),
                    const Divider(height: 10, color: WebTheme.cardBorder),
                    _buildPaymentRow('Số tài khoản nhận:', widget.bankAcc, () => _copyToClipboard(context, widget.bankAcc, 'Số tài khoản Admin')),
                    const Divider(height: 10, color: WebTheme.cardBorder),
                    _buildPaymentRow('Chủ tài khoản nhận:', widget.bankName, null),
                    const Divider(height: 10, color: WebTheme.cardBorder),
                    if (widget.pkg['originalPrice'] != null) ...[
                      _buildPaymentRow('Giá gốc niêm yết:', widget.pkg['originalPriceText'] ?? '', null),
                      const Divider(height: 10, color: WebTheme.cardBorder),
                      _buildPaymentRow('Voucher tân thủ (3 ngày):', '-10% (Đã trừ thẳng vào gói)', null, isDiscount: true),
                      const Divider(height: 10, color: WebTheme.cardBorder),
                    ],
                    if (_discount > 0) ...[
                      _buildPaymentRow('Giá gốc:', CurrencyFormatter.formatVND(widget.amount.toDouble()), null),
                      const Divider(height: 10, color: WebTheme.cardBorder),
                      _buildPaymentRow(_appliedCouponCode.isNotEmpty ? 'Mã Coupon ($_appliedCouponCode):' : 'Giảm giá Coupon:', '-${CurrencyFormatter.formatVND(_discount.toDouble())}', null, isDiscount: true),
                      const Divider(height: 10, color: WebTheme.cardBorder),
                    ],
                    _buildPaymentRow('Số tiền cần chuyển:', CurrencyFormatter.formatVND(_finalPayableAmount.toDouble()), () => _copyToClipboard(context, _finalPayableAmount.toString(), 'Số tiền'), isHighlight: true),
                    const Divider(height: 10, color: WebTheme.cardBorder),
                    _buildPaymentRow('Nội dung chuyển khoản:', widget.orderCode, () => _copyToClipboard(context, widget.orderCode, 'Nội dung chuyển khoản'), isOrderCode: true),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // HỘP THÔNG BÁO TÍN HIỆU THANH TOÁN TỰ ĐỘNG
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF16A34A)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đang chờ nhận tiền chuyển khoản... Hệ thống sẽ tự động kích hoạt gói ngay khi có tín hiệu tiền về thành công.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                    backgroundColor: const Color(0xFFF0F9FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                  ),
                  onPressed: _isProcessing ? null : () => _checkPaymentStatus(isManual: true),
                  icon: _isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)))
                      : const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF0284C7)),
                  label: Text(
                    _isProcessing ? 'Đang kiểm tra tín hiệu tự động...' : 'Kiểm tra giao dịch tự động',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ),
              ),
            ] else ...[
              // === TAB 2: THANH TOÁN GOOGLE PAY ===
              if (isGpayMaintenance)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                    border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.build_circle_rounded, color: Color(0xFFDC2626), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cổng Google Pay Đang Tạm Bảo Trì',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sysConfig.googlePayMaintenanceMsg,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isGpayMaintenance ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                  border: Border.all(color: isGpayMaintenance ? const Color(0xFFFECDD3) : const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GoogleLogo(size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Google Pay / In-App Purchase',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isGpayMaintenance ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isGpayMaintenance ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isGpayMaintenance ? 'ĐANG BẢO TRÌ' : '+15% Phí Google Play',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isGpayMaintenance ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentRow('Gói bản quyền:', widget.pkg['name'], null),
                    const Divider(height: 10, color: Color(0xFFE2E8F0)),
                    _buildPaymentRow('Tài khoản Google:', widget.customerEmail, null),
                    const Divider(height: 10, color: Color(0xFFE2E8F0)),
                    _buildPaymentRow('Giá gốc niêm yết:', CurrencyFormatter.formatVND(widget.amount.toDouble()), null),
                    const Divider(height: 10, color: Color(0xFFE2E8F0)),
                    _buildPaymentRow(
                      'Phí dịch vụ Google Play (+15%):',
                      '+${CurrencyFormatter.formatVND(_googlePayFee.toDouble())}',
                      null,
                    ),
                    const Divider(height: 10, color: Color(0xFFE2E8F0)),
                    if (_discount > 0) ...[
                      _buildPaymentRow('Giảm giá Coupon:', '-${CurrencyFormatter.formatVND(_discount.toDouble())}', null, isDiscount: true),
                      const Divider(height: 10, color: Color(0xFFE2E8F0)),
                    ],
                    _buildPaymentRow(
                      'Tổng thanh toán qua Google Pay:',
                      CurrencyFormatter.formatVND(_finalPayableAmount.toDouble()),
                      null,
                      isHighlight: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (isGpayMaintenance) ...[
                // Khi bật bảo trì: Khóa thanh toán GG, hướng dẫn thanh toán qua VietQR
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => setState(() => _selectedPaymentMethod = 0),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text(
                      'Chuyển sang Chuyển khoản VietQR (Hoạt động 100%)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '⚠️ Cổng thanh toán Google Pay tạm khóa theo cấu hình Quản trị viên (Admin)',
                    style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                  ),
                ),
              ] else ...[
                // Nút Google Pay chuẩn đen sang trọng khi hoạt động bình thường
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: _isProcessing ? null : _handleGooglePayCheckout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GoogleLogo(size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Pay với Google Pay (${CurrencyFormatter.formatVND(_finalPayableAmount.toDouble())})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Thanh toán an toàn 1 chạm bảo vệ bởi Google Play Console & MBBank',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value,
    VoidCallback? onCopy, {
    bool isHighlight = false,
    bool isOrderCode = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: WebTheme.textMuted)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDiscount
                    ? const Color(0xFF16A34A)
                    : (isOrderCode
                        ? const Color(0xFFE11D48)
                        : (isHighlight ? WebTheme.primary : WebTheme.textHeading)),
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Chép', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: WebTheme.primaryDark)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _LifetimeFeatureRow extends StatelessWidget {
  final String text;
  const _LifetimeFeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), height: 1.3),
          ),
        ),
      ],
    );
  }
}

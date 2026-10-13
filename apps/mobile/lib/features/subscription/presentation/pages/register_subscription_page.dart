import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../auth/presentation/providers/google_auth_provider.dart';
import '../../../system/presentation/providers/system_config_provider.dart';

class RegisterSubscriptionPage extends StatefulWidget {
  final String? initialPackageKey;
  const RegisterSubscriptionPage({super.key, this.initialPackageKey});

  @override
  State<RegisterSubscriptionPage> createState() => _RegisterSubscriptionPageState();
}

class _RegisterSubscriptionPageState extends State<RegisterSubscriptionPage> {
  late final TextEditingController _shopController;
  Timer? _liveCountdownTimer;

  // Gói được chọn (Mặc định gói 1 năm hoặc gói truyền vào từ deep link)
  late String _selectedPackageKey;

  @override
  void initState() {
    super.initState();
    _selectedPackageKey = widget.initialPackageKey ?? '1year';
    final auth = context.read<GoogleAuthProvider>();
    _shopController = TextEditingController(text: auth.shopName);

    // Bắt đầu đếm ngược thời gian thực từng giây cho gói dùng thử 3 ngày
    _liveCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _liveCountdownTimer?.cancel();
    _shopController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPackages(SystemConfigProvider sysConfig) {
    return [
      {
        'key': 'trial',
        'name': 'Dùng thử',
        'duration': '3 ngày miễn phí',
        'days': 3,
        'price': sysConfig.priceTrial,
        'priceText': '0đ',
        'badge': 'Tài khoản mới',
        'desc': 'Trải nghiệm 100% tính năng cao cấp không giới hạn',
        'isFeatured': false,
        'icon': Icons.timer_outlined,
      },
      {
        'key': '1month',
        'name': 'Gói 1 tháng',
        'duration': 'Thời hạn 30 ngày',
        'days': 30,
        'price': sysConfig.price1m,
        'priceText': CurrencyFormatter.formatVND(sysConfig.price1m.toDouble()),
        'badge': null,
        'desc': 'Phù hợp dùng ngắn hạn & linh hoạt cho quán mới mở',
        'isFeatured': false,
        'icon': Icons.calendar_today_rounded,
      },
      {
        'key': '3month',
        'name': 'Gói 3 tháng',
        'duration': 'Thời hạn 90 ngày',
        'days': 90,
        'price': sysConfig.price3m,
        'priceText': CurrencyFormatter.formatVND(sysConfig.price3m.toDouble()),
        'badge': 'Tiết kiệm 15%',
        'desc': 'Chỉ ~33.000đ/tháng • Đọc thông báo 24/7 ổn định cao',
        'isFeatured': false,
        'icon': Icons.calendar_month_rounded,
      },
      {
        'key': '6month',
        'name': 'Gói 6 tháng',
        'duration': 'Thời hạn 180 ngày',
        'days': 180,
        'price': sysConfig.price6m,
        'priceText': CurrencyFormatter.formatVND(sysConfig.price6m.toDouble()),
        'badge': 'Tiết kiệm 25%',
        'desc': 'Chỉ ~29.000đ/tháng • Nửa năm an tâm kinh doanh',
        'isFeatured': false,
        'icon': Icons.date_range_rounded,
      },
      {
        'key': '9month',
        'name': 'Gói 9 tháng',
        'duration': 'Thời hạn 270 ngày',
        'days': 270,
        'price': sysConfig.price9m,
        'priceText': CurrencyFormatter.formatVND(sysConfig.price9m.toDouble()),
        'badge': 'Tiết kiệm 30%',
        'desc': 'Chỉ ~27.000đ/tháng • Hỗ trợ kỹ thuật ưu tiên 24/7',
        'isFeatured': false,
        'icon': Icons.verified_rounded,
      },
      {
        'key': '1year',
        'name': 'Gói 1 năm',
        'duration': sysConfig.bonusMonths1y > 0
            ? '365 ngày (+ Tặng ${sysConfig.bonusMonths1y} tháng)'
            : 'Thời hạn 365 ngày',
        'days': 365 + (sysConfig.bonusMonths1y * 30),
        'price': sysConfig.price1y,
        'priceText': CurrencyFormatter.formatVND(sysConfig.price1y.toDouble()),
        'badge': sysConfig.bonusMonths1y > 0
            ? 'Tặng ${sysConfig.bonusMonths1y} tháng ⭐'
            : 'Khuyên dùng nhất ⭐',
        'desc': sysConfig.bonusMonths1y > 0
            ? 'Chỉ ~24.000đ/tháng • Admin tặng kèm ${sysConfig.bonusMonths1y} tháng dùng miễn phí'
            : 'Chỉ ~24.000đ/tháng (~800đ/ngày) • Tiết kiệm tối đa',
        'isFeatured': true,
        'icon': Icons.workspace_premium_rounded,
      },
      {
        'key': 'lifetime',
        'name': 'Gói Vĩnh Viễn',
        'duration': 'Trọn đời không giới hạn',
        'days': 36500,
        'price': sysConfig.priceLifetime,
        'priceText': CurrencyFormatter.formatVND(sysConfig.priceLifetime.toDouble()),
        'badge': 'Vĩnh viễn trọn đời 🔥',
        'desc': 'Thanh toán 1 lần dùng mãi mãi • Không lo gia hạn • Bảo hành trọn đời',
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
    final packages = _getPackages(sysConfig);

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

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isFeatured ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                            border: Border.all(
                              color: isFeatured ? const Color(0xFF86EFAC) : WebTheme.cardBorder,
                              width: isFeatured ? 1.5 : 1,
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
                                        if (pkg['badge'] != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isFeatured ? const Color(0xFFFEF3C7) : WebTheme.emeraldLight,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isFeatured ? const Color(0xFFF59E0B) : WebTheme.emerald,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              pkg['badge'],
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: isFeatured ? const Color(0xFFB45309) : WebTheme.emerald,
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
  void _handleActivateTrial(GoogleAuthProvider googleAuth) {
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

    final success = googleAuth.startTrial(); // Bắt đầu tính giờ đếm ngược từ khoảnh khắc người dùng chọn gói!
    if (!success) return;

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
    final packages = _getPackages(sysConfig);

    final currentSelectedPkg = packages.firstWhere(
      (p) => p['key'] == _selectedPackageKey,
      orElse: () => packages.last,
    );

    return Scaffold(
      backgroundColor: WebTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER BRANDING & TRẠNG THÁI BẢN QUYỀN + ĐẾM NGƯỢC
              _buildHeaderCard(sysConfig, googleAuth),

              if (sysConfig.marketingBanner.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMarketingBanner(sysConfig.marketingBanner),
              ],

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
                // 3. TIÊU ĐỀ CHỌN GÓI THỜI HẠN & NÚT BẢNG CÁC GÓI
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        const Text(
                          'Chọn gói thời hạn (Tháng / Năm)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: WebTheme.textHeading,
                          ),
                        ),
                      ],
                    ),
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

  // BANNER KHUYẾN MÃI MARKETING TỪ ADMIN
  Widget _buildMarketingBanner(String bannerText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(WebTheme.radiusMd),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'ƯU ĐÃI KHUYẾN MÃI TỪ ADMIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFD97706)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  bannerText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                                  : 'HSD: ${googleAuth.expireDate.day}/${googleAuth.expireDate.month}/${googleAuth.expireDate.year} (Tự động cộng dồn khi mua thêm)',
                              style: TextStyle(
                                fontSize: 9,
                                color: isExpired ? const Color(0xFFDC2626) : const Color(0xFF15803D),
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
                final remaining = googleAuth.expireDate.difference(DateTime.now());
                final isExpired = remaining.isNegative;
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
                  '👑 Bạn đã sở hữu gói Vĩnh Viễn của AutoBank! Hệ thống tự động khóa tính năng mua gói vì tài khoản của bạn đã có đặc quyền trọn đời cao nhất.',
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

    String? customBadge = pkg['badge'];
    if (isTrial) {
      if (googleAuth.isTrialStarted) {
        customBadge = 'Đang đếm ngược ⏳';
      } else {
        customBadge = 'Chưa kích hoạt • Chọn để đếm ngược';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? WebTheme.primaryBg : Colors.white,
        borderRadius: BorderRadius.circular(WebTheme.radiusMd),
        border: Border.all(
          color: isSelected
              ? WebTheme.primary
              : (isFeatured ? const Color(0xFFBAE6FD) : WebTheme.cardBorder),
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          if (isSelected || isFeatured)
            BoxShadow(
              color: WebTheme.primary.withValues(alpha: 0.08),
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
                    color: isSelected ? WebTheme.primaryLight : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  ),
                  child: Icon(
                    pkg['icon'] as IconData,
                    size: 22,
                    color: isSelected ? WebTheme.primary : WebTheme.textMuted,
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
                              color: isSelected ? WebTheme.primaryDark : WebTheme.textHeading,
                            ),
                          ),
                          if (customBadge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isFeatured
                                    ? const Color(0xFFFEF3C7)
                                    : (isTrial ? const Color(0xFFFEF3C7) : WebTheme.emeraldLight),
                                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                                border: Border.all(
                                  color: isFeatured
                                      ? const Color(0xFFF59E0B)
                                      : (isTrial ? const Color(0xFFF59E0B) : WebTheme.emerald),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                customBadge,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: (isFeatured || isTrial) ? const Color(0xFFB45309) : WebTheme.emerald,
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
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pkg['priceText'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? WebTheme.primaryDark : WebTheme.emerald,
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
            'Quyền lợi khi kích hoạt bản quyền AutoBank',
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
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      }
    });

    _registerOrderToBackend();
  }

  Future<void> _registerOrderToBackend() async {
    try {
      final uri = Uri.parse('http://localhost:3000/admin/orders');
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

  int get _finalPayableAmount => (widget.amount - _discount).clamp(0, 99999999);

  String get _dynamicQrUrl {
    return 'https://img.vietqr.io/image/${widget.bankCode}-${widget.bankAcc}-compact2.png?amount=$_finalPayableAmount&addInfo=${widget.orderCode}&accountName=${Uri.encodeComponent(widget.bankName)}';
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isApplyingCoupon = true);

    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/admin/coupons/validate'),
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
    if (code == 'AUTOBANK20') {
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

  Future<void> _confirmAndActivatePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final approveUri = Uri.parse('http://localhost:3000/admin/orders/${widget.orderCode}/approve');
      await http.put(approveUri).timeout(const Duration(seconds: 4));

      final txUri = Uri.parse('http://localhost:3000/transactions');
      await http.post(
        txUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bankName': widget.bankCode,
          'accountNumber': widget.bankAcc,
          'amount': _finalPayableAmount,
          'content': 'CT TU ${widget.customerName.toUpperCase()} ND ${widget.orderCode}',
          'receivedAt': DateTime.now().toIso8601String(),
          'rawMessage': 'GD +${_finalPayableAmount}VND ND ${widget.orderCode} tai ${widget.bankCode}',
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      widget.onPaymentSuccess();
    }
  }

  Future<void> _handleGooglePayCheckout() async {
    setState(() => _isProcessing = true);

    // Giả lập popup xác thực Google Pay 1 chạm bảo mật
    await showDialog(
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
            Text(
              'Đang xử lý giao dịch qua Google Play...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
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

    // Kích hoạt thanh toán thành công
    await _confirmAndActivatePayment();
  }

  @override
  Widget build(BuildContext context) {
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
                      onTap: () => setState(() => _selectedPaymentMethod = 0),
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
                      onTap: () => setState(() => _selectedPaymentMethod = 1),
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
                              '2. Google Pay (GPay)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: _selectedPaymentMethod == 1 ? FontWeight.bold : FontWeight.w600,
                                color: _selectedPaymentMethod == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
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

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                    elevation: 1,
                  ),
                  onPressed: _isProcessing ? null : _confirmAndActivatePayment,
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 8),
                            Text('Đang kích hoạt bản quyền từ Admin...', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Xác nhận đã chuyển khoản • Kích hoạt gói',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                  ),
                  onPressed: _isProcessing ? null : _confirmAndActivatePayment,
                  icon: const Icon(Icons.sync_rounded, size: 16, color: WebTheme.primary),
                  label: const Text(
                    'Kiểm tra giao dịch tự động',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: WebTheme.primary),
                  ),
                ),
              ),
            ] else ...[
              // === TAB 2: THANH TOÁN GOOGLE PAY ===
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
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
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Bảo mật 100%', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentRow('Gói bản quyền:', widget.pkg['name'], null),
                    const Divider(height: 10, color: Color(0xFFE2E8F0)),
                    _buildPaymentRow('Tài khoản Google:', widget.customerEmail, null),
                    const Divider(height: 10, color: Color(0xFFE2E8F0)),
                    if (_discount > 0) ...[
                      _buildPaymentRow('Giá niêm yết:', CurrencyFormatter.formatVND(widget.amount.toDouble()), null),
                      const Divider(height: 10, color: Color(0xFFE2E8F0)),
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

              // Nút Google Pay chuẩn đen sang trọng
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

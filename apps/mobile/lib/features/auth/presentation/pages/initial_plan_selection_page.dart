import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../providers/google_auth_provider.dart';
import '../../../subscription/presentation/pages/register_subscription_page.dart';

/// Màn hình chọn gói bắt buộc cho tài khoản người dùng mới tạo
/// Yêu cầu xác nhận Tên cửa hàng / SĐT và kích hoạt dùng thử 3 ngày (đúng 72h) hoặc chọn các gói bản quyền
class InitialPlanSelectionPage extends StatefulWidget {
  const InitialPlanSelectionPage({super.key});

  @override
  State<InitialPlanSelectionPage> createState() => _InitialPlanSelectionPageState();
}

class _InitialPlanSelectionPageState extends State<InitialPlanSelectionPage> {
  late final TextEditingController _shopController;
  late final TextEditingController _phoneController;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    final auth = context.read<GoogleAuthProvider>();
    final initialShop = auth.shopName.isNotEmpty && auth.shopName != 'Cửa hàng'
        ? auth.shopName
        : (auth.displayName.isNotEmpty ? auth.displayName : 'Cửa hàng');
    _shopController = TextEditingController(text: initialShop);
    _phoneController = TextEditingController(text: auth.phone);
  }

  @override
  void dispose() {
    _shopController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GoogleAuthProvider>();
    final sysConfig = context.watch<SystemConfigProvider>();

    // Lọc các gói cước trả phí từ admin
    final paidPackages = sysConfig.packages.where((p) {
      final key = (p['key'] ?? '').toString();
      final isActive = p['isActive'] != false;
      return key != 'trial' && isActive;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. LOGO & HEADER CHÀO MỪNG
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF0284C7),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Bảng Giá & Kích Hoạt Gói',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Tài khoản mới: Vui lòng nhập SĐT & Ngân hàng để nhận diện giao dịch',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. KHỐI FORM THÔNG TIN TÀI KHOẢN GOOGLE + SĐT + NGÂN HÀNG + TÊN CỬA HÀNG
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF0284C7),
                              child: Text(
                                auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'G',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.displayName.isNotEmpty ? auth.displayName : 'Tài khoản Google',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    auth.email,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Text(
                                'Đăng ký mới',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 14),

                        // Trường 1: Số điện thoại (Bắt buộc cho tài khoản mới)
                        const Row(
                          children: [
                            Text(
                              'Số điện thoại của bạn:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            SizedBox(width: 4),
                            Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: 0912345678',
                            prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF0284C7), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Trường 2: Tên cửa hàng hoặc tên cá nhân
                        const Text(
                          'Tên cửa hàng hoặc tên cá nhân:',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _shopController,
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: Quán Cà Phê Mộc hoặc Nguyễn Văn A',
                            prefixIcon: const Icon(Icons.storefront_rounded, color: Color(0xFF0284C7), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),

                        if (_inputError != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _inputError!,
                                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. THẺ 1: GÓI DÙNG THỬ 3 NGÀY MIỄN PHÍ (NỔI BẬT NHẤT - ĐÚNG 72 GIỜ)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF15803D)),
                                  SizedBox(width: 4),
                                  Text(
                                    'MIỄN PHÍ 100% • ĐÚNG 72 GIỜ',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '0 VNĐ',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Gói Dùng Thử 3 Ngày (72 Giờ)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Trải nghiệm đầy đủ 100% tính năng đọc biến động số dư bằng giọng nói tự nhiên.',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.35),
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureItem('Trực loa 24/7 không giới hạn số lượng giao dịch'),
                        _buildFeatureItem('Tự động nhận diện 65+ ngân hàng & ví điện tử Việt Nam'),
                        _buildFeatureItem('Đọc số tiền, ngân hàng nhận, lời cảm ơn khách hàng'),
                        _buildFeatureItem('Bỏ qua tối ưu hóa pin để chạy ngầm bền bỉ xuyên đêm'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đếm ngược đúng 72 giờ (3 ngày) tính từ lúc bạn bấm kích hoạt bên dưới.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.35, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final shop = _shopController.text.trim();
                              final phone = _phoneController.text.trim();
                              if (shop.isEmpty) {
                                setState(() => _inputError = 'Vui lòng nhập tên cửa hàng hoặc họ tên của bạn');
                                return;
                              }
                              if (phone.isEmpty || phone.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
                                setState(() => _inputError = 'Vui lòng nhập số điện thoại hợp lệ (tối thiểu 9 số)');
                                return;
                              }
                              setState(() => _inputError = null);
                              final success = await auth.startTrial(shop: shop, phone: phone);
                              if (success) {
                                TtsService().speakTestFeedback('Chào mừng bạn đến với hệ thống đọc thông báo nhận tiền tự động.');
                                if (context.mounted) {
                                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                      content: Row(
                                        children: [
                                          Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text('🎉 Kích hoạt dùng thử 3 ngày (72 giờ) thành công! Bắt đầu đếm ngược từ bây giờ.'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_circle_fill_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'BẮT ĐẦU DÙNG THỬ 3 NGÀY NGAY',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. DANH SÁCH CÁC GÓI BẢN QUYỀN CHÍNH THỨC CÀI ĐẶT BỞI ADMIN
                  Row(
                    children: const [
                      Icon(Icons.diamond_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'HOẶC CHỌN GÓI BẢN QUYỀN CHÍNH THỨC',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...paidPackages.map((pkg) {
                    final key = (pkg['key'] ?? '').toString();
                    final name = (pkg['name'] ?? 'Gói dịch vụ').toString();
                    final price = (pkg['price'] as num?)?.toInt() ?? 0;
                    final badge = (pkg['badge'] ?? '').toString();
                    final desc = (pkg['description'] ?? '').toString();
                    final isHighlighted = key == '1year' || key == 'lifetime';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHighlighted ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isHighlighted ? 1.6 : 1,
                        ),
                        boxShadow: [
                          if (isHighlighted)
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    if (badge.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isHighlighted ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          badge,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isHighlighted ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  price > 0 ? CurrencyFormatter.formatVND(price.toDouble()) : '0 VNĐ',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isHighlighted ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final shop = _shopController.text.trim();
                              final phone = _phoneController.text.trim();
                              if (shop.isNotEmpty || phone.isNotEmpty) {
                                await auth.updateAccountInfo(
                                  shop: shop.isNotEmpty ? shop : null,
                                  phone: phone.isNotEmpty ? phone : null,
                                );
                              }
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterSubscriptionPage(
                                      initialPackageKey: key,
                                      onBackToHome: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Chọn gói', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Nút Đăng xuất Google
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                      onPressed: () => auth.signOut(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Đăng xuất tài khoản Google này', style: TextStyle(fontSize: 12)),
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

  static Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

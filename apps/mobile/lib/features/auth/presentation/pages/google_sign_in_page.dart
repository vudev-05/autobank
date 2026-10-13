import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../providers/google_auth_provider.dart';

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  State<GoogleSignInPage> createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  bool _showCustomForm = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _shopController.dispose();
    super.dispose();
  }

  void _handleSelectAccount(GoogleAuthProvider auth, int index) {
    auth.selectAccountByIndex(index);
    final acc = auth.accounts[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: WebTheme.emerald,
        content: Text('🎉 Chào mừng ${acc.name} (${acc.email}) quay trở lại!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleCreateOrSignInCustom(GoogleAuthProvider auth) {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final shop = _shopController.text.trim();

    auth.signInWithGoogle(
      name: name,
      email: email,
      initial: name.isNotEmpty ? name[0].toUpperCase() : 'G',
      shop: shop.isNotEmpty ? shop : 'Cửa hàng $name',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: WebTheme.emerald,
        content: Text('🎉 Đã đăng nhập tài khoản Google: $email'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GoogleAuthProvider>();
    final sysConfig = context.watch<SystemConfigProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. BRAND LOGO & TIÊU ĐỀ
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: WebTheme.primary.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: WebTheme.cardBorder),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: WebTheme.primary,
                            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      sysConfig.brandName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Center(
                    child: Text(
                      sysConfig.brandSlogan,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. KHỐI ĐĂNG NHẬP GOOGLE BẮT BUỘC
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const GoogleLogo(size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Đăng nhập tài khoản Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Yêu cầu đăng nhập để đồng bộ bản quyền & thông tin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 14),

                        const Text(
                          'CHỌN TÀI KHOẢN GOOGLE TRÊN THIẾT BỊ:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Danh sách tài khoản có sẵn
                        ...auth.accounts.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final acc = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _handleSelectAccount(auth, idx),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(0xFF4285F4),
                                            child: Text(
                                              acc.initial,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: CircleAvatar(
                                              radius: 7,
                                              backgroundColor: Colors.white,
                                              child: GoogleLogo(size: 10),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              acc.name,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              acc.email,
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.storefront_rounded, size: 12, color: Colors.blue.shade700),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    acc.shop,
                                                    style: TextStyle(fontSize: 10.5, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Đăng nhập',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 4),

                        // Nút chuyển đổi nhập tài khoản khác
                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                            ),
                            onPressed: () {
                              setState(() {
                                _showCustomForm = !_showCustomForm;
                              });
                            },
                            icon: Icon(_showCustomForm ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded, size: 18),
                            label: Text(
                              _showCustomForm ? 'Thu gọn form thêm tài khoản' : '+ Thêm / Đăng nhập tài khoản Google khác',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        // Form tạo / nhập tài khoản Google mới
                        if (_showCustomForm) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Thông tin tài khoản Google mới:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Họ và tên Google',
                                      hintText: 'Ví dụ: Lê Hoàng Minh',
                                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Địa chỉ Gmail',
                                      hintText: 'lehoangminh.shop@gmail.com',
                                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập Gmail';
                                      if (!val.contains('@')) return 'Email không hợp lệ (@gmail.com)';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _shopController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Tên cửa hàng / Kinh doanh',
                                      hintText: 'Ví dụ: Cà Phê Muối Sài Gòn',
                                      prefixIcon: const Icon(Icons.storefront_outlined, size: 18),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên cửa hàng' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _handleCreateOrSignInCustom(auth),
                                    icon: const GoogleLogo(size: 18),
                                    label: const Text(
                                      'Xác nhận đăng nhập Google',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. THÔNG TIN BẢO MẬT & CHÍNH SÁCH
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_rounded, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Chính sách lưu trữ & Bản quyền riêng biệt',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• Mỗi tài khoản Google lưu trữ riêng biệt cấu hình cửa hàng, giọng đọc, và biến động số dư.\n'
                          '• Gói dùng thử 3 ngày miễn phí chỉ áp dụng 1 lần duy nhất cho mỗi tài khoản Google.\n'
                          '• Đăng ký gói bản quyền được tự động lưu lên máy chủ admin và giữ vĩnh viễn theo tài khoản.',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'Hỗ trợ kỹ thuật 24/7: ${sysConfig.hotline}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
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
}

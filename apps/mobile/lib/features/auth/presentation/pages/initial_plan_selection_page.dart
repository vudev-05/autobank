import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/tts/tts_service.dart';
import '../providers/google_auth_provider.dart';
import '../../../subscription/presentation/pages/register_subscription_page.dart';

/// Màn hình chọn gói bắt buộc cho tài khoản người dùng mới tạo
/// Yêu cầu kích hoạt dùng thử 3 ngày (tính giờ từ lúc bấm) hoặc chọn gói bản quyền trước khi vào sử dụng app
class InitialPlanSelectionPage extends StatelessWidget {
  const InitialPlanSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GoogleAuthProvider>();

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
                      'Kích Hoạt Gói Sử Dụng',
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
                      'Vui lòng chọn gói để bắt đầu sử dụng dịch vụ thông báo số dư',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. USER PROFILE CHIP
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF0284C7),
                          child: Text(
                            auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'G',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.displayName,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                auth.email,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
                            'Tài khoản mới',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. THẺ 1: GÓI DÙNG THỬ 3 NGÀY MIỄN PHÍ (NỔI BẬT NHẤT)
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
                                    'MIỄN PHÍ 100% • 72 GIỜ',
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
                          'Gói Dùng Thử 3 Ngày',
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
                              Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Thời hạn dùng thử 3 ngày sẽ bắt đầu tính và đếm ngược chính xác từ thời điểm bạn bấm nút dưới đây.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.35, fontWeight: FontWeight.w600),
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
                            onPressed: () {
                              final success = auth.startTrial();
                              if (success) {
                                TtsService().speakTestFeedback('Chúc mừng bạn đã kích hoạt gói dùng thử ba ngày. Loa sẵn sàng trực biến động số dư!');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                    content: Row(
                                      children: [
                                        Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text('🎉 Kích hoạt dùng thử 3 ngày thành công! Thời gian bắt đầu đếm ngược từ bây giờ.'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
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

                  const SizedBox(height: 16),

                  // 4. THẺ 2: GÓI BẢN QUYỀN CHÍNH THỨC
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DÀNH CHO HỘ KINH DOANH',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Ưu đãi -10%',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Đăng Ký Gói Bản Quyền Chính Thức',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chọn gói Tháng, 1 Năm hoặc Gói Vĩnh Viễn để duy trì dịch vụ liên tục không bị gián đoạn.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                              foregroundColor: const Color(0xFF0284C7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterSubscriptionPage()),
                              );
                            },
                            child: const Text(
                              'Xem bảng các gói bản quyền & giá ưu đãi',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nút Đăng xuất nếu muốn đổi tài khoản
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                      onPressed: () => auth.signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Đổi tài khoản Google khác', style: TextStyle(fontSize: 12)),
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

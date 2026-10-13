import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedPlanIndex = 1; // Mặc định chọn gói 1 năm (index 1)
  late Timer _countdownTimer;
  int _secondsLeft = 23 * 3600 + 35 * 60 + 17;

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
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showPaymentModal(String planName, String price) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thanh toán chuyển khoản VietQR',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gói: $planName • Số tiền: $price',
              style: const TextStyle(fontSize: 14, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade100, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                'https://api.vietqr.io/image/970422-0869226687-compact2.jpg?amount=${price.replaceAll(RegExp(r'[^0-9]'), '')}&addInfo=AUTOBANK%20031380',
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 80, color: Color(0xFF0284C7)),
                      Text('Quét mã QR VietQR để kích hoạt ngay'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Hệ thống tự động kích hoạt tài khoản trong 5 giây sau khi nhận tiền!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cảm ơn bạn! Hệ thống đã ghi nhận yêu cầu gia hạn.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Đã chuyển khoản xong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              child: Column(
                children: [
                  // 1. HEADER ROW: TIỆM BÁNH MÌ KIM ANH + NÚT LỊCH SỬ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tiệm bánh mì Kim Anh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lịch sử thanh toán: Đang dùng gói thử nghiệm 24h.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 16, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Text(
                                'Lịch sử',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. ICON CHUÔNG XANH LỚN + TIÊU ĐỀ
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 32),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Vui lòng chọn gói dịch vụ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. 3 CHỈ SỐ UY TÍN (50.000+ Shop, 50.000+ Cài đặt, 4.9 Đánh giá)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol(Icons.storefront_rounded, const Color(0xFF0284C7), '50.000+', 'Shop tin dùng'),
                        Container(width: 1, height: 30, color: const Color(0xFFF1F5F9)),
                        _buildStatCol(Icons.download_rounded, const Color(0xFF2563EB), '50.000+', 'Cài đặt'),
                        Container(width: 1, height: 30, color: const Color(0xFFF1F5F9)),
                        _buildStatCol(Icons.star_rounded, const Color(0xFFEAB308), '4.9', 'Đánh giá'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. THẺ CẢNH BÁO TÀI KHOẢN ĐÃ HẾT HẠN
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Text(
                      'Tài khoản đã hết hạn — gia hạn để tiếp tục nghe tiền vào.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. THẺ GIA HẠN SỚM GIẢM 10% GRADIENT TÍM
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Gia hạn sớm — giảm 10%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Còn 1 ngày — gia hạn ngay để không bị gián đoạn nghe tiền vào.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Còn ${_formatTimer(_secondsLeft)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6. DÙNG THỬ ĐẾN THỜI ĐIỂM
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF15803D)),
                        SizedBox(width: 8),
                        Text(
                          'Dùng thử đến 12:03 12/10',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 7. CÁC GÓI DỊCH VỤ (Gói 3 tháng & Gói 1 năm & Gói Trọn đời)
                  Row(
                    children: [
                      // GÓI 3 THÁNG
                      Expanded(
                        child: _buildPlanCard(
                          index: 0,
                          badge: 'CƠ BẢN',
                          badgeColor: const Color(0xFF64748B),
                          title: 'Gói 3 tháng',
                          duration: '3 tháng',
                          originalPrice: '90.000 đ',
                          price: '81.000 đ',
                          subPerMonth: '~30.000đ/tháng',
                          subPerDay: '~900đ/ngày',
                          description: 'Phù hợp dùng thử',
                        ),
                      ),
                      const SizedBox(width: 10),
                      // GÓI 1 NĂM (PHỔ BIẾN NHẤT)
                      Expanded(
                        child: _buildPlanCard(
                          index: 1,
                          badge: 'PHỔ BIẾN NHẤT',
                          badgeColor: const Color(0xFF0284C7),
                          title: 'Gói 1 năm',
                          duration: '12 tháng',
                          originalPrice: '180.000 đ',
                          price: '162.000 đ',
                          subPerMonth: '~15.000đ/tháng',
                          subPerDay: '~450đ/ngày',
                          description: 'Lựa chọn của đa số shop',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // GÓI VĨNH VIỄN TRỌN ĐỜI VIP
                  _buildLifetimePlanCard(),

                  const SizedBox(height: 20),

                  // NÚT NÂNG CẤP NGAY
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        elevation: 4,
                        shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (_selectedPlanIndex == 0) {
                          _showPaymentModal('Gói 3 tháng', '81.000 đ');
                        } else if (_selectedPlanIndex == 1) {
                          _showPaymentModal('Gói 1 năm', '162.000 đ');
                        } else {
                          _showPaymentModal('Gói Vĩnh Viễn Trọn Đời', '350.000 đ');
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on_rounded, color: Colors.amber, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'KÍCH HOẠT & QUÉT QR THANH TOÁN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // NÚT ZALO HỖ TRỢ NỔI GÓC DƯỚI PHẢI
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '0869226687'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang kết nối Zalo hỗ trợ 0869226687!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.headset_mic_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Zalo hỗ trợ >',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String badge,
    required Color badgeColor,
    required String title,
    required String duration,
    required String originalPrice,
    required String price,
    required String subPerMonth,
    required String subPerDay,
    required String description,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge đỉnh
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0284C7) : badgeColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Center(
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected ? Colors.white : badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(duration, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  const SizedBox(height: 8),
                  Text(
                    originalPrice,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subPerMonth, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text(subPerDay, style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifetimePlanCard() {
    final isSelected = _selectedPlanIndex == 2;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)]
                : [Colors.white, Colors.white],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Gói Trọn Đời (Vĩnh Viễn)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'HOT',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Dùng mãi mãi không cần gia hạn, bảo hành trọn đời', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('500.000 đ ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough)),
                      const Text('350.000 đ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

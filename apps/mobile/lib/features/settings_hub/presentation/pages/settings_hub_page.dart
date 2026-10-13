import 'package:flutter/material.dart';
import 'package:autobank_mobile/features/settings/presentation/pages/settings_guide_page.dart';
import 'package:autobank_mobile/features/settings/presentation/pages/activity_check_page.dart';
import 'package:autobank_mobile/features/voice_settings/presentation/pages/voice_settings_page.dart';

class SettingsHubPage extends StatefulWidget {
  final VoidCallback? onNavigateToSubscription;

  const SettingsHubPage({
    super.key,
    this.onNavigateToSubscription,
  });

  @override
  State<SettingsHubPage> createState() => _SettingsHubPageState();
}

class _SettingsHubPageState extends State<SettingsHubPage> {
  final TextEditingController _searchController = TextEditingController();

  void _openDetailSheet(String title, String description, IconData icon, Color color) {
    if (title == 'Âm thanh & hiển thị') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VoiceSettingsPage()),
      );
      return;
    }

    if (title == 'Nghe thông báo') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsGuidePage()),
      );
      return;
    }

    if (title == 'Kiểm tra hoạt động' || title == 'Ứng dụng') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActivityCheckPage()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
              title: const Text('Trạng thái hoạt động', style: TextStyle(fontSize: 14)),
              trailing: const Text('Đang bật', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF0284C7)),
              title: const Text('Phiên bản', style: TextStyle(fontSize: 14)),
              trailing: const Text('v2.5.0 Pro', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PROFILE THÔNG TIN HẠN SỬ DỤNG
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hạn sử dụng: ',
                                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                              ),
                              Text(
                                '12/10/2026',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Gói sử dụng: ',
                                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                              ),
                              Text(
                                '1 ngày (Thử nghiệm)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. THANH TÌM KIẾM CÀI ĐẶT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Tìm cài đặt...',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. BANNER ĐĂNG KÝ GIA HẠN SỬ DỤNG (Gradient Tím - Xanh)
                  GestureDetector(
                    onTap: widget.onNavigateToSubscription,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.military_tech_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Đăng ký gia hạn sử dụng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'SẮP HẾT',
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '1 ngày • Hết hạn 12/10/2026',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Gia hạn',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: Color(0xFF0F172A)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. TIÊU ĐỀ SECTION
                  const Text(
                    'Danh mục cài đặt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Chọn nhóm để xem chi tiết',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),

                  const SizedBox(height: 14),

                  // 5. GRID 8 CARD DANH MỤC CÀI ĐẶT
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.98,
                    children: [
                      // 1. Tài khoản & gói
                      _buildSettingsCard(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF0284C7),
                        iconBgColor: const Color(0xFFE0F2FE),
                        topStripeColor: const Color(0xFF0284C7),
                        title: 'Tài khoản & gói',
                        description: 'Thông tin, ngân hàng, kiếm tiền',
                      ),
                      // 2. Tiện ích
                      _buildSettingsCard(
                        icon: Icons.grid_view_rounded,
                        iconColor: const Color(0xFF0D9488),
                        iconBgColor: const Color(0xFFCCFBF1),
                        topStripeColor: const Color(0xFF0D9488),
                        title: 'Tiện ích',
                        description: 'Thống kê, sổ thu chi, giá vàng',
                      ),
                      // 3. Giải trí
                      _buildSettingsCard(
                        icon: Icons.celebration_rounded,
                        iconColor: const Color(0xFF9333EA),
                        iconBgColor: const Color(0xFFF3E8FF),
                        topStripeColor: const Color(0xFF9333EA),
                        title: 'Giải trí',
                        description: 'Game show, thư giãn sau giờ bán',
                      ),
                      // 4. Nghe thông báo
                      _buildSettingsCard(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFF16A34A),
                        iconBgColor: const Color(0xFFDCFCE7),
                        topStripeColor: const Color(0xFF16A34A),
                        title: 'Nghe thông báo',
                        description: 'Cài đặt máy, chia sẻ thông báo',
                      ),
                      // 5. Âm thanh & hiển thị
                      _buildSettingsCard(
                        icon: Icons.volume_up_rounded,
                        iconColor: const Color(0xFFEA580C),
                        iconBgColor: const Color(0xFFFFEDD5),
                        topStripeColor: const Color(0xFFEA580C),
                        title: 'Âm thanh & hiển thị',
                        description: 'Loa, giọng nói, im lặng',
                      ),
                      // 6. Trợ giúp
                      _buildSettingsCard(
                        icon: Icons.support_agent_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        iconBgColor: const Color(0xFFEDE9FE),
                        topStripeColor: const Color(0xFF7C3AED),
                        title: 'Trợ giúp',
                        description: 'Video, FAQ, liên hệ',
                      ),
                      // 7. Kiểm tra hoạt động
                      _buildSettingsCard(
                        icon: Icons.checklist_rtl_rounded,
                        iconColor: const Color(0xFF0891B2),
                        iconBgColor: const Color(0xFFCFFAFE),
                        topStripeColor: const Color(0xFF0891B2),
                        title: 'Kiểm tra hoạt động',
                        description: 'Kiểm tra quyền, pin và loa đọc',
                      ),
                      // 8. Pháp lý & bảo mật
                      _buildSettingsCard(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFF475569),
                        iconBgColor: const Color(0xFFF1F5F9),
                        topStripeColor: const Color(0xFF475569),
                        title: 'Pháp lý & bảo mật',
                        description: 'Điều khoản, quyền riêng tư',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // NÚT HỖ TRỢ 24/7 NỔI GÓC DƯỚI PHẢI
            Positioned(
              bottom: 16,
              right: 16,
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
                      'Hỗ trợ 24/7 >',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color topStripeColor,
    required String title,
    required String description,
  }) {
    return GestureDetector(
      onTap: () => _openDetailSheet(title, description, icon, iconColor),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dải màu mỏng ở mép đỉnh
            Container(height: 4, color: topStripeColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Xem thêm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: topStripeColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward, size: 12, color: topStripeColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

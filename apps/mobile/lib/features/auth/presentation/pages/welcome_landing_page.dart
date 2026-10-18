import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/widgets/bank_directory_widget.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../providers/google_auth_provider.dart';

class WelcomeLandingPage extends StatefulWidget {
  const WelcomeLandingPage({super.key});

  @override
  State<WelcomeLandingPage> createState() => _WelcomeLandingPageState();
}

class _WelcomeLandingPageState extends State<WelcomeLandingPage> {
  final ScrollController _scrollController = ScrollController();
  final TtsService _ttsService = TtsService();
  bool _isPlayingAudio = false;
  String _activeDemoSentence = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _playTtsDemo(String sentence) async {
    setState(() {
      _isPlayingAudio = true;
      _activeDemoSentence = sentence;
    });
    await _ttsService.speakSentence(
      sentence,
      onFinished: () {
        if (mounted) {
          setState(() {
            _isPlayingAudio = false;
            _activeDemoSentence = '';
          });
        }
      },
    );
  }

  void _handleGoogleSignIn(BuildContext context) async {
    final auth = context.read<GoogleAuthProvider>();
    if (auth.isLoading) return;
    final success = await auth.signInWithRealGoogle();
    if (!success && auth.errorMessage != null && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
          content: Text(auth.errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sysConfig = context.watch<SystemConfigProvider>();
    final auth = context.watch<GoogleAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. THANH ĐIỀU HƯỚNG WEB HEADER (WEBSITE PILL NAV)
                  _buildWebPillHeader(context, sysConfig),

                  // 2. HERO BANNER CHÍNH (ĐỌC THÔNG BÁO NHẬN TIỀN)
                  _buildWebHeroSection(context, sysConfig),

                  // 3. THANH METRICS UY TÍN (65+ BANK, 0.1S, 100K SHOP)
                  _buildSocialProofMetrics(),

                  // 4. KHỐI TRẢI NGHIỆM NGHE THỬ LOA PHÁT THANH
                  _buildVoiceDemoSection(),

                  // 5. CÁC TÍNH NĂNG VƯỢT TRỘI (GRID 6 CARDS)
                  _buildFeaturesSection(),

                  // 6. DANH SÁCH 65+ NGÂN HÀNG & VÍ ĐIỆN TỬ
                  _buildBankEcosystemSection(),

                  // 7. BẢNG GIÁ CÁC GÓI BẢN QUYỀN
                  _buildPricingSection(context),

                  // 8. HƯỚNG DẪN 3 BƯỚC BẮT ĐẦU CỰC DỄ
                  _buildHowItWorksSection(),

                  // 9. CAM KẾT BẢO MẬT & FOOTER
                  _buildFooterSection(sysConfig),
                ],
              ),
            ),

            // 10. THANH NÚT BẤM CỐ ĐỊNH Ở ĐÁY (STICKY BOTTOM ACTION BAR)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const GoogleLogo(size: 20),
                          label: Text(
                            auth.isLoading ? 'ĐANG KẾT NỐI GOOGLE...' : 'ĐĂNG NHẬP BẰNG GOOGLE',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          onPressed: auth.isLoading ? null : () => _handleGoogleSignIn(context),
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
    );
  }

  // 1. THANH ĐIỀU HƯỚNG WEB PILL HEADER
  Widget _buildWebPillHeader(BuildContext context, SystemConfigProvider sysConfig) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'app_logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx1, err1, stack1) => Image.network(
                      'favicon.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx2, err2, stack2) => Container(
                        color: const Color(0xFF0284C7),
                        child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sysConfig.brandName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sysConfig.brandSlogan,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _handleGoogleSignIn(context),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 2. HERO BANNER CHÍNH
  Widget _buildWebHeroSection(BuildContext context, SystemConfigProvider sysConfig) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge công nghệ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 14),
                SizedBox(width: 4),
                Text(
                  'CÔNG NGHỆ BÁO TIỀN TỰ ĐỘNG 4.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Đọc Thông Báo\nNhận Tiền Tức Thì',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Phát loa tiếng Việt chuẩn xác ngay khi khách quét mã QR chuyển khoản. Chống gian lận chuyển khoản ảo, không cần mở app ngân hàng check.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFFE0F2FE),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // NÚT CTA CHÍNH TRÊN HERO - TƯƠNG PHẢN CAO SÁNG RÕ
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.login_rounded, size: 20, color: Color(0xFF0284C7)),
              label: const Text(
                'ĐĂNG NHẬP VÀO SỬ DỤNG',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.3,
                ),
              ),
              onPressed: () => _handleGoogleSignIn(context),
            ),
          ),

          const SizedBox(height: 14),
          // CHIA RA NẰM TRÊN 1 HÀNG CÂN ĐỐI
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF86EFAC), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Dùng thử 3 ngày miễn phí',
                        style: TextStyle(
                          color: Color(0xFFF0FDF4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.white.withValues(alpha: 0.35),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF86EFAC), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Không cần mật khẩu ngân hàng',
                        style: TextStyle(
                          color: Color(0xFFF0FDF4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. THANH METRICS UY TÍN
  Widget _buildSocialProofMetrics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCol('65+', 'Ngân hàng & Ví'),
          _buildDivider(),
          _buildMetricCol('0.1s', 'Đọc tức thì'),
          _buildDivider(),
          _buildMetricCol('100K+', 'Shop tin dùng'),
          _buildDivider(),
          _buildMetricCol('99.9%', 'Ổn định 24/7'),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0284C7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE2E8F0),
    );
  }

  // 4. KHỐI TRẢI NGHIỆM NGHE THỬ LOA PHÁT THANH
  Widget _buildVoiceDemoSection() {
    final demoSentences = [
      'Tài khoản vừa nhận năm mươi nghìn đồng',
      'MB Bank nhận hai trăm năm mươi nghìn đồng, tiền cà phê sáng',
      'Vietcombank nhận một triệu hai trăm nghìn đồng, đơn hàng số tám tám',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.headset_rounded, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 8),
              Text(
                'NGHE THỬ GIỌNG ĐỌC LOA THỰC TẾ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Bấm vào các câu dưới đây để nghe thử âm thanh loa phát thanh rõ ràng, to rõ giữa quán ồn ào:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          ...demoSentences.map((sentence) {
            final isCurrent = _activeDemoSentence == sentence && _isPlayingAudio;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFF22C55E) : const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCurrent ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    sentence,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isCurrent ? const Color(0xFF15803D) : const Color(0xFF1E293B),
                    ),
                  ),
                  trailing: Text(
                    isCurrent ? 'Đang phát...' : 'Bấm nghe',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                    ),
                  ),
                  onTap: () => _playTtsDemo(sentence),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5. CÁC TÍNH NĂNG VƯỢT TRỘI (GRID 6 CARDS)
  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
        'title': 'Báo Tiền Tức Thì 0.1s',
        'desc': 'Bắt biến động số dư ngoài thanh thông báo Android siêu nhanh, phát loa ngay lập tức.',
      },
      {
        'icon': Icons.light_mode_rounded,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFDCFCE7),
        'title': 'Sáng Đèn & Toàn Màn Hình',
        'desc': 'Viền đèn Neon chớp sáng và pop-up số tiền khổng lồ, thu ngân nhìn rõ từ xa.',
      },
      {
        'icon': Icons.pie_chart_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'title': 'Quản Lý Quỹ & Chi Tiêu',
        'desc': 'Chọn phân loại tiền ăn, tiền nhà, xăng xe... Báo cáo chi tiêu cá nhân và doanh nghiệp.',
      },
      {
        'icon': Icons.devices_rounded,
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFCCFBF1),
        'title': 'Chia Sẻ Loa PC & iPhone',
        'desc': 'Tạo mã PIN 6 số hoặc quét QR để mở loa trên máy tính thu ngân hoặc iPhone/iPad.',
      },
      {
        'icon': Icons.battery_charging_full_rounded,
        'color': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFF7ED),
        'title': 'Chạy Ngầm 24/7 Bền Bỉ',
        'desc': 'Không bị hệ điều hành tắt khi tắt màn hình, sẵn sàng trực quầy 24/24 khi cắm sạc.',
      },
      {
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'title': 'Bảo Mật Cấp Ngân Hàng',
        'desc': 'Không yêu cầu mật khẩu hay liên kết thẻ ngân hàng. Chỉ đọc thông báo push ngoài máy.',
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'TÍNH NĂNG VƯỢT TRỘI CỦA HỆ THỐNG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.4,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemCount: features.length,
            itemBuilder: (ctx, idx) {
              final item = features[idx];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['bg'] as Color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 6. DANH SÁCH 65+ NGÂN HÀNG & VÍ ĐIỆN TỬ (BÊ NGUYÊN GIAO DIỆN WEB CÓ LOGO ĐẦY ĐỦ)
  Widget _buildBankEcosystemSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: const BankDirectoryWidget(showHeader: true),
    );
  }

  // 7. BẢNG GIÁ CÁC GÓI BẢN QUYỀN
  Widget _buildPricingSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'CÁC GÓI DỊCH VỤ LINH HOẠT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.4,
              ),
            ),
          ),
          // Thẻ Gói Vĩnh Viễn VIP (Nổi bật nhất)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.diamond_rounded, color: Color(0xFFFDE047), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'GÓI VĨNH VIỄN (TRỌN ĐỜI)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE047),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VIP NHẤT HỆ THỐNG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF713F12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '399.000 đ',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Text(
                  'Mua 1 lần dùng mãi mãi trọn đời • Không bao giờ phải gia hạn thêm',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFBAE6FD)),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleGoogleSignIn(context),
                    child: const Text(
                      'Đăng nhập để sở hữu Gói VIP',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Các gói khác dạng row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Dùng thử 3 ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('0 đ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF16A34A))),
                      Text('Miễn phí sau khi đăng nhập', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Gói 1 Năm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('199.000 đ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0284C7))),
                      Text('Chỉ ~16k / tháng', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. HƯỚNG DẪN 3 BƯỚC BẮT ĐẦU CỰC DỄ
  Widget _buildHowItWorksSection() {
    final steps = [
      {'num': '1', 'title': 'Đăng nhập Google', 'desc': 'Ấn nút Đăng nhập vào sử dụng và chọn tài khoản Google của bạn.'},
      {'num': '2', 'title': 'Bật Quyền đọc thông báo', 'desc': 'Gạt công tắc cấp quyền 1 lần duy nhất để app nghe thông báo tiền về.'},
      {'num': '3', 'title': 'Để điện thoại tại quầy', 'desc': 'Khách chuyển khoản quét mã QR là loa phát thanh tự động đọc ngay!'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3 BƯỚC ĐƠN GIẢN ĐỂ SỬ DỤNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          ...steps.map((st) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        st['num']!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          st['desc']!,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 9. CAM KẾT BẢO MẬT & FOOTER
  Widget _buildFooterSection(SystemConfigProvider sysConfig) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.shield_rounded, color: Color(0xFF16A34A), size: 16),
              SizedBox(width: 6),
              Text(
                'Cam kết 100% An toàn & Bảo mật thông tin ngân hàng',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hotline CSKH: ${sysConfig.hotline} • Zalo hỗ trợ: ${sysConfig.hotline}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 ${sysConfig.brandName}. Bản quyền thuộc về hệ thống Đọc thông báo nhận tiền.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_picker_service.dart';
import '../../../../core/utils/file_downloader.dart';
import '../../../../core/widgets/bank_directory_widget.dart';
import '../../../../core/widgets/app_video_guide_modal.dart';
import '../../../../core/widgets/app_in_app_rating_dialog.dart';
import '../../../../core/security/app_pin_security_service.dart';
import '../../../../core/security/app_pin_dialog.dart';
import '../../../affiliate/presentation/pages/affiliate_earn_page.dart';
import '../../../affiliate/presentation/providers/affiliate_provider.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../auth/presentation/providers/google_auth_provider.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../../pos/presentation/pages/pos_smart_cashier_page.dart';
import '../../../subscription/presentation/pages/register_subscription_page.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../../../transactions/domain/entities/normalized_transaction.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../voice_settings/presentation/pages/voice_settings_page.dart';
import 'activity_check_page.dart';

class SettingsGuidePage extends StatefulWidget {
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onNavigateToAnalytics;

  const SettingsGuidePage({
    super.key,
    this.onNavigateToRegister,
    this.onNavigateToAnalytics,
  });

  @override
  State<SettingsGuidePage> createState() => _SettingsGuidePageState();
}

class _SettingsGuidePageState extends State<SettingsGuidePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Âm thanh & Tùy chọn cục bộ
  bool _readDebit = true;
  bool _strobeEffectEnabled = true;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 6, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readDebit = prefs.getBool('read_debit_notifications') ?? true;
      _strobeEffectEnabled = prefs.getBool('strobe_effect_enabled') ?? true;
      _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
      final qStartH = prefs.getInt('quiet_start_h') ?? 22;
      final qStartM = prefs.getInt('quiet_start_m') ?? 0;
      final qEndH = prefs.getInt('quiet_end_h') ?? 6;
      final qEndM = prefs.getInt('quiet_end_m') ?? 0;
      _quietStart = TimeOfDay(hour: qStartH, minute: qStartM);
      _quietEnd = TimeOfDay(hour: qEndH, minute: qEndM);
    });

    if (_quietHoursEnabled) {
      TtsService().updateSchedule(
        enabled: true,
        startHour: _quietStart.hour,
        startMinute: _quietStart.minute,
        endHour: _quietEnd.hour,
        endMinute: _quietEnd.minute,
      );
    }
  }

  Future<void> _saveReadDebit(bool val) async {
    setState(() => _readDebit = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('read_debit_notifications', val);
  }

  @override
  Widget build(BuildContext context) {
    final googleAuth = context.watch<GoogleAuthProvider>();
    final acc = googleAuth.currentAccount;
    final sysConfig = context.watch<SystemConfigProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final affiliate = context.watch<AffiliateProvider>();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 24),
            SizedBox(width: 8),
            Text(
              'Cài đặt & Quản lý',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFF0284C7)),
            onPressed: () => _openZaloSupport(sysConfig.hotline),
            tooltip: 'Hỗ trợ kỹ thuật',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ==========================================
          // 1. THẺ THÔNG TIN TÀI KHOẢN ĐỒNG BỘ 100%
          // ==========================================
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        acc.initial.isNotEmpty ? acc.initial : (acc.name.isNotEmpty ? acc.name[0].toUpperCase() : 'V'),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                acc.name.isNotEmpty ? acc.name : 'Chủ Cửa Hàng',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: acc.effectiveIsActivated ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                acc.effectiveIsActivated ? 'Đã kích hoạt' : 'Hết hạn',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: acc.effectiveIsActivated ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          acc.email.isNotEmpty ? acc.email : 'autobank@gmail.com',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Cửa hàng: ${acc.shop.isNotEmpty ? acc.shop : 'Chưa đặt tên'}',
                                style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          acc.isLifetime
                              ? 'Bản quyền: Vĩnh viễn trọn đời'
                              : 'Hạn dùng: ${dateFormat.format(acc.expireDate)}',
                          style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ==========================================
          // 2. BANNER GÓI BẢN QUYỀN ĐỒNG BỘ THỜI GIAN THẬT
          // ==========================================
          GestureDetector(
            onTap: () {
              if (widget.onNavigateToRegister != null) {
                widget.onNavigateToRegister!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterSubscriptionPage()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x261D4ED8), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFDE047), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gói đang dùng: ${acc.effectivePackageName}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          acc.effectiveIsActivated
                              ? 'Thời hạn đến ${dateFormat.format(acc.expireDate)} · VIP 24/7'
                              : 'Bản quyền đã hết hạn · Nhấn để gia hạn ngay',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          acc.effectiveIsActivated ? 'Gia hạn' : 'Nâng cấp',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ==========================================
          // 3. Ô TÌM KIẾM TÍNH NĂNG
          // ==========================================
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm cài đặt nhanh...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ==========================================
          // 4. LƯỚI 8 Ô DANH MỤC QUẢN LÝ (GRID CARDS 2 CỘT)
          // ==========================================
          const Text(
            'Danh mục quản lý',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 12) / 2;

              final allCards = [
                // Ô 1: Kiếm tiền & Giới thiệu
                _GridItemData(
                  title: 'Kiếm tiền & Giới thiệu',
                  desc: 'Hoa hồng 5k - 120k, rút tiền về tài khoản',
                  icon: Icons.monetization_on_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showAffiliateSheet(context, affiliate, sysConfig),
                ),

                // Ô 2: Quầy thu ngân thông minh
                _GridItemData(
                  title: 'Quầy thu ngân',
                  desc: 'Mã QR thanh toán của quán, đèn chớp xanh',
                  icon: Icons.storefront_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showCashierSheet(context, txProvider),
                ),

                // Ô 3: Âm thanh & Giọng đọc
                _GridItemData(
                  title: 'Âm thanh & Hiển thị',
                  desc: 'Câu đọc, đọc tiền ra, im lặng ban đêm',
                  icon: Icons.volume_up_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showAudioSettingsSheet(context, txProvider),
                ),

                // Ô 4: Báo cáo & Thống kê doanh thu
                _GridItemData(
                  title: 'Báo cáo & Thống kê',
                  desc: 'Doanh thu ngày/tháng, sổ thu chi, xuất Excel',
                  icon: Icons.bar_chart_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showReportAndAnalyticsSheet(context, txProvider),
                ),

                // Ô 5: Nghe thông báo & Thiết bị
                _GridItemData(
                  title: 'Nghe thông báo',
                  desc: 'Cài đặt máy, tối ưu pin, 65+ ngân hàng',
                  icon: Icons.notifications_active_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showNotificationHealthSheet(context),
                ),

                // Ô 6: Tiện ích & Live Web
                _GridItemData(
                  title: 'Tiện ích & Live Web',
                  desc: 'Chia sẻ loa web 24/7, mã PIN bảo vệ',
                  icon: Icons.cell_tower_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showLiveShareSettingsSheet(context),
                ),

                // Ô 7: Trợ giúp & Hướng dẫn (PHÁT VIDEO YOUTUBE NGAY TRONG APP)
                _GridItemData(
                  title: 'Trợ giúp & Hỗ trợ',
                  desc: 'Video hướng dẫn cài đặt, Zalo 24/7',
                  icon: Icons.support_agent_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showHelpSupportSheet(context, sysConfig),
                ),

                // Ô 8: Pháp lý & Bảo mật
                _GridItemData(
                  title: 'Pháp lý & Bảo mật',
                  desc: 'Chính sách riêng tư, điều khoản, đăng xuất',
                  icon: Icons.verified_user_rounded,
                  iconGradient: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                  onTap: () => _showLegalSecuritySheet(context, googleAuth),
                ),
              ];

              final filteredCards = _searchQuery.isEmpty
                  ? allCards
                  : allCards.where((c) {
                      final str = '${c.title} ${c.desc}'.toLowerCase();
                      return str.contains(_searchQuery);
                    }).toList();

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: filteredCards.map((item) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildGridCard(item),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // KÊNH HỖ TRỢ & MẠNG XÃ HỘI CHÍNH THỨC
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hub_rounded, size: 18, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text(
                      'Kênh hỗ trợ & Đánh giá chính thức',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // 1. YouTube
                    Expanded(
                      child: _buildSocialAppTile(
                        icon: Icons.play_arrow_rounded,
                        iconColor: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFFEF2F2),
                        borderColor: const Color(0xFFFECACA),
                        label: 'YouTube',
                        subLabel: 'Video HD',
                        onTap: () {
                          final yt = sysConfig.youtubeLink.isNotEmpty
                              ? sysConfig.youtubeLink
                              : sysConfig.youtubeGuideUrl;
                          if (yt.isNotEmpty) {
                            NotificationService.openUrl(yt);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 2. Zalo
                    Expanded(
                      child: _buildSocialAppTile(
                        icon: Icons.chat_bubble_rounded,
                        iconColor: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFF0F9FF),
                        borderColor: const Color(0xFFBAE6FD),
                        label: 'Zalo 24/7',
                        subLabel: sysConfig.hotline,
                        onTap: () => _openZaloSupport(sysConfig.hotline),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 3. TikTok
                    Expanded(
                      child: _buildSocialAppTile(
                        icon: Icons.music_note_rounded,
                        iconColor: const Color(0xFF0F172A),
                        bgColor: const Color(0xFFF1F5F9),
                        borderColor: const Color(0xFFCBD5E1),
                        label: 'TikTok',
                        subLabel: 'Mẹo hay',
                        onTap: () {
                          final tt = sysConfig.tiktok.trim();
                          if (tt.isNotEmpty) {
                            final url = tt.startsWith('http') ? tt : 'https://www.tiktok.com/@$tt';
                            NotificationService.openUrl(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kênh TikTok chính thức đang được cập nhật!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 4. Đánh giá Google Play
                    Expanded(
                      child: _buildSocialAppTile(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFFFBEB),
                        borderColor: const Color(0xFFFDE68A),
                        label: 'Đánh giá',
                        subLabel: '5 sao Play',
                        onTap: () {
                          final rateUrl = sysConfig.ratingUrl.isNotEmpty ? sysConfig.ratingUrl : sysConfig.chplayLink;
                          if (rateUrl.isNotEmpty) {
                            NotificationService.openUrl(rateUrl);
                          } else {
                            AppInAppRatingDialog.showDirectRating(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hiển thị Phiên bản ứng dụng cố định 1.0.0
          const Center(
            child: Column(
              children: [
                Text(
                  'Phiên bản 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bản quyền thuộc về AutoBank System © 2026',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSheetLeadingIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Icon(icon, color: const Color(0xFF0284C7), size: 20),
    );
  }

  Widget _buildSocialAppTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(_GridItemData item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Icon(item.icon, color: const Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.desc,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Text(
                    'Xem thêm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0284C7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 1: KIẾM TIỀN & GIỚI THIỆU
  // ==========================================
  void _showAffiliateSheet(BuildContext context, AffiliateProvider affiliate, SystemConfigProvider sysConfig) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Kiếm tiền & Giới thiệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 14),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _buildSheetLeadingIcon(Icons.wallet_rounded),
                title: const Text('Ví hoa hồng & Chính sách thưởng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Số dư: ${CurrencyFormatter.formatVND(affiliate.availableBalance)} · Thưởng 10k - 120k/gói & Rút tiền về STK', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AffiliateEarnPage()));
                },
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _buildSheetLeadingIcon(Icons.card_giftcard_rounded),
                title: Text('Mã giới thiệu của bạn: ${affiliate.myReferralCode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Bấm để sao chép mã và chia sẻ cho bạn bè', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.copy_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: affiliate.myReferralCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép mã giới thiệu: ${affiliate.myReferralCode}!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 2: QUẦY THU NGÂN
  // ==========================================
  void _showCashierSheet(BuildContext context, TransactionProvider txProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 36),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Quầy Thu Ngân Thông Minh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 14),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildSheetLeadingIcon(Icons.point_of_sale_rounded),
                  title: const Text('Mở màn hình Quầy Thu Ngân', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Giao diện hiển thị mã QR và radar nghe tiền vào 24/7', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PosSmartCashierPage()));
                  },
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildSheetLeadingIcon(Icons.add_photo_alternate_rounded),
                  title: const Text('Tải ảnh mã QR của quán từ máy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Tự động lưu và hiển thị cho khách quét', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.upload_file_rounded, size: 18),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final img = await ImagePickerService.pickImageAsBase64();
                    if (img != null && img.isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('pos_user_uploaded_qr_image');
                      await prefs.setString('pos_user_uploaded_qr_image', img);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Đã cập nhật ảnh mã QR quầy thành công!'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF0284C7),
                  title: const Text('Chớp viền xanh khi nhận tiền', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Hiệu ứng trực quan thông báo tiền đã vào tài khoản', style: TextStyle(fontSize: 12)),
                  value: _strobeEffectEnabled,
                  onChanged: (val) async {
                    setSheetState(() => _strobeEffectEnabled = val);
                    setState(() => _strobeEffectEnabled = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('strobe_effect_enabled', val);
                  },
                ),
                const Divider(),

                // CẤU HÌNH THỜI GIAN ĐÓNG THÔNG BÁO NHẬN TIỀN (Mặc định 10s)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildSheetLeadingIcon(Icons.timer_rounded),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thời gian hiển thị thông báo nhận tiền',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tự động đóng popup sau 10 giây (Mặc định) hoặc tùy chỉnh để trả về mã QR',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [5, 10, 15, 30].map((sec) {
                          final isSel = txProvider.alertDisplayDurationSeconds == sec;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () {
                                  txProvider.setAlertDisplayDuration(sec);
                                  setSheetState(() {});
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    sec == 10 ? '10s (Mặc định)' : '${sec}s',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 3: ÂM THANH & HIỂN THỊ
  // ==========================================
  void _showAudioSettingsSheet(BuildContext context, TransactionProvider txProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 36),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Cài đặt Âm thanh & Giọng đọc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 14),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _buildSheetLeadingIcon(Icons.campaign_rounded),
                title: const Text('Tùy chỉnh mẫu câu đọc chi tiết', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Thêm tên quán, câu chúc mừng, đọc số tiền', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceSettingsPage()));
                },
              ),
              const Divider(),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF0284C7),
                title: const Text('Đọc biến động tiền ra (Debit)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Đọc cả giao dịch chuyển tiền đi hoặc thanh toán hóa đơn', style: TextStyle(fontSize: 12)),
                value: _readDebit,
                onChanged: (val) {
                  setSheetState(() => _readDebit = val);
                  _saveReadDebit(val);
                },
              ),
              const Divider(),

              // CHẾ ĐỘ IM LẶNG BAN ĐÊM (CÓ TÙY CHỈNH THỜI GIAN THEO Ý MUỐN)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _quietHoursEnabled ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _quietHoursEnabled ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bedtime_rounded,
                              color: _quietHoursEnabled ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Chế độ im lặng ban đêm',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _quietHoursEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF0284C7),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFCBD5E1),
                          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                          onChanged: (val) async {
                            setSheetState(() => _quietHoursEnabled = val);
                            setState(() => _quietHoursEnabled = val);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('quiet_hours_enabled', val);
                            TtsService().updateSchedule(
                              enabled: val,
                              startHour: _quietStart.hour,
                              startMinute: _quietStart.minute,
                              endHour: _quietEnd.hour,
                              endMinute: _quietEnd.minute,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _quietHoursEnabled
                          ? 'Đang tự động tắt loa từ ${_quietStart.format(context)} đến ${_quietEnd.format(context)}'
                          : 'Tự động tắt loa theo khung giờ nghỉ ngơi bạn cài đặt',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),

                    // 2 NÚT TÙY CHỈNH GIỜ BẮT ĐẦU VÀ GIỜ KẾT THÚC
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickCustomQuietTime(true, setSheetState),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Từ giờ:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      Text(
                                        _quietStart.format(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickCustomQuietTime(false, setSheetState),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.alarm_off_rounded, size: 16, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Đến giờ:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      Text(
                                        _quietEnd.format(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _buildSheetLeadingIcon(Icons.volume_up_rounded),
                title: const Text('Kiểm tra giọng đọc loa máy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Bấm để phát âm thanh thử nghiệm ngay', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.play_circle_outline_rounded, size: 20),
                onTap: () {
                  TtsService().speakTestFeedback('AutoBank xin chào quý khách, tài khoản vừa nhận năm mươi nghìn đồng');
                },
              ),
              const Divider(),

              // CẤU HÌNH THỜI GIAN ĐÓNG THÔNG BÁO NHẬN TIỀN (Mặc định 10s)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSheetLeadingIcon(Icons.timer_rounded),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thời gian hiển thị thông báo nhận tiền',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tự động đóng popup sau 10 giây (Mặc định) hoặc tùy chỉnh để trả về mã QR',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [5, 10, 15, 30].map((sec) {
                        final isSel = txProvider.alertDisplayDurationSeconds == sec;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () {
                                txProvider.setAlertDisplayDuration(sec);
                                setSheetState(() {});
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  sec == 10 ? '10s (Mặc định)' : '${sec}s',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ==========================================
  // HÀM CHỌN GIỜ TỰ DO CHO CHẾ ĐỘ IM LẶNG BAN ĐÊM
  // ==========================================
  Future<void> _pickCustomQuietTime(bool isStart, StateSetter setSheetState) async {
    final initial = isStart ? _quietStart : _quietEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'CHỌN GIỜ BẮT ĐẦU TỰ ĐỘNG TẮT LOA' : 'CHỌN GIỜ KẾT THÚC (BẬT LẠI LOA)',
      cancelText: 'HỦY',
      confirmText: 'XÁC NHẬN',
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (isStart) {
          _quietStart = picked;
          prefs.setInt('quiet_start_h', picked.hour);
          prefs.setInt('quiet_start_m', picked.minute);
        } else {
          _quietEnd = picked;
          prefs.setInt('quiet_end_h', picked.hour);
          prefs.setInt('quiet_end_m', picked.minute);
        }
      });
      setSheetState(() {});

      if (_quietHoursEnabled) {
        TtsService().updateSchedule(
          enabled: true,
          startHour: _quietStart.hour,
          startMinute: _quietStart.minute,
          endHour: _quietEnd.hour,
          endMinute: _quietEnd.minute,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0284C7),
            behavior: SnackBarBehavior.floating,
            content: Text(
              isStart
                  ? 'Đã đổi giờ tắt loa ban đêm: ${picked.format(context)}'
                  : 'Đã đổi giờ bật loa lại ban ngày: ${picked.format(context)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 4: BÁO CÁO & THỐNG KÊ DOANH THU
  // ==========================================
  void _showReportAndAnalyticsSheet(BuildContext context, TransactionProvider txProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Báo cáo & Thống kê doanh thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 14),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildSheetLeadingIcon(Icons.analytics_rounded),
              title: const Text('Xem biểu đồ & Sổ đối soát doanh thu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Biểu đồ tiền vào, số giao dịch và lọc đối soát chi tiết', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                if (widget.onNavigateToAnalytics != null) {
                  widget.onNavigateToAnalytics!();
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsPage()));
                }
              },
            ),
            const Divider(),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildSheetLeadingIcon(Icons.file_download_rounded),
              title: const Text('Xuất báo cáo giao dịch (Excel / CSV)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Đang có ${txProvider.transactions.length} giao dịch sẵn sàng xuất 3 loại file', style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.download_rounded, size: 18),
              onTap: () {
                Navigator.pop(ctx);
                _showExportReportOptionsSheet(context, txProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HÀM XUẤT 3 LOẠI BÁO CÁO DOANH THU CHUYÊN NGHIỆP (EXCEL / CSV UTF-8)
  // ==========================================
  void _showExportReportOptionsSheet(BuildContext context, TransactionProvider txProvider) {
    final allTxs = txProvider.transactions;
    final now = DateTime.now();
    final todayTxs = allTxs.where((tx) =>
      tx.transactionTime.year == now.year &&
      tx.transactionTime.month == now.month &&
      tx.transactionTime.day == now.day
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text(
              'Chọn loại báo cáo xuất file',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tệp tin Excel/CSV tiếng Việt chuẩn UTF-8 BOM, tải trực tiếp về máy mở không lỗi font chữ.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            // LOẠI 1: SỔ CHI TIẾT TOÀN BỘ GIAO DỊCH
            _buildExportOptionCard(
              icon: Icons.table_view_rounded,
              iconColor: const Color(0xFF10B981),
              title: '1. Sổ chi tiết toàn bộ giao dịch',
              badge: '${allTxs.length} giao dịch',
              desc: 'Xuất toàn bộ lịch sử: Mã GD, ngày giờ, số tiền, loại thu/chi, ngân hàng, STK, nội dung.',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportFullTransactionDetailsCsv(allTxs);
              },
            ),
            const SizedBox(height: 10),

            // LOẠI 2: BÁO CÁO DOANH THU HÔM NAY (ĐỐI SOÁT CA/NGÀY)
            _buildExportOptionCard(
              icon: Icons.today_rounded,
              iconColor: const Color(0xFF0284C7),
              title: '2. Báo cáo doanh thu Hôm nay',
              badge: '${todayTxs.length} giao dịch hôm nay',
              desc: 'Tổng hợp tiền vào, tiền ra và danh sách giao dịch trong ngày hôm nay.',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportTodayRevenueSummaryCsv(todayTxs, now);
              },
            ),
            const SizedBox(height: 10),

            // LOẠI 3: BÁO CÁO PHÂN BỔ THEO NGÂN HÀNG (THÁNG)
            _buildExportOptionCard(
              icon: Icons.account_balance_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: '3. Báo cáo phân bổ theo Ngân hàng',
              badge: 'Tổng hợp nguồn tiền',
              desc: 'Thống kê tổng tiền và tỷ trọng % theo từng ngân hàng nhận tiền.',
              onTap: () async {
                Navigator.pop(ctx);
                await _exportBankDistributionCsv(allTxs, now);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Icon(icon, color: const Color(0xFF0284C7), size: 22),
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
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.file_download_rounded, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _csvEscape(dynamic val) {
    if (val == null) return '""';
    final s = val.toString().replaceAll('"', '""');
    return '"$s"';
  }

  Future<void> _exportFullTransactionDetailsCsv(List<NormalizedTransaction> txs) async {
    final buffer = StringBuffer();
    final dFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final filenameDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'AutoBank_SoChiTietGiaoDich_$filenameDate.csv';

    buffer.writeln('${_csvEscape('STT')},${_csvEscape('Mã giao dịch')},${_csvEscape('Thời gian')},${_csvEscape('Số tiền (VNĐ)')},${_csvEscape('Loại')},${_csvEscape('Ngân hàng')},${_csvEscape('Số tài khoản')},${_csvEscape('Nội dung chuyển khoản')},${_csvEscape('Ghi chú')}');

    double totalCredit = 0;
    double totalDebit = 0;

    for (int i = 0; i < txs.length; i++) {
      final tx = txs[i];
      final isCredit = tx.type == TransactionType.credit;
      if (isCredit) {
        totalCredit += tx.amount;
      } else {
        totalDebit += tx.amount;
      }
      final typeLabel = isCredit ? 'Tiền vào (+)' : 'Tiền ra (-)';
      buffer.writeln(
        '${_csvEscape(i + 1)},'
        '${_csvEscape(tx.id)},'
        '${_csvEscape(dFormat.format(tx.transactionTime))},'
        '${_csvEscape(tx.amount.toInt())},'
        '${_csvEscape(typeLabel)},'
        '${_csvEscape(tx.bankCode)},'
        '${_csvEscape(tx.accountNumber)},'
        '${_csvEscape(tx.content)},'
        '${_csvEscape(tx.note ?? '')}'
      );
    }

    buffer.writeln('');
    buffer.writeln('${_csvEscape('TỔNG TIỀN VÀO (+)')},,,${_csvEscape(totalCredit.toInt())},${_csvEscape('VNĐ')},,,,');
    buffer.writeln('${_csvEscape('TỔNG TIỀN RA (-)')},,,${_csvEscape(totalDebit.toInt())},${_csvEscape('VNĐ')},,,,');
    buffer.writeln('${_csvEscape('DOANH THU RÒNG')},,,${_csvEscape((totalCredit - totalDebit).toInt())},${_csvEscape('VNĐ')},,,,');

    final success = await FileDownloader.downloadFile(content: buffer.toString(), filename: filename);
    _showExportSuccessNotification(filename, success);
  }

  Future<void> _exportTodayRevenueSummaryCsv(List<NormalizedTransaction> todayTxs, DateTime now) async {
    final buffer = StringBuffer();
    final dFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final dayStr = DateFormat('dd/MM/yyyy').format(now);
    final filenameDate = DateFormat('yyyyMMdd').format(now);
    final filename = 'AutoBank_DoanhThu_HomNay_$filenameDate.csv';

    double todayCredit = 0;
    double todayDebit = 0;
    for (final tx in todayTxs) {
      if (tx.type == TransactionType.credit) {
        todayCredit += tx.amount;
      } else {
        todayDebit += tx.amount;
      }
    }

    buffer.writeln('${_csvEscape('BÁO CÁO DOANH THU CỬA HÀNG TRONG NGÀY')},,,,,,');
    buffer.writeln('${_csvEscape('Ngày đối soát:')},${_csvEscape(dayStr)},,,,,');
    buffer.writeln('${_csvEscape('Tổng tiền thu vào (+):')},${_csvEscape(todayCredit.toInt())},${_csvEscape('VNĐ')},,,,');
    buffer.writeln('${_csvEscape('Tổng tiền chi ra (-):')},${_csvEscape(todayDebit.toInt())},${_csvEscape('VNĐ')},,,,');
    buffer.writeln('${_csvEscape('Doanh thu ròng hôm nay:')},${_csvEscape((todayCredit - todayDebit).toInt())},${_csvEscape('VNĐ')},,,,');
    buffer.writeln('${_csvEscape('Tổng số giao dịch:')},${_csvEscape(todayTxs.length)},${_csvEscape('giao dịch')},,,,');
    buffer.writeln('');

    buffer.writeln('${_csvEscape('STT')},${_csvEscape('Mã giao dịch')},${_csvEscape('Thời gian')},${_csvEscape('Số tiền (VNĐ)')},${_csvEscape('Loại')},${_csvEscape('Ngân hàng')},${_csvEscape('Nội dung chuyển khoản')}');

    for (int i = 0; i < todayTxs.length; i++) {
      final tx = todayTxs[i];
      final isCredit = tx.type == TransactionType.credit;
      final typeLabel = isCredit ? 'Tiền vào (+)' : 'Tiền ra (-)';
      buffer.writeln(
        '${_csvEscape(i + 1)},'
        '${_csvEscape(tx.id)},'
        '${_csvEscape(dFormat.format(tx.transactionTime))},'
        '${_csvEscape(tx.amount.toInt())},'
        '${_csvEscape(typeLabel)},'
        '${_csvEscape(tx.bankCode)},'
        '${_csvEscape(tx.content)}'
      );
    }

    final success = await FileDownloader.downloadFile(content: buffer.toString(), filename: filename);
    _showExportSuccessNotification(filename, success);
  }

  Future<void> _exportBankDistributionCsv(List<NormalizedTransaction> txs, DateTime now) async {
    final buffer = StringBuffer();
    final monthStr = DateFormat('MM/yyyy').format(now);
    final filenameDate = DateFormat('yyyy_MM').format(now);
    final filename = 'AutoBank_PhanBo_NganHang_$filenameDate.csv';

    final Map<String, int> bankCount = {};
    final Map<String, double> bankCredit = {};
    final Map<String, double> bankDebit = {};
    double totalCredit = 0;

    for (final tx in txs) {
      final bank = tx.bankCode.isEmpty ? 'Khác' : tx.bankCode.toUpperCase();
      bankCount[bank] = (bankCount[bank] ?? 0) + 1;
      if (tx.type == TransactionType.credit) {
        bankCredit[bank] = (bankCredit[bank] ?? 0) + tx.amount;
        totalCredit += tx.amount;
      } else {
        bankDebit[bank] = (bankDebit[bank] ?? 0) + tx.amount;
      }
    }

    buffer.writeln('${_csvEscape('BÁO CÁO PHÂN BỔ NGUỒN TIỀN THEO NGÂN HÀNG')},,,,,');
    buffer.writeln('${_csvEscape('Thời kỳ báo cáo:')},${_csvEscape('Tháng $monthStr')},,,,');
    buffer.writeln('${_csvEscape('Tổng doanh thu tiền vào:')},${_csvEscape(totalCredit.toInt())},${_csvEscape('VNĐ')},,,');
    buffer.writeln('${_csvEscape('Tổng số ngân hàng nhận tiền:')},${_csvEscape(bankCredit.keys.length)},,,,');
    buffer.writeln('');

    buffer.writeln('${_csvEscape('STT')},${_csvEscape('Tên ngân hàng')},${_csvEscape('Số giao dịch')},${_csvEscape('Tổng tiền nhận (+)')},${_csvEscape('Tổng tiền chi (-)')},${_csvEscape('Tỷ trọng tiền vào (%)')}');

    int index = 1;
    final sortedBanks = bankCredit.keys.toList()
      ..sort((a, b) => (bankCredit[b] ?? 0).compareTo(bankCredit[a] ?? 0));

    for (final bank in sortedBanks) {
      final credit = bankCredit[bank] ?? 0;
      final debit = bankDebit[bank] ?? 0;
      final count = bankCount[bank] ?? 0;
      final percentage = totalCredit > 0 ? (credit / totalCredit * 100).toStringAsFixed(1) : '0.0';

      buffer.writeln(
        '${_csvEscape(index++)},'
        '${_csvEscape(bank)},'
        '${_csvEscape(count)},'
        '${_csvEscape(credit.toInt())},'
        '${_csvEscape(debit.toInt())},'
        '${_csvEscape('$percentage%')}'
      );
    }

    final success = await FileDownloader.downloadFile(content: buffer.toString(), filename: filename);
    _showExportSuccessNotification(filename, success);
  }

  void _showExportSuccessNotification(String filename, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success ? 'Đã tải tệp về máy: $filename' : 'Không thể lưu file báo cáo, vui lòng thử lại',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 5: NGHE THÔNG BÁO & THIẾT BỊ
  // ==========================================
  void _showNotificationHealthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => FutureBuilder<Map<String, bool>>(
          future: Future.wait([
            NotificationService.isListenerEnabled(),
            NotificationService.isBatteryOptimizationIgnored(),
          ]).then((results) => {
            'notif': results[0],
            'battery': results[1],
          }),
          builder: (context, snapshot) {
            final isNotifGranted = snapshot.data?['notif'] ?? false;
            final isBatteryIgnored = snapshot.data?['battery'] ?? false;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trạng thái nghe thông báo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (isLoading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)))
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF0284C7)),
                          tooltip: 'Làm mới trạng thái',
                          onPressed: () => setSheetState(() {}),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isNotifGranted ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: isNotifGranted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 24,
                    ),
                    title: Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Quyền đọc thông báo Android',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isNotifGranted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isNotifGranted ? 'ĐÃ CẤP' : 'CHƯA CẤP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isNotifGranted ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text('Bắt buộc bật để đọc được biến động số dư ngân hàng', style: TextStyle(fontSize: 12)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isNotifGranted ? const Color(0xFFE2E8F0) : const Color(0xFF0284C7),
                        foregroundColor: isNotifGranted ? const Color(0xFF475569) : Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await NotificationService.openSettings();
                        if (context.mounted) {
                          setSheetState(() {});
                        }
                      },
                      child: Text(isNotifGranted ? 'Kiểm tra' : 'Cài đặt'),
                    ),
                  ),
                  const Divider(),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isBatteryIgnored ? Icons.check_circle_rounded : Icons.battery_alert_rounded,
                      color: isBatteryIgnored ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 24,
                    ),
                    title: Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Hoạt động dưới nền (Mức sử dụng pin)',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBatteryIgnored ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBatteryIgnored ? 'ĐÃ BẬT' : 'CHƯA BẬT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isBatteryIgnored ? const Color(0xFF15803D) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: const Text('Mở Thông tin ứng dụng → Mức sử dụng pin → Bật hoạt động dưới nền & Tự khởi chạy', style: TextStyle(fontSize: 11.5)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBatteryIgnored ? const Color(0xFFE2E8F0) : const Color(0xFFF59E0B),
                        foregroundColor: isBatteryIgnored ? const Color(0xFF475569) : Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await NotificationService.requestIgnoreBatteryOptimizations();
                        if (context.mounted) {
                          setSheetState(() {});
                        }
                      },
                      child: Text(isBatteryIgnored ? 'Đã tối ưu' : 'Bật ngay'),
                    ),
                  ),
                  const Divider(),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.smart_display_rounded, color: Color(0xFFEF4444)),
                    title: const Text('Video hướng dẫn chạy ngầm mượt mà hơn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Xem clip hướng dẫn chỉnh đa nhiệm & pin trên từng hãng điện thoại', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEF4444), size: 22),
                    onTap: () {
                      final sysConfig = context.read<SystemConfigProvider>();
                      Navigator.pop(ctx);
                      AppVideoGuideModal.showDirect(
                        context,
                        title: 'Sử Dụng Ứng Dụng Mượt Mà Hơn',
                        subtitle: 'Cách tối ưu pin và duy trì ứng dụng chạy ngầm 24/7 không bị tắt',
                        videoUrl: sysConfig.videoGuideSmooth,
                        badgeText: 'Chạy Ngầm Mượt Mà',
                      );
                    },
                  ),
                  const Divider(),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.speed_rounded, color: Color(0xFF8B5CF6)),
                    title: const Text('Kiểm tra toàn diện & Thử loa', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Chẩn đoán sâu 4 cấp độ: Quyền, pin, âm thanh, thông báo', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityCheckPage()));
                    },
                  ),
                  const Divider(),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_balance_rounded, color: Color(0xFF10B981)),
                    title: const Text('Danh sách 65+ Ngân hàng hỗ trợ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Vietcombank, MB, Techcombank, ACB, Momo...', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('Hỗ trợ 65+ Ngân hàng & Ví'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: BankDirectoryWidget(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 6: TIỆN ÍCH & LIVE WEB
  // ==========================================
  void _showLiveShareSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Tiện ích & Chia sẻ Live Web 24/7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Color(0xFF16A34A), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Link nghe loa từ xa 24/7:\n${AppConfig.webBaseUrl}/live',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF16A34A), size: 18),
                    tooltip: 'Sao chép link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${AppConfig.webBaseUrl}/live'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Đã sao chép link Live Web 24/7!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. MÃ BẢO MẬT LIVE WEB TỪ XA (6 SỐ - KHÁC HOÀN TOÀN MÃ PIN APP)
            Builder(
              builder: (bCtx) {
                final pinService = AppPinSecurityService();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pin_rounded, color: Color(0xFF16A34A), size: 20),
                  ),
                  title: const Text('Mã bảo mật Live Web (6 số)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Mã riêng của bạn: ${pinService.liveWebPin} · Mã 6 số duy nhất không trùng lặp', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF16A34A)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await AppPinSecurityDialogs.showLiveWebPinDialog(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 7: TRỢ GIÚP & HỖ TRỢ (PHÁT YOUTUBE NGAY TRONG APP)
  // ==========================================
  void _showHelpSupportSheet(BuildContext context, SystemConfigProvider sysConfig) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Trợ giúp & Hỗ trợ kỹ thuật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 14),

              const Text(
                'DANH MỤC VIDEO HƯỚNG DẪN',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),

              // 1. Video người mới
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEF4444)),
                title: const Text('1. Hướng dẫn người mới bắt đầu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Làm quen, đăng ký gói dùng thử và thiết lập cơ bản', style: TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppVideoGuideModal.showDirect(
                    context,
                    title: 'Hướng Dẫn Cho Người Mới',
                    subtitle: 'Video ngắn hướng dẫn làm quen và thiết lập ban đầu',
                    videoUrl: sysConfig.videoGuideNewbie,
                    badgeText: 'Người Mới',
                  );
                },
              ),
              const Divider(height: 1),

              // 2. Video dùng mượt mà hơn (pin, chạy ngầm)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
                title: const Text('2. Hướng dẫn chạy ngầm mượt mà hơn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Tắt tối ưu hóa pin, khóa đa nhiệm để không bị tắt app', style: TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppVideoGuideModal.showDirect(
                    context,
                    title: 'Sử Dụng Ứng Dụng Mượt Mà Hơn',
                    subtitle: 'Cách tối ưu pin và duy trì ứng dụng chạy ngầm 24/7 không bị tắt',
                    videoUrl: sysConfig.videoGuideSmooth,
                    badgeText: 'Chạy Ngầm Mượt Mà',
                  );
                },
              ),
              const Divider(height: 1),

              // 3. Video giới thiệu bạn bè & rút tiền
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981)),
                title: const Text('3. Hướng dẫn giới thiệu bạn bè & Rút tiền', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Cách chia sẻ link, nhận hoa hồng và tạo lệnh rút tiền', style: TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppVideoGuideModal.showDirect(
                    context,
                    title: 'Tiếp Thị & Rút Tiền Hoa Hồng',
                    subtitle: 'Cách nhận hoa hồng giới thiệu và rút về tài khoản ngân hàng',
                    videoUrl: sysConfig.videoGuideAffiliate,
                    badgeText: 'Giới Thiệu Bạn Bè',
                  );
                },
              ),
              const Divider(height: 1),

              // 4. Video trang đọc lại
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, color: Color(0xFF0284C7)),
                title: const Text('4. Hướng dẫn sử dụng trang Đọc lại', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Tra cứu biến động, nghe lại thông báo và lọc dòng tiền', style: TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppVideoGuideModal.showDirect(
                    context,
                    title: 'Hướng Dẫn Trang Đọc Lại',
                    subtitle: 'Cách nghe lại thông báo và theo dõi dòng tiền',
                    videoUrl: sysConfig.videoGuideHistory,
                    badgeText: 'Trang Đọc Lại',
                  );
                },
              ),
              const Divider(height: 1),

              // 5. Video trang câu đọc
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF8B5CF6)),
                title: const Text('5. Hướng dẫn tối ưu câu đọc', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Cá nhân hóa mẫu câu, gắn tên shop và lời cảm ơn', style: TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppVideoGuideModal.showDirect(
                    context,
                    title: 'Hướng Dẫn Tối Ưu Câu Đọc',
                    subtitle: 'Cá nhân hóa câu đọc và giọng phát thanh',
                    videoUrl: sysConfig.videoGuideVoice,
                    badgeText: 'Trang Câu Đọc',
                  );
                },
              ),
              const Divider(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF0284C7)),
                title: const Text('Zalo hỗ trợ trực tiếp 24/7', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Số hotline: ${sysConfig.hotline}', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  _openZaloSupport(sysConfig.hotline);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openZaloSupport(String hotline) {
    final cleanPhone = hotline.replaceAll(RegExp(r'[^0-9]'), '');
    Clipboard.setData(ClipboardData(text: hotline));
    if (!kIsWeb) {
      NotificationService.openUrl('https://zalo.me/$cleanPhone');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã sao chép số Zalo: $hotline! Đang mở Zalo...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // BẢNG CHỌN DANH MỤC 8: PHÁP LÝ & BẢO MẬT
  // ==========================================
  void _showLegalSecuritySheet(BuildContext context, GoogleAuthProvider googleAuth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Pháp lý & Bảo mật tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 14),

              // MỤC MÃ PIN BẢO MẬT 4 SỐ - ĐỒNG BỘ TỨC THÌ QUA LISTENALBE
              ListenableBuilder(
                listenable: AppPinSecurityService(),
                builder: (pCtx, _) {
                  final pinService = AppPinSecurityService();
                  final isPinOn = pinService.isPinEnabled;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pin_rounded, color: Color(0xFF0284C7), size: 22),
                    ),
                    title: const Text('Mã PIN bảo mật ứng dụng (4 số)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      isPinOn ? 'Đang bật mã PIN bảo vệ 4 số khi mở app' : 'Chưa cài đặt mã PIN bảo vệ',
                      style: TextStyle(fontSize: 12, color: isPinOn ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPinOn ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isPinOn ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            isPinOn ? 'Đang bật' : 'Chưa bật',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPinOn ? const Color(0xFF166534) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                      ],
                    ),
                    onTap: () async {
                      if (!isPinOn) {
                        final success = await AppPinSecurityDialogs.showSetPinDialog(context);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Đã kích hoạt mã PIN 4 số bảo mật ứng dụng thành công!'),
                              backgroundColor: Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        // Menu tùy chọn: Đổi mã PIN hoặc Tắt mã PIN
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (optCtx) => SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Quản Lý Mã PIN 4 Số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  ListTile(
                                    leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFF0284C7)),
                                    title: const Text('Đổi mã PIN mới (4 số)'),
                                    subtitle: const Text('Yêu cầu nhập mã PIN cũ để xác thực', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    onTap: () async {
                                      Navigator.pop(optCtx);
                                      await AppPinSecurityDialogs.showChangePinDialog(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.lock_open_rounded, color: Color(0xFFDC2626)),
                                    title: const Text('Tắt bảo vệ mã PIN', style: TextStyle(color: Color(0xFFDC2626))),
                                    subtitle: const Text('Yêu cầu nhập mã PIN cũ để tắt', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    onTap: () async {
                                      Navigator.pop(optCtx);
                                      final ok = await AppPinSecurityDialogs.showDisablePinDialog(context);
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã tắt mã PIN bảo vệ ứng dụng.')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              const Divider(),

              // MỤC ĐÁNH GIÁ 5 SAO
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                title: const Text('Đánh giá 5 sao trên CH Play (Google Play)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Mở trực tiếp trang CH Play để viết đánh giá 5 sao cho ứng dụng', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF01875F)),
                onTap: () {
                  Navigator.pop(ctx);
                  AppInAppRatingDialog.showDirectRating(context);
                },
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.policy_rounded, color: Color(0xFF64748B)),
                title: const Text('Chính sách quyền riêng tư', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Bảo mật tuyệt đối thông tin biến động tài khoản ngân hàng', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Chính sách riêng tư'),
                      content: const Text(
                        'AutoBank cam kết bảo mật 100% dữ liệu ngân hàng. Mọi giao dịch được đọc cục bộ trên máy và không chia sẻ cho bên thứ ba trái phép.',
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Đóng'))],
                    ),
                  );
                },
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_rounded, color: Color(0xFF64748B)),
                title: const Text('Điều khoản sử dụng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Quy định sử dụng dịch vụ thông báo số dư', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Điều khoản dịch vụ'),
                      content: const Text(
                        'Người dùng sử dụng dịch vụ thông báo nhận tiền để phục vụ mục đích bán hàng, quản lý kinh doanh hợp pháp theo pháp luật Việt Nam.',
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Đóng'))],
                    ),
                  );
                },
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFD97706)),
                title: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFD97706))),
                onTap: () {
                  Navigator.pop(ctx);
                  googleAuth.signOut();
                },
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
                title: const Text('Xóa tài khoản vĩnh viễn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Xác nhận xóa tài khoản?'),
                      content: const Text('Mọi dữ liệu gói cước và lịch sử giao dịch sẽ bị xóa vĩnh viễn khỏi hệ thống.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Hủy')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dCtx);
                            googleAuth.signOut();
                          },
                          child: const Text('Xóa ngay', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridItemData {
  final String title;
  final String desc;
  final IconData icon;
  final List<Color> iconGradient;
  final VoidCallback onTap;

  _GridItemData({
    required this.title,
    required this.desc,
    required this.icon,
    required this.iconGradient,
    required this.onTap,
  });
}

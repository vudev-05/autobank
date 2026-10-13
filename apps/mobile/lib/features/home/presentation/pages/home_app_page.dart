import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../../../transactions/domain/entities/normalized_transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class HomeAppPage extends StatefulWidget {
  final VoidCallback? onNavigateToVoiceSettings;
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onNavigateToGuide;

  const HomeAppPage({
    super.key,
    this.onNavigateToVoiceSettings,
    this.onNavigateToRegister,
    this.onNavigateToGuide,
  });

  @override
  State<HomeAppPage> createState() => _HomeAppPageState();
}

class _HomeAppPageState extends State<HomeAppPage> with SingleTickerProviderStateMixin {
  bool _isSpeakerActive = true;
  bool _showTransactions = true;
  String _sharePin = '889922'; // Mã 6 số mặc định, có thể đổi tùy ý

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Đồng bộ mã PIN lên backend NestJS
    _syncPinToBackend(_sharePin);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _syncPinToBackend(String pin) async {
    try {
      final uri = Uri.parse('http://localhost:3000/admin/live-pin');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  void _generateRandomPin() {
    final random = Random();
    final newPin = (100000 + random.nextInt(900000)).toString();
    setState(() {
      _sharePin = newPin;
    });
    _syncPinToBackend(newPin);
  }

  void _toggleSpeaker(TransactionProvider txProvider) {
    setState(() {
      _isSpeakerActive = !_isSpeakerActive;
    });
    txProvider.toggleTts(_isSpeakerActive);
    HapticFeedback.heavyImpact();
  }

  void _handleReplay(TransactionProvider txProvider) {
    HapticFeedback.lightImpact();
    final hasLast = txProvider.lastSpokenSentence.isNotEmpty;
    if (hasLast) {
      TtsService().speakSentence(txProvider.lastSpokenSentence);
    }
    txProvider.replayLastSentence();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
        content: Row(
          children: [
            const Icon(Icons.replay_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(hasLast ? 'Đang phát lại câu thông báo gần nhất...' : 'Chưa có thông báo gần đây để đọc lại'),
          ],
        ),
      ),
    );
  }

  void _handleToggleRepeat(TransactionProvider txProvider) {
    HapticFeedback.lightImpact();
    txProvider.toggleRepeatTwice();

    final isRepeat = txProvider.isRepeatTwiceEnabled;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isRepeat ? WebTheme.emerald : const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
        content: Row(
          children: [
            Icon(isRepeat ? Icons.repeat_on_rounded : Icons.repeat_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(isRepeat ? 'Đã BẬT chế độ nhắc lại (Đọc 1 lần và nhắc lại x2)' : 'Đã TẮT nhắc lại (Chỉ đọc 1 lần)'),
          ],
        ),
      ),
    );
  }

  void _handleToggleHistory() {
    HapticFeedback.lightImpact();
    setState(() {
      _showTransactions = !_showTransactions;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _showTransactions ? const Color(0xFF0284C7) : const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
        content: Row(
          children: [
            Icon(_showTransactions ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(_showTransactions ? 'Đã hiển thị lịch sử giao dịch' : 'Đã ẩn lịch sử giao dịch (Bảo mật quầy thu ngân)'),
          ],
        ),
      ),
    );
  }

  void _showShareLiveModal(BuildContext context) {
    final pinController = TextEditingController(text: _sharePin);
    final shareUrl = 'http://localhost:5173/live.html?code=$_sharePin';
    final qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(shareUrl)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phonelink_ring_rounded, color: Color(0xFF0284C7), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Chia sẻ phát loa (PC / iPhone)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: WebTheme.textMuted),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chia sẻ link để người khác mở trên máy tính hoặc iPhone/iPad cùng nghe phát loa tiền về theo thời gian thực.',
                    style: TextStyle(fontSize: 12, color: WebTheme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // KHỐI THIẾT LẬP MÃ PIN 6 SỐ
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MÃ BẢO MẬT 6 SỐ (BẮT BUỘC NHẬP KHI MỞ LINK)',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
                            ),
                            Icon(Icons.lock_rounded, size: 14, color: Color(0xFF0284C7)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: pinController,
                                maxLength: 6,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                  color: Color(0xFF0284C7),
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  if (val.length == 6) {
                                    setState(() => _sharePin = val);
                                    _syncPinToBackend(val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0284C7)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                _generateRandomPin();
                                pinController.text = _sharePin;
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF0284C7)),
                              label: const Text('Mã mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // KHỐI ĐƯỜNG LINK & NÚT COPY
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ĐƯỜNG DẪN TRANG WEB TRỰC TIẾP:',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'http://localhost:5173/live.html?code=$_sharePin',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WebTheme.emerald,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: 'http://localhost:5173/live.html?code=$_sharePin'));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: WebTheme.emerald,
                                      content: Text('Đã sao chép link phát loa kèm mã PIN!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                                label: const Text('Sao chép Link', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // MÃ QR ĐỂ QUÉT TỪ CAMERA IPHONE / MÁY TÍNH
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                      border: Border.all(color: WebTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hoặc mở camera iPhone / iPad quét mã QR bên dưới:',
                          style: TextStyle(fontSize: 11.5, color: WebTheme.textMuted),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            qrImageUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.qr_code_2_rounded, size: 100, color: WebTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    '🔒 Bảo mật: Chỉ người có mã PIN 6 số mới có thể xem biến động số dư và nghe âm thanh tiền về.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: WebTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sysConfig = context.watch<SystemConfigProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;

    return Scaffold(
      backgroundColor: WebTheme.slateBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: WebTheme.primary,
          onRefresh: () async {
            await Future.wait([
              sysConfig.fetchConfig(),
              txProvider.loadLocalTransactions(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thông báo bảo trì nếu Admin cấu hình từ SQL
                if (sysConfig.maintenance)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.engineering_rounded, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sysConfig.maintenanceMsg.isNotEmpty
                                ? sysConfig.maintenanceMsg
                                : 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ. Vui lòng quay lại sau ít phút.',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Thông báo quyền truy cập thông báo Android nếu chưa cấp
                if (!txProvider.isPermissionGranted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_paused_rounded, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Chưa cấp Quyền đọc thông báo ngân hàng',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ứng dụng cần quyền này để tự động đọc loa khi điện thoại nhận tiền.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => NotificationService.openSettings(),
                          child: const Text('Cấp quyền'),
                        ),
                      ],
                    ),
                  ),

                // 1. THANH HEADER THƯƠNG HIỆU CHUẨN WEB (LOGO + SLOGAN + STATUS)
                _buildBrandHeader(sysConfig),

                const SizedBox(height: 16),

                // 2. NÚT TẮT BẬT TO ĐÙNG NẰM TRÊN ĐẦU (MASTER ON/OFF POWER BUTTON)
                _buildMasterPowerButton(txProvider),

                const SizedBox(height: 16),

                // 3. BỘ 4 NÚT HÀNH ĐỘNG DƯỚI NÚT ON/OFF: ĐỌC LẠI, NHẮC LẠI, ẨN/HIỆN LỊCH SỬ, CHIA SẺ
                _buildControlActionsRow(txProvider),

                const SizedBox(height: 16),

                // 4. THẺ DOANH THU HÔM NAY (PULSE CARD - KHÔNG CÓ NÚT TEST)
                _buildTodayPulseCard(txProvider),

                const SizedBox(height: 16),

                // 5. BỘ 4 PHÍM TẮT TIỆN ÍCH HỆ THỐNG
                _buildQuickActionsGrid(sysConfig),

                const SizedBox(height: 16),

                // 6. DANH SÁCH BIẾN ĐỘNG SỐ DƯ GẦN NHẤT (CÓ CHẾ ĐỘ ẨN/HIỆN)
                _buildTransactionFeedCard(transactions),

                const SizedBox(height: 14),

                // 7. THÔNG TIN HỆ THỐNG ĐỒNG BỘ TỪ SQL
                _buildSystemInfoFooter(sysConfig),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header chuẩn thương hiệu
  Widget _buildBrandHeader(SystemConfigProvider sysConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: WebTheme.cardDecoration(
        color: Colors.white,
        border: Border.all(color: WebTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WebTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: WebTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(WebTheme.radiusMd),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: WebTheme.primary,
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sysConfig.brandName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.textHeading,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sysConfig.brandSlogan,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: WebTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: WebTheme.badgeDecoration(
              bgColor: sysConfig.isServerConnected ? WebTheme.emeraldLight : const Color(0xFFFEF3C7),
              borderColor: sysConfig.isServerConnected ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: sysConfig.isServerConnected ? WebTheme.emerald : const Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  sysConfig.isServerConnected ? 'Trực tuyến 24/7' : 'Đang kết nối',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sysConfig.isServerConnected ? WebTheme.emerald : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. NÚT TẮT BẬT TO ĐÙNG NẰM TRÊN ĐẦU (MASTER ON/OFF POWER BUTTON NHƯ HÌNH MẪU)
  Widget _buildMasterPowerButton(TransactionProvider txProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isSpeakerActive ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isSpeakerActive ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // NÚT NGUỒN POWER TO ĐÙNG
          GestureDetector(
            onTap: () => _toggleSpeaker(txProvider),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isSpeakerActive ? _pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSpeakerActive
                        ? const [Color(0xFF22C55E), Color(0xFF15803D)]
                        : const [Color(0xFF94A3B8), Color(0xFF475569)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSpeakerActive ? const Color(0xFF22C55E) : const Color(0xFF475569)).withValues(alpha: 0.38),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        size: 36,
                        color: _isSpeakerActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // DÒNG CHỮ TRẠNG THÁI TO ĐẬM DƯỚI NÚT NGUỒN
          Text(
            _isSpeakerActive ? 'Thông báo đang bật' : 'Thông báo đang tắt',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _isSpeakerActive ? const Color(0xFF15803D) : const Color(0xFFDC2626),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _isSpeakerActive
                ? 'Loa sẵn sàng đọc thông báo tức thì khi có biến động số dư'
                : 'Chạm nút nguồn to ở trên để bật phát loa thông báo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: WebTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 3. BỘ 4 NÚT HÀNH ĐỘNG: ĐỌC LẠI, NHẮC LẠI, ẨN/HIỆN LỊCH SỬ, CHIA SẺ
  Widget _buildControlActionsRow(TransactionProvider txProvider) {
    return Row(
      children: [
        // 1. ĐỌC LẠI
        Expanded(
          child: _buildControlSquareBtn(
            icon: Icons.replay_rounded,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFEFF6FF),
            label: 'Đọc lại',
            subLabel: 'Nghe lại',
            onTap: () => _handleReplay(txProvider),
          ),
        ),
        const SizedBox(width: 8),

        // 2. NHẮC LẠI (x2)
        Expanded(
          child: _buildControlSquareBtn(
            icon: txProvider.isRepeatTwiceEnabled ? Icons.repeat_on_rounded : Icons.repeat_rounded,
            iconColor: txProvider.isRepeatTwiceEnabled ? const Color(0xFF15803D) : const Color(0xFF7C3AED),
            bgColor: txProvider.isRepeatTwiceEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFF5F3FF),
            label: 'Nhắc lại',
            subLabel: txProvider.isRepeatTwiceEnabled ? 'Bật (x2)' : 'Tắt (x1)',
            isHighlighted: txProvider.isRepeatTwiceEnabled,
            onTap: () => _handleToggleRepeat(txProvider),
          ),
        ),
        const SizedBox(width: 8),

        // 3. ẨN / HIỆN LỊCH SỬ
        Expanded(
          child: _buildControlSquareBtn(
            icon: _showTransactions ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            iconColor: _showTransactions ? const Color(0xFFD97706) : const Color(0xFF64748B),
            bgColor: _showTransactions ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
            label: _showTransactions ? 'Ẩn L.Sử' : 'Hiện L.Sử',
            subLabel: _showTransactions ? 'Đang hiện' : 'Đang ẩn',
            onTap: _handleToggleHistory,
          ),
        ),
        const SizedBox(width: 8),

        // 4. CHIA SẺ (PC / IPHONE)
        Expanded(
          child: _buildControlSquareBtn(
            icon: Icons.ios_share_rounded,
            iconColor: const Color(0xFF0D9488),
            bgColor: const Color(0xFFCCFBF1),
            label: 'Chia sẻ',
            subLabel: 'PC / iPhone',
            onTap: () => _showShareLiveModal(context),
          ),
        ),
      ],
    );
  }

  Widget _buildControlSquareBtn({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String subLabel,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              width: isHighlighted ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: WebTheme.textHeading,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? const Color(0xFF15803D) : WebTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Thẻ thống kê doanh thu và giao dịch hôm nay (Không có nút test)
  Widget _buildTodayPulseCard(TransactionProvider txProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hôm nay nhận được',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WebTheme.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: WebTheme.badgeDecoration(
                  bgColor: WebTheme.emeraldLight,
                  borderColor: const Color(0xFF86EFAC),
                ),
                child: Text(
                  _showTransactions ? '${txProvider.todayCount} giao dịch' : '** giao dịch',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Số tiền hiển thị (nếu ẩn lịch sử thì che bảo mật)
          Text(
            _showTransactions
                ? '+${CurrencyFormatter.formatVND(txProvider.todayTotal)}'
                : '****** đ',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: WebTheme.emerald,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Bộ 4 phím tắt tiện ích
  Widget _buildQuickActionsGrid(SystemConfigProvider sysConfig) {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            icon: Icons.record_voice_over_rounded,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            label: 'Câu đọc',
            onTap: () {
              widget.onNavigateToVoiceSettings?.call();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            icon: Icons.diamond_rounded,
            iconColor: WebTheme.primary,
            bgColor: WebTheme.primaryBg,
            label: 'Đăng ký gói',
            onTap: () {
              widget.onNavigateToRegister?.call();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            icon: Icons.battery_charging_full_rounded,
            iconColor: WebTheme.emerald,
            bgColor: WebTheme.emeraldLight,
            label: 'Chạy ngầm',
            onTap: () {
              widget.onNavigateToGuide?.call();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionTile(
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
            label: 'Hotline 24/7',
            onTap: () {
              Clipboard.setData(ClipboardData(text: sysConfig.hotline));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép hotline ${sysConfig.hotline}!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WebTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: WebTheme.cardDecoration(
          border: Border.all(color: WebTheme.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: WebTheme.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Danh sách biến động số dư gần nhất (có hỗ trợ Ẩn / Hiện)
  Widget _buildTransactionFeedCard(List<NormalizedTransaction> transactions) {
    if (!_showTransactions) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_rounded, size: 36, color: Color(0xFF64748B)),
            const SizedBox(height: 8),
            const Text(
              'Lịch sử giao dịch đang được ẩn',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WebTheme.textHeading),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chế độ riêng tư tại quầy thu ngân đang bật. Chạm nút "Hiện L.Sử" ở trên nếu bạn muốn xem lại chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: WebTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 18, color: WebTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Biến động số dư gần nhất',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WebTheme.textHeading,
                    ),
                  ),
                ],
              ),
              Text(
                '${transactions.length} tin',
                style: const TextStyle(fontSize: 12, color: WebTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text(
                'Chưa có thông báo nhận tiền mới.\n(Ứng dụng đang chạy ngầm lắng nghe thông báo ngân hàng 24/7)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted, height: 1.4),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.take(4).length,
              separatorBuilder: (_, _) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: WebTheme.primaryBg,
                        borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                        border: Border.all(color: WebTheme.primaryLight),
                      ),
                      child: Text(
                        tx.bankCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: WebTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: WebTheme.textHeading,
                            ),
                          ),
                          Text(
                            'Lúc ${tx.transactionTime.hour}:${tx.transactionTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${CurrencyFormatter.formatVND(tx.amount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: WebTheme.emerald,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // 7. Footer thông tin máy chủ từ SQL
  Widget _buildSystemInfoFooter(SystemConfigProvider sysConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WebTheme.radiusMd),
        border: Border.all(color: WebTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: WebTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                'Phiên bản: ${sysConfig.latestVersion}',
                style: const TextStyle(fontSize: 11, color: WebTheme.textMuted),
              ),
            ],
          ),
          Text(
            'Hỗ trợ: ${sysConfig.hotline}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: WebTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

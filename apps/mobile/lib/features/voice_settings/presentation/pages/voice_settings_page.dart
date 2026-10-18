import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../../auth/presentation/providers/google_auth_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../providers/voice_settings_provider.dart';

class VoiceSettingsPage extends StatefulWidget {
  final VoidCallback? onNavigateToRegister;
  const VoiceSettingsPage({super.key, this.onNavigateToRegister});

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  int _activeTab = 0; // 0: Nhận Tiền, 1: Trừ Tiền

  // Từ riêng tự nhập (hiển thị ưu tiên ở đầu danh sách, khi chọn từ khác thì xóa đi)
  String? _customCreditPrefix;
  String? _customCreditSuffix;
  String? _customDebitPrefix;
  String? _customDebitSuffix;

  int _selectedAmountIndex = 1; // Mặc định 250.000 đ
  final List<Map<String, dynamic>> _sampleAmounts = [
    {'label': '50.000 ₫', 'words': 'năm mươi nghìn đồng'},
    {'label': '250.000 ₫', 'words': 'hai trăm năm mươi nghìn đồng'},
    {'label': '500.000 ₫', 'words': 'năm trăm nghìn đồng'},
    {'label': '1.500.000 ₫', 'words': 'một triệu năm trăm nghìn đồng'},
    {'label': '5.000.000 ₫', 'words': 'năm triệu đồng'},
  ];

  int _selectedDebitAmountIndex = 1; // Mặc định 150.000 đ
  final List<Map<String, dynamic>> _sampleDebitAmounts = [
    {'label': '30.000 ₫', 'words': 'ba mươi nghìn đồng'},
    {'label': '150.000 ₫', 'words': 'một trăm năm mươi nghìn đồng'},
    {'label': '500.000 ₫', 'words': 'năm trăm nghìn đồng'},
    {'label': '2.000.000 ₫', 'words': 'hai triệu đồng'},
  ];

  final List<String> _prefixOptions = [
    'Đã nhận',
    'Tài khoản vừa cộng',
    'Khách chuyển khoản',
    'Thu tiền thành công',
    'Ting ting! Đã nhận',
    'Vừa nhận được',
    'Thông báo nhận tiền',
    'Khách thanh toán',
  ];

  final List<String> _debitPrefixOptions = [
    'Đã chuyển',
    'Tài khoản vừa trừ',
    'Thanh toán thành công',
    'Chuyển khoản thành công',
    'Vừa chuyển đi',
    'Giao dịch trừ tiền',
    'Thông báo chuyển tiền',
    'Đã thanh toán',
  ];

  final List<String> _suffixOptions = [
    'Cảm ơn quý khách!',
    'Chúc ngày mới đắt hàng!',
    'Hẹn gặp lại quý khách!',
    'Cửa hàng xin cảm ơn!',
    'Cảm ơn và hẹn gặp lại!',
    'Giao dịch thành công!',
    'Không đọc lời cảm ơn',
  ];

  final List<String> _debitSuffixOptions = [
    'Giao dịch hoàn tất!',
    'Đã lưu biên lai!',
    'Thanh toán thành công!',
    'Chuyển tiền thành công!',
    'Không đọc lời kết',
  ];

  final List<Map<String, String>> _amountStyleOptions = [
    {'id': 'dong', 'label': 'Kèm "đồng" (250.000 đồng)'},
    {'id': 'vnd', 'label': 'Kèm "VNĐ" (250.000 VNĐ)'},
    {'id': 'compact', 'label': 'Rút gọn số (250.000)'},
    {'id': 'short_k', 'label': 'Giờ cao điểm (250 nghìn)'},
  ];

  final List<Map<String, String>> _bankStyleOptions = [
    {'id': 'tu', 'label': 'từ [Ngân hàng] (từ Techcombank)'},
    {'id': 'qua', 'label': 'qua [Ngân hàng] (qua Techcombank)'},
    {'id': 'vao', 'label': 'vào tài khoản [Ngân hàng]'},
    {'id': 'ten', 'label': 'Chỉ đọc tên [Ngân hàng]'},
  ];

  final List<Map<String, String>> _debitBankStyleOptions = [
    {'id': 'qua', 'label': 'qua [Ngân hàng] (qua MBBank)'},
    {'id': 'tu', 'label': 'từ tài khoản [Ngân hàng]'},
    {'id': 'bang', 'label': 'bằng [Ngân hàng]'},
    {'id': 'ten', 'label': 'Chỉ đọc tên [Ngân hàng]'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final googleAuth = context.read<GoogleAuthProvider>();
      if (googleAuth.isSignedIn && googleAuth.email.isNotEmpty) {
        context.read<VoiceSettingsProvider>().loadConfigFromBackend(googleAuth.email);
      }
    });
  }

  void _showCustomTextDialog({
    required String title,
    required String hintText,
    required String initialValue,
    required ValueChanged<String> onSaved,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusMd)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onSaved(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoiceSettingsProvider>();
    final googleAuth = context.watch<GoogleAuthProvider>();

    // Kiểm tra và khởi tạo từ riêng nếu giá trị hiện tại không thuộc mẫu có sẵn
    if (provider.prefixWord.isNotEmpty &&
        !_prefixOptions.contains(provider.prefixWord) &&
        _customCreditPrefix == null) {
      _customCreditPrefix = provider.prefixWord;
    }
    if (provider.suffixWord.isNotEmpty &&
        provider.suffixWord != 'Không đọc lời cảm ơn' &&
        !_suffixOptions.contains(provider.suffixWord) &&
        _customCreditSuffix == null) {
      _customCreditSuffix = provider.suffixWord;
    }
    if (provider.debitPrefixWord.isNotEmpty &&
        !_debitPrefixOptions.contains(provider.debitPrefixWord) &&
        _customDebitPrefix == null) {
      _customDebitPrefix = provider.debitPrefixWord;
    }
    if (provider.debitSuffixWord.isNotEmpty &&
        provider.debitSuffixWord != 'Không đọc lời kết' &&
        !_debitSuffixOptions.contains(provider.debitSuffixWord) &&
        _customDebitSuffix == null) {
      _customDebitSuffix = provider.debitSuffixWord;
    }

    final isPlanExpired = googleAuth.isExpired || !googleAuth.isActivated;

    return Scaffold(
      backgroundColor: WebTheme.slateBg,
      appBar: AppBar(
        title: const Text(
          'Cài Đặt Câu Thông Báo',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: WebTheme.textHeading,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Khôi phục cài đặt mặc định',
            icon: const Icon(Icons.restart_alt_rounded, color: WebTheme.primaryDark),
            onPressed: isPlanExpired
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng đăng ký gói bản quyền để tùy chỉnh cài đặt câu thông báo.'),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                    widget.onNavigateToRegister?.call();
                  }
                : () {
                    setState(() {
                      _customCreditPrefix = null;
                      _customCreditSuffix = null;
                      _customDebitPrefix = null;
                      _customDebitSuffix = null;
                    });
                    provider.resetToDefaults();
                    provider.syncConfigToBackend(googleAuth.email);
                    TtsService().speakTestFeedback('Đã khôi phục cài đặt câu thông báo về mặc định tối ưu');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã khôi phục cài đặt câu thông báo về mặc định tối ưu!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: WebTheme.cardBorder, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: [
          if (isPlanExpired)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tùy chỉnh câu đọc bị khóa (Hết hạn gói)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Cấu hình của bạn vẫn được lưu giữ an toàn theo tài khoản. Hãy đăng ký/gia hạn gói để tiếp tục chỉnh sửa.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF7F1D1D), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                    onPressed: () => widget.onNavigateToRegister?.call(),
                    child: const Text('Đăng ký', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // 0. CHIA 2 TAB: NHẬN TIỀN VS TRỪ TIỀN
          _buildTypeTabSelector(),

          const SizedBox(height: 14),

          // Vùng cài đặt (Nếu hết hạn: Khóa chỉnh sửa nhưng vẫn hiển thị cấu hình đã lưu)
          AbsorbPointer(
            absorbing: isPlanExpired,
            child: Opacity(
              opacity: isPlanExpired ? 0.65 : 1.0,
              child: Column(
                children: [
                  // NỘI DUNG THAY ĐỔI THEO TAB ĐANG CHỌN
                  if (_activeTab == 0) ...[
                    // === TAB 0: NHẬN TIỀN (CREDIT) ===
                    _buildCreditPreviewAndPlayCard(provider, googleAuth),
                    const SizedBox(height: 16),
                    _buildCreditReadingFormBuilderCard(provider, googleAuth),
                  ] else ...[
                    // === TAB 1: TRỪ TIỀN (DEBIT) ===
                    _buildDebitPreviewAndPlayCard(provider, googleAuth),
                    const SizedBox(height: 16),
                    _buildDebitReadingFormBuilderCard(provider, googleAuth),
                  ],

                  const SizedBox(height: 18),

                  // TÙY CHỈNH KỸ THUẬT PHÁT ÂM & ÂM LƯỢNG TỐI ĐA MAX THEO ĐIỆN THOẠI
                  _buildAcousticControlsCard(provider, googleAuth),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Bộ chọn Tab 2 loại: "Nhận Tiền" và "Trừ Tiền"
  Widget _buildTypeTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Tab 0: Nhận Tiền
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 0),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _activeTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? const Color(0xFF10B981) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 13,
                        color: _activeTab == 0 ? Colors.white : WebTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nhận Tiền (Tiền Vào)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                        color: _activeTab == 0 ? const Color(0xFF0F172A) : WebTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Tab 1: Trừ Tiền
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 1),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _activeTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? const Color(0xFFE11D48) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 13,
                        color: _activeTab == 1 ? Colors.white : WebTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trừ Tiền (Tiền Ra)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                        color: _activeTab == 1 ? const Color(0xFF0F172A) : WebTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ===================== TAB 0: CẤU HÌNH NHẬN TIỀN =========================
  // =========================================================================

  Widget _buildCreditPreviewAndPlayCard(
    VoiceSettingsProvider provider,
    GoogleAuthProvider googleAuth,
  ) {
    final selectedSample = _sampleAmounts[_selectedAmountIndex];
    final liveSentence = provider.getLivePreviewSentence(selectedSample['label']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nghe Thử Câu Đọc Nhận Tiền',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      'Phát âm tròn vành rõ chữ, chính xác tuyệt đối từng số tiền',
                      style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Chọn số tiền nghe thử nghiệm:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textBody),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_sampleAmounts.length, (idx) {
              final isChosen = _selectedAmountIndex == idx;
              return ChoiceChip(
                label: Text(
                  _sampleAmounts[idx]['label'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isChosen ? FontWeight.bold : FontWeight.w500,
                    color: isChosen ? Colors.white : WebTheme.textBody,
                  ),
                ),
                selected: isChosen,
                selectedColor: const Color(0xFF10B981),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  side: BorderSide(
                    color: isChosen ? const Color(0xFF10B981) : WebTheme.cardBorder,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedAmountIndex = idx);
                    provider.playSample(sampleAmount: _sampleAmounts[idx]['words']);
                  }
                },
              );
            }),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(WebTheme.radiusSm),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_quote_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Xem trước câu đọc nhận tiền:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"$liveSentence"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Nút phát loa lớn nhận tiền
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                ),
              ),
              onPressed: () {
                if (provider.isPlayingSample) {
                  provider.stop();
                } else {
                  if (provider.isMaxVolumePhone) {
                    NotificationService.ensureMaxVolume();
                  }
                  provider.playSample(sampleAmount: selectedSample['words']);
                  final sampleText = provider.generateSentence(
                    amountWords: selectedSample['words'] ?? '500 nghìn đồng',
                    shopOrOrder: 'DH1058',
                    bankName: 'MBBank',
                  );
                  _showPlayingSnackbar(context, sampleText, 'Nhận tiền');
                  NotificationService.showSystemNotification(
                    title: '🔊 Nghe thử câu nhận tiền',
                    content: sampleText,
                    type: 'system',
                  );
                }
              },
              icon: Icon(provider.isPlayingSample ? Icons.stop_rounded : Icons.volume_up_rounded),
              label: Text(
                provider.isPlayingSample
                    ? 'Dừng phát'
                    : 'Nghe thử câu thông báo nhận tiền',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút bắn thông báo giao dịch chuyển khoản MBBank nhận tiền
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF047857),
                side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                ),
              ),
              onPressed: () async {
                final txProvider = context.read<TransactionProvider>();
                final randCode = (1000 + Random().nextInt(9000)).toString();
                await txProvider.simulateNotification(
                  bankCode: 'MBBANK',
                  title: 'MBBank',
                  body: 'TK 0338889999|GD: +250,000VND|ND: DH$randCode NGUYEN VAN A chuyen khoan|SD: 50,000,000VND',
                );
              },
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: const Text(
                'Bắn thử thông báo nhận tiền MBBank (Demo)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditReadingFormBuilderCard(
    VoiceSettingsProvider provider,
    GoogleAuthProvider googleAuth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Form đọc Nhận Tiền & Sắp xếp vị trí:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: WebTheme.textHeading,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cấu hình Nhận',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Tự do bật/tắt hoặc hoán đổi vị trí trước sau theo ý muốn. Dữ liệu lưu trực tiếp vào tài khoản MySQL!',
          style: TextStyle(fontSize: 11, color: WebTheme.textMuted, height: 1.3),
        ),
        const SizedBox(height: 12),

        // Chọn kịch bản mẫu nhanh
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: VoiceSettingsProvider.readingPresets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final preset = VoiceSettingsProvider.readingPresets[idx];
              final isChosen = provider.activePresetId == preset.id;

              return InkWell(
                onTap: () {
                  provider.applyReadingPreset(preset.id);
                  provider.syncConfigToBackend(googleAuth.email);
                  final sampleAmt = _sampleAmounts[_selectedAmountIndex]['words'];
                  provider.playSample(sampleAmount: sampleAmt);
                },
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isChosen ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                    border: Border.all(
                      color: isChosen ? const Color(0xFF10B981) : WebTheme.cardBorder,
                      width: isChosen ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(preset.icon, size: 14, color: isChosen ? const Color(0xFF065F46) : WebTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isChosen ? const Color(0xFF065F46) : WebTheme.textHeading,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.desc,
                        style: const TextStyle(fontSize: 9, color: WebTheme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Danh sách các khối sắp xếp thứ tự
        Container(
          decoration: WebTheme.cardDecoration(),
          child: Column(
            children: [
              ...provider.blocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;
                final isAmount = block.id == 'amount';

                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, color: WebTheme.cardBorder),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: block.isEnabled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(block.icon, size: 20, color: block.isEnabled ? const Color(0xFF065F46) : WebTheme.textMuted),
                        ],
                      ),
                      title: Text(
                        block.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: block.isEnabled ? WebTheme.textHeading : WebTheme.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        'Ví dụ: "${block.id == 'prefix' ? provider.prefixWord : (block.id == 'suffix' ? provider.suffixWord : block.sample)}"',
                        style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            color: index > 0 ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                            onPressed: index > 0
                                ? () {
                                    provider.moveBlockUp(index);
                                    provider.syncConfigToBackend(googleAuth.email);
                                    TtsService().speakTestFeedback('Đã chuyển ${block.title} lên trên');
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            color: index < provider.blocks.length - 1 ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                            onPressed: index < provider.blocks.length - 1
                                ? () {
                                    provider.moveBlockDown(index);
                                    provider.syncConfigToBackend(googleAuth.email);
                                    TtsService().speakTestFeedback('Đã chuyển ${block.title} xuống dưới');
                                  }
                                : null,
                          ),
                          const SizedBox(width: 4),
                          if (isAmount)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Luôn đọc',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            )
                          else
                            Switch(
                              activeThumbColor: const Color(0xFF10B981),
                              value: block.isEnabled,
                              onChanged: (val) {
                                provider.toggleBlock(block.id);
                                provider.syncConfigToBackend(googleAuth.email);
                                TtsService().speakTestFeedback(val ? 'Đã bật ${block.title}' : 'Đã tắt ${block.title}');
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Lựa chọn từ ngữ & cách đọc (Tiền tố, Số tiền, Ngân hàng, Lời cảm ơn)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: WebTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lựa chọn từ ngữ Nhận Tiền:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: WebTheme.textHeading),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Tùy biến 100%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Tiền tố Nhận Tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('1. Câu mở đầu / Tiền tố nhận tiền:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
                  InkWell(
                    onTap: () {
                      _showCustomTextDialog(
                        title: 'Tự nhập câu mở đầu nhận tiền riêng',
                        hintText: 'Ví dụ: Quán phở gia truyền xin nhận...',
                        initialValue: _customCreditPrefix ?? provider.prefixWord,
                        onSaved: (val) {
                          setState(() {
                            _customCreditPrefix = val;
                          });
                          provider.setPrefixWord(val);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('Mở đầu nhận: $val');
                        },
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 3),
                        Text(
                          '+ Tự nhập riêng',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Danh sách chips tiền tố (kèm chip từ riêng ưu tiên ở đầu nếu có)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_customCreditPrefix != null && _customCreditPrefix!.isNotEmpty)
                    _buildCustomChip(
                      label: _customCreditPrefix!,
                      isSelected: provider.prefixWord == _customCreditPrefix,
                      activeColor: const Color(0xFF10B981),
                      onSelected: () {
                        provider.setPrefixWord(_customCreditPrefix!);
                        provider.syncConfigToBackend(googleAuth.email);
                        TtsService().speakTestFeedback('$_customCreditPrefix, đã nhận hai trăm năm mươi nghìn đồng');
                      },
                      onDelete: () {
                        setState(() {
                          _customCreditPrefix = null;
                        });
                        provider.setPrefixWord('Đã nhận');
                        provider.syncConfigToBackend(googleAuth.email);
                      },
                    ),
                  ..._prefixOptions.map((opt) {
                    final isSelected = provider.prefixWord == opt;
                    return ChoiceChip(
                      label: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : WebTheme.textBody,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isSelected ? const Color(0xFF10B981) : WebTheme.cardBorder),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _customCreditPrefix = null;
                          });
                          provider.setPrefixWord(opt);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('$opt, đã nhận hai trăm năm mươi nghìn đồng');
                        }
                      },
                    );
                  }),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Cách đọc số tiền
              const Text('2. Cách đọc số tiền nhận:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _amountStyleOptions.map((item) {
                  final isSelected = provider.amountStyle == item['id'];
                  return ChoiceChip(
                    label: Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : WebTheme.textBody,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? const Color(0xFF10B981) : WebTheme.cardBorder),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.setAmountStyle(item['id']!);
                        provider.syncConfigToBackend(googleAuth.email);
                        String sampleAmt;
                        if (item['id'] == 'vnd') {
                          sampleAmt = 'Hai trăm năm mươi nghìn V N Đ';
                        } else if (item['id'] == 'compact' || item['id'] == 'short_k') {
                          sampleAmt = 'Hai trăm năm mươi nghìn';
                        } else {
                          sampleAmt = 'Hai trăm năm mươi nghìn đồng';
                        }
                        TtsService().speakTestFeedback('Đã nhận $sampleAmt');
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 3. Cách đọc tên ngân hàng
              const Text('3. Cách đọc tên ngân hàng nhận:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _bankStyleOptions.map((item) {
                  final isSelected = provider.bankStyle == item['id'];
                  return ChoiceChip(
                    label: Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : WebTheme.textBody,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? const Color(0xFF10B981) : WebTheme.cardBorder),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.setBankStyle(item['id']!);
                        provider.syncConfigToBackend(googleAuth.email);
                        String sampleBank;
                        if (item['id'] == 'tu') {
                          sampleBank = 'từ Techcombank';
                        } else if (item['id'] == 'qua') {
                          sampleBank = 'qua Techcombank';
                        } else if (item['id'] == 'vao') {
                          sampleBank = 'vào tài khoản Techcombank';
                        } else {
                          sampleBank = 'Techcombank';
                        }
                        TtsService().speakTestFeedback('Hai trăm năm mươi nghìn đồng, $sampleBank');
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 4. Lời cảm ơn / Hậu tố
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('4. Lời cảm ơn / Hậu tố kết thúc:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
                  InkWell(
                    onTap: () {
                      _showCustomTextDialog(
                        title: 'Tự nhập lời cảm ơn của quán',
                        hintText: 'Ví dụ: Bánh Mì Cô Ba xin cảm ơn quý khách!',
                        initialValue: _customCreditSuffix ?? provider.suffixWord,
                        onSaved: (val) {
                          setState(() {
                            _customCreditSuffix = val;
                          });
                          provider.setSuffixWord(val);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('Hậu tố: $val');
                        },
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 3),
                        Text(
                          '+ Tự nhập riêng',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_customCreditSuffix != null && _customCreditSuffix!.isNotEmpty)
                    _buildCustomChip(
                      label: _customCreditSuffix!,
                      isSelected: provider.suffixWord == _customCreditSuffix,
                      activeColor: const Color(0xFF10B981),
                      onSelected: () {
                        provider.setSuffixWord(_customCreditSuffix!);
                        provider.syncConfigToBackend(googleAuth.email);
                        TtsService().speakTestFeedback('Đã nhận hai trăm năm mươi nghìn đồng, $_customCreditSuffix');
                      },
                      onDelete: () {
                        setState(() {
                          _customCreditSuffix = null;
                        });
                        provider.setSuffixWord('Cảm ơn quý khách!');
                        provider.syncConfigToBackend(googleAuth.email);
                      },
                    ),
                  ..._suffixOptions.map((opt) {
                    final isSelected = opt.isEmpty
                        ? provider.suffixWord.isEmpty
                        : (opt == 'Không đọc lời cảm ơn'
                            ? provider.suffixWord.isEmpty
                            : provider.suffixWord == opt);

                    final displayText = opt.isEmpty ? 'Tắt lời cảm ơn' : opt;

                    return ChoiceChip(
                      label: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : WebTheme.textBody,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isSelected ? const Color(0xFF10B981) : WebTheme.cardBorder),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _customCreditSuffix = null;
                          });
                          final valToSet = (opt == 'Không đọc lời cảm ơn' || opt.isEmpty) ? '' : opt;
                          provider.setSuffixWord(valToSet);
                          provider.syncConfigToBackend(googleAuth.email);
                          if (valToSet.isEmpty) {
                            TtsService().speakTestFeedback('Đã tắt lời cảm ơn');
                          } else {
                            TtsService().speakTestFeedback('Đã nhận hai trăm năm mươi nghìn đồng, $valToSet');
                          }
                        }
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ===================== TAB 1: CẤU HÌNH TRỪ TIỀN ==========================
  // =========================================================================

  Widget _buildDebitPreviewAndPlayCard(
    VoiceSettingsProvider provider,
    GoogleAuthProvider googleAuth,
  ) {
    final selectedSample = _sampleDebitAmounts[_selectedDebitAmountIndex];
    final liveSentence = provider.getDebitLivePreviewSentence(selectedSample['label']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                ),
                child: const Icon(Icons.outbond_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nghe Thử Câu Đọc Trừ Tiền',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                    Text(
                      'Báo tiền ra, chi tiêu mua sắm, chuyển khoản dứt khoát chính xác',
                      style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Chọn số tiền trừ nghe thử nghiệm:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textBody),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_sampleDebitAmounts.length, (idx) {
              final isChosen = _selectedDebitAmountIndex == idx;
              return ChoiceChip(
                label: Text(
                  _sampleDebitAmounts[idx]['label'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isChosen ? FontWeight.bold : FontWeight.w500,
                    color: isChosen ? Colors.white : WebTheme.textBody,
                  ),
                ),
                selected: isChosen,
                selectedColor: const Color(0xFFE11D48),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  side: BorderSide(
                    color: isChosen ? const Color(0xFFE11D48) : WebTheme.cardBorder,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDebitAmountIndex = idx);
                    provider.playDebitSample(sampleAmount: _sampleDebitAmounts[idx]['words']);
                  }
                },
              );
            }),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(WebTheme.radiusSm),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_quote_rounded, size: 14, color: Color(0xFFE11D48)),
                    SizedBox(width: 4),
                    Text(
                      'Xem trước câu đọc trừ tiền:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"$liveSentence"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9F1239),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Nút phát loa lớn trừ tiền
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                ),
              ),
              onPressed: () {
                if (provider.isPlayingSample) {
                  provider.stop();
                } else {
                  if (provider.isMaxVolumePhone) {
                    NotificationService.ensureMaxVolume();
                  }
                  provider.playDebitSample(sampleAmount: selectedSample['words']);
                  final sampleText = provider.generateDebitSentence(
                    amountWords: selectedSample['words'] ?? '150 nghìn đồng',
                    shopOrOrder: 'đơn hàng D H 1 0 5 8',
                    bankName: 'MBBank',
                  );
                  _showPlayingSnackbar(context, sampleText, 'Trừ tiền');
                  NotificationService.showSystemNotification(
                    title: '🔊 Nghe thử câu trừ tiền',
                    content: sampleText,
                    type: 'system',
                  );
                }
              },
              icon: Icon(provider.isPlayingSample ? Icons.stop_rounded : Icons.volume_up_rounded),
              label: Text(
                provider.isPlayingSample
                    ? 'Dừng phát'
                    : 'Nghe thử câu thông báo trừ tiền',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút bắn thông báo giao dịch trừ tiền MBBank
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBE123C),
                side: const BorderSide(color: Color(0xFFE11D48), width: 1.2),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WebTheme.radiusMd),
                ),
              ),
              onPressed: () async {
                final txProvider = context.read<TransactionProvider>();
                final randCode = (1000 + Random().nextInt(9000)).toString();
                await txProvider.simulateNotification(
                  bankCode: 'MBBANK',
                  title: 'MBBank',
                  body: 'TK 0338889999|GD: -150,000VND|ND: Chuyen khoan DH$randCode thanh toan hoa don|SD: 48,500,000VND',
                );
              },
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: const Text(
                'Bắn thử thông báo trừ tiền MBBank (Demo)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebitReadingFormBuilderCard(
    VoiceSettingsProvider provider,
    GoogleAuthProvider googleAuth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Form đọc Trừ Tiền & Sắp xếp vị trí:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: WebTheme.textHeading,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cấu hình Trừ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Định dạng cấu hình đọc khi phát hiện biến động trừ tiền hoặc chi tiêu chuyển khoản.',
          style: TextStyle(fontSize: 11, color: WebTheme.textMuted, height: 1.3),
        ),
        const SizedBox(height: 12),

        // Chọn kịch bản mẫu nhanh cho Chuyển Đi
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: VoiceSettingsProvider.debitReadingPresets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final preset = VoiceSettingsProvider.debitReadingPresets[idx];
              final isChosen = provider.debitActivePresetId == preset.id;

              return InkWell(
                onTap: () {
                  provider.applyDebitReadingPreset(preset.id);
                  provider.syncConfigToBackend(googleAuth.email);
                  final sampleAmt = _sampleDebitAmounts[_selectedDebitAmountIndex]['words'];
                  provider.playDebitSample(sampleAmount: sampleAmt);
                },
                borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isChosen ? const Color(0xFFFFF1F2) : Colors.white,
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                    border: Border.all(
                      color: isChosen ? const Color(0xFFE11D48) : WebTheme.cardBorder,
                      width: isChosen ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(preset.icon, size: 14, color: isChosen ? const Color(0xFF9F1239) : WebTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isChosen ? const Color(0xFF9F1239) : WebTheme.textHeading,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.desc,
                        style: const TextStyle(fontSize: 9, color: WebTheme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Danh sách các khối sắp xếp thứ tự cho Trừ Tiền
        Container(
          decoration: WebTheme.cardDecoration(),
          child: Column(
            children: [
              ...provider.debitBlocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;
                final isAmount = block.id == 'amount';

                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1, color: WebTheme.cardBorder),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: block.isEnabled ? const Color(0xFFE11D48) : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(block.icon, size: 20, color: block.isEnabled ? const Color(0xFF9F1239) : WebTheme.textMuted),
                        ],
                      ),
                      title: Text(
                        block.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: block.isEnabled ? WebTheme.textHeading : WebTheme.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        'Ví dụ: "${block.id == 'prefix' ? provider.debitPrefixWord : (block.id == 'suffix' ? provider.debitSuffixWord : block.sample)}"',
                        style: const TextStyle(fontSize: 10, color: WebTheme.textMuted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            color: index > 0 ? const Color(0xFFE11D48) : const Color(0xFFCBD5E1),
                            onPressed: index > 0
                                ? () {
                                    provider.moveDebitBlockUp(index);
                                    provider.syncConfigToBackend(googleAuth.email);
                                    TtsService().speakTestFeedback('Đã chuyển ${block.title} lên trên');
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            color: index < provider.debitBlocks.length - 1 ? const Color(0xFFE11D48) : const Color(0xFFCBD5E1),
                            onPressed: index < provider.debitBlocks.length - 1
                                ? () {
                                    provider.moveDebitBlockDown(index);
                                    provider.syncConfigToBackend(googleAuth.email);
                                    TtsService().speakTestFeedback('Đã chuyển ${block.title} xuống dưới');
                                  }
                                : null,
                          ),
                          const SizedBox(width: 4),
                          if (isAmount)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Luôn đọc',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFBE123C),
                                ),
                              ),
                            )
                          else
                            Switch(
                              activeThumbColor: const Color(0xFFE11D48),
                              value: block.isEnabled,
                              onChanged: (val) {
                                provider.toggleDebitBlock(block.id);
                                provider.syncConfigToBackend(googleAuth.email);
                                TtsService().speakTestFeedback(val ? 'Đã bật ${block.title}' : 'Đã tắt ${block.title}');
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Lựa chọn từ ngữ cho Trừ Tiền (Tiền tố, Số tiền, Ngân hàng, Lời kết)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: WebTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lựa chọn từ ngữ Trừ Tiền:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: WebTheme.textHeading),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Tùy biến 100%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Tiền tố Trừ Tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('1. Câu thông báo / Tiền tố trừ tiền:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
                  InkWell(
                    onTap: () {
                      _showCustomTextDialog(
                        title: 'Tự nhập câu mở đầu trừ tiền riêng',
                        hintText: 'Ví dụ: Đã chi trả, Vừa mua sắm...',
                        initialValue: _customDebitPrefix ?? provider.debitPrefixWord,
                        onSaved: (val) {
                          setState(() {
                            _customDebitPrefix = val;
                          });
                          provider.setDebitPrefixWord(val);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('Mở đầu trừ: $val');
                        },
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFE11D48)),
                        SizedBox(width: 3),
                        Text(
                          '+ Tự nhập riêng',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_customDebitPrefix != null && _customDebitPrefix!.isNotEmpty)
                    _buildCustomChip(
                      label: _customDebitPrefix!,
                      isSelected: provider.debitPrefixWord == _customDebitPrefix,
                      activeColor: const Color(0xFFE11D48),
                      onSelected: () {
                        provider.setDebitPrefixWord(_customDebitPrefix!);
                        provider.syncConfigToBackend(googleAuth.email);
                        TtsService().speakTestFeedback('$_customDebitPrefix, một trăm năm mươi nghìn đồng');
                      },
                      onDelete: () {
                        setState(() {
                          _customDebitPrefix = null;
                        });
                        provider.setDebitPrefixWord('Đã chuyển');
                        provider.syncConfigToBackend(googleAuth.email);
                      },
                    ),
                  ..._debitPrefixOptions.map((opt) {
                    final isSelected = provider.debitPrefixWord == opt;
                    return ChoiceChip(
                      label: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : WebTheme.textBody,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE11D48),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isSelected ? const Color(0xFFE11D48) : WebTheme.cardBorder),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _customDebitPrefix = null;
                          });
                          provider.setDebitPrefixWord(opt);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('$opt, một trăm năm mươi nghìn đồng');
                        }
                      },
                    );
                  }),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Cách đọc số tiền trừ
              const Text('2. Cách đọc số tiền trừ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _amountStyleOptions.map((item) {
                  final isSelected = provider.debitAmountStyle == item['id'];
                  return ChoiceChip(
                    label: Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : WebTheme.textBody,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE11D48),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? const Color(0xFFE11D48) : WebTheme.cardBorder),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.setDebitAmountStyle(item['id']!);
                        provider.syncConfigToBackend(googleAuth.email);
                        String sampleAmt;
                        if (item['id'] == 'vnd') {
                          sampleAmt = 'Một trăm năm mươi nghìn V N Đ';
                        } else if (item['id'] == 'compact' || item['id'] == 'short_k') {
                          sampleAmt = 'Một trăm năm mươi nghìn';
                        } else {
                          sampleAmt = 'Một trăm năm mươi nghìn đồng';
                        }
                        TtsService().speakTestFeedback('Đã chuyển $sampleAmt');
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 3. Cách đọc ngân hàng thực hiện
              const Text('3. Cách đọc ngân hàng chuyển:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _debitBankStyleOptions.map((item) {
                  final isSelected = provider.debitBankStyle == item['id'];
                  return ChoiceChip(
                    label: Text(
                      item['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : WebTheme.textBody,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE11D48),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? const Color(0xFFE11D48) : WebTheme.cardBorder),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.setDebitBankStyle(item['id']!);
                        provider.syncConfigToBackend(googleAuth.email);
                        TtsService().speakTestFeedback('Đã chuyển qua MBBank');
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 4. Lời kết / Hậu tố trừ tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('4. Lời kết / Hậu tố hoàn tất:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
                  InkWell(
                    onTap: () {
                      _showCustomTextDialog(
                        title: 'Tự nhập lời kết trừ tiền riêng',
                        hintText: 'Ví dụ: Đã ghi nhận sổ quỹ...',
                        initialValue: _customDebitSuffix ?? provider.debitSuffixWord,
                        onSaved: (val) {
                          setState(() {
                            _customDebitSuffix = val;
                          });
                          provider.setDebitSuffixWord(val);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('Lời kết: $val');
                        },
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFE11D48)),
                        SizedBox(width: 3),
                        Text(
                          '+ Tự nhập riêng',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_customDebitSuffix != null && _customDebitSuffix!.isNotEmpty)
                    _buildCustomChip(
                      label: _customDebitSuffix!,
                      isSelected: provider.debitSuffixWord == _customDebitSuffix,
                      activeColor: const Color(0xFFE11D48),
                      onSelected: () {
                        provider.setDebitSuffixWord(_customDebitSuffix!);
                        provider.syncConfigToBackend(googleAuth.email);
                        TtsService().speakTestFeedback('Đã chuyển một trăm năm mươi nghìn đồng, $_customDebitSuffix');
                      },
                      onDelete: () {
                        setState(() {
                          _customDebitSuffix = null;
                        });
                        provider.setDebitSuffixWord('Giao dịch hoàn tất!');
                        provider.syncConfigToBackend(googleAuth.email);
                      },
                    ),
                  ..._debitSuffixOptions.map((opt) {
                    final isSelected = opt.isEmpty
                        ? provider.debitSuffixWord.isEmpty
                        : (opt == 'Không đọc lời kết'
                            ? provider.debitSuffixWord.isEmpty
                            : provider.debitSuffixWord == opt);

                    final displayText = opt.isEmpty ? 'Tắt lời kết' : opt;

                    return ChoiceChip(
                      label: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : WebTheme.textBody,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE11D48),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isSelected ? const Color(0xFFE11D48) : WebTheme.cardBorder),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _customDebitSuffix = null;
                          });
                          final valToSet = (opt == 'Không đọc lời kết' || opt.isEmpty) ? '' : opt;
                          provider.setDebitSuffixWord(valToSet);
                          provider.syncConfigToBackend(googleAuth.email);
                          if (valToSet.isEmpty) {
                            TtsService().speakTestFeedback('Đã tắt lời kết');
                          } else {
                            TtsService().speakTestFeedback('Đã chuyển một trăm năm mươi nghìn đồng, $valToSet');
                          }
                        }
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ================= TÙY CHỈNH ÂM LƯỢNG MAX & KỸ THUẬT PHÁT ÂM =============
  // =========================================================================

  Widget _buildAcousticControlsCard(VoiceSettingsProvider provider, GoogleAuthProvider googleAuth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chỉnh kỹ thuật phát âm & Âm lượng:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: WebTheme.textHeading,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: WebTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CARD ÂM LƯỢNG TỐI ĐA MAX THEO ĐIỆN THOẠI (Yêu cầu đặc biệt của người dùng)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Âm lượng to nhất theo điện thoại (100% MAX)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tự động kích âm Media lên 100% cực đại của điện thoại khi đọc thông báo, to rõ chống ồn quầy thu ngân',
                                style: TextStyle(fontSize: 10, color: Color(0xFF166534), height: 1.25),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.isMaxVolumePhone,
                          activeThumbColor: const Color(0xFF16A34A),
                          onChanged: (val) {
                            provider.setMaxVolumePhone(val, email: googleAuth.email);
                            if (val) {
                              NotificationService.ensureMaxVolume();
                              TtsService().speakTestFeedback('Đã bật chế độ đọc to nhất theo âm lượng điện thoại');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () async {
                          await NotificationService.ensureMaxVolume();
                          await provider.setVolume(1.0);
                          TtsService().speakTestFeedback('Đang phát thông báo với âm lượng to nhất theo điện thoại');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔊 Đã kích âm lượng loa ngoài lên 100% cực đại của điện thoại!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: const Text('Thử ngay âm lượng to nhất theo điện thoại', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Thanh trượt âm lượng chi tiết
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Âm lượng chi tiết:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    '${(provider.volume * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.primaryDark),
                  ),
                ],
              ),
              Slider(
                value: provider.volume.clamp(0.2, 1.0),
                min: 0.2,
                max: 1.0,
                divisions: 8,
                activeColor: WebTheme.primary,
                onChanged: (val) {
                  provider.setVolume(val, testAudio: false);
                },
                onChangeEnd: (val) {
                  provider.setVolume(val, testAudio: true);
                  provider.syncConfigToBackend(googleAuth.email);
                },
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildQuickValueChip('60% Vừa', (provider.volume - 0.6).abs() < 0.05, () {
                      provider.setVolume(0.6, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                    const SizedBox(width: 5),
                    _buildQuickValueChip('85% Lớn', (provider.volume - 0.85).abs() < 0.05, () {
                      provider.setVolume(0.85, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                    const SizedBox(width: 5),
                    _buildQuickValueChip('100% Cực đại (MAX)', provider.volume >= 0.98, () {
                      provider.setVolume(1.0, testAudio: true);
                      NotificationService.ensureMaxVolume();
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Tốc độ đọc
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tốc độ đọc:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    '${(provider.speechRate * 100).toInt()}% (${provider.speechRate.toStringAsFixed(2)}x)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.primaryDark),
                  ),
                ],
              ),
              Slider(
                value: provider.speechRate.clamp(0.5, 2.0),
                min: 0.5,
                max: 2.0,
                divisions: 15,
                activeColor: WebTheme.primary,
                onChanged: (val) {
                  provider.setSpeechRate(val, testAudio: false);
                },
                onChangeEnd: (val) {
                  provider.setSpeechRate(val, testAudio: true);
                  provider.syncConfigToBackend(googleAuth.email);
                },
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildQuickValueChip('0.7x Chậm', (provider.speechRate - 0.7).abs() < 0.05, () {
                      provider.setSpeechRate(0.7, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                    const SizedBox(width: 5),
                    _buildQuickValueChip('0.9x Chuẩn', (provider.speechRate - 0.9).abs() < 0.05, () {
                      provider.setSpeechRate(0.9, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                    const SizedBox(width: 5),
                    _buildQuickValueChip('1.2x Nhanh', (provider.speechRate - 1.2).abs() < 0.05, () {
                      provider.setSpeechRate(1.2, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                    const SizedBox(width: 5),
                    _buildQuickValueChip('1.5x Cao điểm', (provider.speechRate - 1.5).abs() < 0.05, () {
                      provider.setSpeechRate(1.5, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Cao độ giọng (Pitch)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cao độ giọng (Pitch):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    '${(provider.pitch * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.primaryDark),
                  ),
                ],
              ),
              Slider(
                value: provider.pitch.clamp(0.5, 2.0),
                min: 0.5,
                max: 2.0,
                divisions: 15,
                activeColor: WebTheme.primary,
                onChanged: (val) {
                  provider.setPitch(val, testAudio: false);
                },
                onChangeEnd: (val) {
                  provider.setPitch(val, testAudio: true);
                  provider.syncConfigToBackend(googleAuth.email);
                },
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildQuickValueChip('0.65x Trầm', (provider.pitch - 0.65).abs() < 0.05, () {
                      provider.setPitch(0.65, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                    const SizedBox(width: 5),
                    _buildQuickValueChip('1.0x Tự nhiên', (provider.pitch - 1.0).abs() < 0.05, () {
                      provider.setPitch(1.0, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                    const SizedBox(width: 5),
                    _buildQuickValueChip('1.45x Nữ cao', (provider.pitch - 1.45).abs() < 0.05, () {
                      provider.setPitch(1.45, testAudio: true);
                      provider.syncConfigToBackend(googleAuth.email);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Chip hiển thị từ riêng tự nhập với dấu sao và nút xóa
  Widget _buildCustomChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onSelected,
    required VoidCallback onDelete,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFF59E0B),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFFD97706),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF92400E),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickValueChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? WebTheme.primaryLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? WebTheme.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? WebTheme.primaryDark : WebTheme.textMuted,
          ),
        ),
      ),
    );
  }

  void _showPlayingSnackbar(BuildContext context, String sampleText, String typeName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Color(0xFF38BDF8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ĐANG PHÁT THỬ CÂU $typeName:'.toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(sampleText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

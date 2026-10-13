import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/web_theme.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../auth/presentation/providers/google_auth_provider.dart';
import '../providers/voice_settings_provider.dart';

class VoiceSettingsPage extends StatefulWidget {
  final VoidCallback? onNavigateToRegister;
  const VoiceSettingsPage({super.key, this.onNavigateToRegister});

  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  int _selectedAmountIndex = 1; // Mặc định 250.000 đ
  final List<Map<String, dynamic>> _sampleAmounts = [
    {'label': '50.000 ₫', 'words': 'năm mươi nghìn đồng'},
    {'label': '250.000 ₫', 'words': 'hai trăm năm mươi nghìn đồng'},
    {'label': '500.000 ₫', 'words': 'năm trăm nghìn đồng'},
    {'label': '1.500.000 ₫', 'words': 'một triệu năm trăm nghìn đồng'},
    {'label': '5.000.000 ₫', 'words': 'năm triệu đồng'},
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

  final List<String> _suffixOptions = [
    'Cảm ơn quý khách!',
    'Chúc ngày mới đắt hàng!',
    'Hẹn gặp lại quý khách!',
    'AutoBank xin cảm ơn!',
    'Cảm ơn và hẹn gặp lại!',
    'Chúc quý khách ngon miệng!',
    'Giao dịch thành công!',
    'Không đọc lời cảm ơn',
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
    final selectedSample = _sampleAmounts[_selectedAmountIndex];

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
            onPressed: () {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. CARD BANNER NGHE THỬ CÂU ĐỌC & FORM PREVIEW TRỰC QUAN
          _buildPreviewAndPlayCard(provider, selectedSample, googleAuth),

          const SizedBox(height: 18),

          // 2. MÔ HÌNH 1 FORM ĐỌC DUY NHẤT & SẮP XẾP VỊ TRÍ CÁC KHỐI
          _buildReadingFormBuilderCard(provider, selectedSample, googleAuth),

          const SizedBox(height: 18),

          // 3. TÙY CHỈNH KỸ THUẬT PHÁT ÂM: TỐC ĐỘ, ÂM LƯỢNG
          _buildAcousticControlsCard(provider, googleAuth),

          const SizedBox(height: 32),
        ],
      ),
    );
  }



  /// Card banner nghe thử câu đọc và xem trước kết quả
  Widget _buildPreviewAndPlayCard(
    VoiceSettingsProvider provider,
    Map<String, dynamic> selectedSample,
    GoogleAuthProvider googleAuth,
  ) {
    final liveSentence = provider.getLivePreviewSentence(selectedSample['label']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WebTheme.cardDecoration(
        color: WebTheme.primaryBg,
        border: Border.all(color: WebTheme.primaryLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WebTheme.primary,
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nghe Thử Câu Đọc Thông Báo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: WebTheme.primaryDark,
                      ),
                    ),
                    const Text(
                      'Phát âm tròn vành rõ chữ, chính xác tuyệt đối từng số tiền',
                      style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Chọn mức tiền nghe thử nghiệm (Chips bo góc 8px chuẩn web)
          const Text(
            'Chọn số tiền nghe thử:',
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
                selectedColor: WebTheme.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                  side: BorderSide(
                    color: isChosen ? WebTheme.primary : WebTheme.cardBorder,
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

          // Khung hiển thị câu đọc trực quan theo Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(WebTheme.radiusSm),
              border: Border.all(color: WebTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_quote_rounded, size: 14, color: WebTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'Xem trước câu đọc thực tế:',
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
                    color: WebTheme.primaryDark,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Nút phát loa lớn
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: WebTheme.primary,
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
                  provider.playSample(sampleAmount: selectedSample['words']);
                }
              },
              icon: Icon(provider.isPlayingSample ? Icons.stop_rounded : Icons.volume_up_rounded),
              label: Text(
                provider.isPlayingSample
                    ? 'Dừng phát'
                    : 'Nghe thử câu thông báo',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// Tùy chỉnh kỹ thuật phát âm: Tốc độ, Cao độ, Âm lượng
  Widget _buildAcousticControlsCard(VoiceSettingsProvider provider, GoogleAuthProvider googleAuth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chỉnh kỹ thuật phát âm:',
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
              // 1. Tốc độ đọc
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
                value: provider.speechRate,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                activeColor: WebTheme.primary,
                onChanged: (val) {
                  provider.setSpeechRate(val, testAudio: false);
                },
                onChangeEnd: (val) {
                  provider.setSpeechRate(val, testAudio: true);
                  provider.syncConfigToBackend(googleAuth.email);
                },
              ),
              // Chips chọn nhanh tốc độ
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildQuickValueChip('0.8x Chậm', (provider.speechRate - 0.8).abs() < 0.02, () {
                    provider.setSpeechRate(0.8, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                  const SizedBox(width: 6),
                  _buildQuickValueChip('0.9x Chuẩn', (provider.speechRate - 0.9).abs() < 0.02, () {
                    provider.setSpeechRate(0.9, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                  const SizedBox(width: 6),
                  _buildQuickValueChip('1.0x Thường', (provider.speechRate - 1.0).abs() < 0.02, () {
                    provider.setSpeechRate(1.0, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                  const SizedBox(width: 6),
                  _buildQuickValueChip('1.2x Nhanh', (provider.speechRate - 1.2).abs() < 0.02, () {
                    provider.setSpeechRate(1.2, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Cao độ giọng (Pitch)
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
                value: provider.pitch,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                activeColor: WebTheme.primary,
                onChanged: (val) {
                  provider.setPitch(val, testAudio: false);
                },
                onChangeEnd: (val) {
                  provider.setPitch(val, testAudio: true);
                  provider.syncConfigToBackend(googleAuth.email);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildQuickValueChip('Trầm ấm', (provider.pitch - 0.85).abs() < 0.05, () {
                    provider.setPitch(0.85, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                  const SizedBox(width: 6),
                  _buildQuickValueChip('Tự nhiên', (provider.pitch - 1.0).abs() < 0.05, () {
                    provider.setPitch(1.0, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                  const SizedBox(width: 6),
                  _buildQuickValueChip('Trong trẻo', (provider.pitch - 1.15).abs() < 0.05, () {
                    provider.setPitch(1.15, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Âm lượng thông báo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Âm lượng thông báo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    '${(provider.volume * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WebTheme.primaryDark),
                  ),
                ],
              ),
              Slider(
                value: provider.volume,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                activeColor: WebTheme.primary,
                onChanged: (val) {
                  provider.setVolume(val, testAudio: false);
                },
                onChangeEnd: (val) {
                  provider.setVolume(val, testAudio: true);
                  provider.syncConfigToBackend(googleAuth.email);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildQuickValueChip('70% Vừa', provider.volume == 0.7, () {
                    provider.setVolume(0.7, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                  const SizedBox(width: 6),
                  _buildQuickValueChip('90% Lớn', provider.volume == 0.9, () {
                    provider.setVolume(0.9, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                  const SizedBox(width: 6),
                  _buildQuickValueChip('100% Tối đa', provider.volume == 1.0, () {
                    provider.setVolume(1.0, testAudio: true);
                    provider.syncConfigToBackend(googleAuth.email);
                  }),
                ],
              ),
              const SizedBox(height: 14),

              // Nút nghe thử ngay hiệu ứng âm thanh vừa chỉnh
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WebTheme.primaryDark,
                    side: const BorderSide(color: WebTheme.primaryLight, width: 1.2),
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebTheme.radiusSm)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    TtsService().speakTestFeedback(
                      'Đã nhận hai trăm năm mươi nghìn đồng, tốc độ ${(provider.speechRate * 100).toInt()}%',
                    );
                  },
                  icon: const Icon(Icons.volume_up_rounded, size: 18, color: WebTheme.primary),
                  label: const Text(
                    'Bấm nghe thử hiệu ứng âm thanh vừa chỉnh',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  /// Khối mô hình 1 Form đọc duy nhất & sắp xếp vị trí các khối
  Widget _buildReadingFormBuilderCard(
    VoiceSettingsProvider provider,
    Map<String, dynamic> selectedSample,
    GoogleAuthProvider googleAuth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Form đọc duy nhất & Sắp xếp vị trí:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: WebTheme.textHeading,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: WebTheme.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '1 Form thống nhất',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WebTheme.primaryDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Câu thông báo tuân theo 1 Form chuẩn thống nhất dưới đây. Bạn có thể sắp xếp đổi vị trí trước/sau và bật tắt theo ý bạn!',
          style: TextStyle(fontSize: 11, color: WebTheme.textMuted, height: 1.3),
        ),
        const SizedBox(height: 12),

        // Chọn kịch bản mẫu nhanh (Presets)
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
                    color: isChosen ? WebTheme.primaryBg : Colors.white,
                    borderRadius: BorderRadius.circular(WebTheme.radiusSm),
                    border: Border.all(
                      color: isChosen ? WebTheme.primary : WebTheme.cardBorder,
                      width: isChosen ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(preset.icon, size: 14, color: isChosen ? WebTheme.primaryDark : WebTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isChosen ? WebTheme.primaryDark : WebTheme.textHeading,
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
                          // Badge thứ tự vị trí
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: block.isEnabled ? WebTheme.primary : const Color(0xFFCBD5E1),
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
                          Icon(block.icon, size: 20, color: block.isEnabled ? WebTheme.primaryDark : WebTheme.textMuted),
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
                          // Nút chuyển vị trí lên trên
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            color: index > 0 ? WebTheme.primary : const Color(0xFFCBD5E1),
                            onPressed: index > 0
                                ? () {
                                    provider.moveBlockUp(index);
                                    provider.syncConfigToBackend(googleAuth.email);
                                    TtsService().speakTestFeedback('Đã chuyển ${block.title} lên trên');
                                  }
                                : null,
                          ),
                          // Nút chuyển vị trí xuống dưới
                          IconButton(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            color: index < provider.blocks.length - 1 ? WebTheme.primary : const Color(0xFFCBD5E1),
                            onPressed: index < provider.blocks.length - 1
                                ? () {
                                    provider.moveBlockDown(index);
                                    provider.syncConfigToBackend(googleAuth.email);
                                    TtsService().speakTestFeedback('Đã chuyển ${block.title} xuống dưới');
                                  }
                                : null,
                          ),
                          const SizedBox(width: 4),
                          // Switch bật / tắt khối (Số tiền luôn cố định bật)
                          if (isAmount)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: WebTheme.primaryBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: WebTheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Luôn đọc',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: WebTheme.primaryDark,
                                ),
                              ),
                            )
                          else
                            Switch(
                              activeThumbColor: WebTheme.primary,
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

        // Tùy chỉnh câu chào / Tiền tố & Lời cảm ơn / Hậu tố & Cách đọc số tiền
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
                    'Lựa chọn từ ngữ & cách đọc:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: WebTheme.textHeading),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: WebTheme.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Tùy biến 100%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WebTheme.primaryDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Tiền tố
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('1. Câu mở đầu / Tiền tố:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
                  InkWell(
                    onTap: () {
                      _showCustomTextDialog(
                        title: 'Tự nhập câu mở đầu / Tiền tố',
                        hintText: 'Ví dụ: Tiệm bánh mì xin nhận, Khách gửi...',
                        initialValue: provider.prefixWord,
                        onSaved: (val) {
                          provider.setPrefixWord(val);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('Mở đầu: $val');
                        },
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 14, color: WebTheme.primary),
                        SizedBox(width: 3),
                        Text(
                          '+ Tự nhập riêng',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.primary),
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
                children: _prefixOptions.map((opt) {
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
                    selectedColor: WebTheme.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? WebTheme.primary : WebTheme.cardBorder),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.setPrefixWord(opt);
                        provider.syncConfigToBackend(googleAuth.email);
                        TtsService().speakTestFeedback('$opt, đã nhận hai trăm năm mươi nghìn đồng');
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 2. Cách đọc số tiền
              const Text('2. Cách đọc số tiền:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
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
                    selectedColor: WebTheme.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? WebTheme.primary : WebTheme.cardBorder),
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
              const Text('3. Cách đọc tên ngân hàng:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.textHeading)),
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
                    selectedColor: WebTheme.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? WebTheme.primary : WebTheme.cardBorder),
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
                        hintText: 'Ví dụ: Bánh Mì Kim Anh xin cảm ơn quý khách!',
                        initialValue: provider.suffixWord,
                        onSaved: (val) {
                          provider.setSuffixWord(val);
                          provider.syncConfigToBackend(googleAuth.email);
                          TtsService().speakTestFeedback('Hậu tố: $val');
                        },
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 14, color: WebTheme.primary),
                        SizedBox(width: 3),
                        Text(
                          '+ Tự nhập riêng',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WebTheme.primary),
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
                children: _suffixOptions.map((opt) {
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
                    selectedColor: WebTheme.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: isSelected ? WebTheme.primary : WebTheme.cardBorder),
                    ),
                    onSelected: (selected) {
                      if (selected) {
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
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

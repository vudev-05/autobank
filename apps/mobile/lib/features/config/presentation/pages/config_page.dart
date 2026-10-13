import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autobank_mobile/features/voice_settings/presentation/providers/voice_settings_provider.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final Map<String, bool> _enabledBanks = {
    'Vietcombank (VCB)': true,
    'MB Bank (Quân Đội)': true,
    'Techcombank (TCB)': true,
    'ACB ONE': true,
    'VPBank NEO': true,
    'TPBank Mobile': true,
    'BIDV SmartBanking': true,
    'Agribank E-Mobile': true,
    'Ví MoMo': true,
    'Ví ZaloPay': true,
  };

  int _selectedTemplateIndex = 0;
  final List<String> _templates = [
    'Đã nhận {số_tiền} từ {ngân_hàng}.',
    'Tài khoản {ngân_hàng} cộng {số_tiền}.',
    'Đã nhận {số_tiền} từ {ngân_hàng}, nội dung {mã_đơn}.',
  ];

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceSettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Cấu hình hệ thống',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CẤU HÌNH CÚ PHÁP ĐỌC
              _buildSectionTitle('1. Mẫu cú pháp đọc tiền', Icons.format_quote_rounded, const Color(0xFF0284C7)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: List.generate(_templates.length, (idx) {
                    final isSelected = _selectedTemplateIndex == idx;
                    return InkWell(
                      onTap: () => setState(() => _selectedTemplateIndex = idx),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _templates[idx],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // 2. GIỌNG ĐỌC & TỐC ĐỘ
              _buildSectionTitle('2. Giọng đọc & Âm lượng', Icons.record_voice_over_rounded, const Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giọng phát thanh:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: voiceProvider.currentPreset.id,
                              isDense: true,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
                              items: VoiceSettingsProvider.availablePresets.map((v) {
                                return DropdownMenuItem(
                                  value: v.id,
                                  child: Text('${v.name} (${v.region})'),
                                );
                              }).toList(),
                              onChanged: (id) {
                                if (id != null) {
                                  voiceProvider.selectVoice(id);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tốc độ đọc:', style: TextStyle(fontSize: 13)),
                        Text('${(voiceProvider.speechRate * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Slider(
                      value: voiceProvider.speechRate,
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      activeColor: const Color(0xFF8B5CF6),
                      onChanged: (val) => voiceProvider.setSpeechRate(val),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cao độ giọng (Pitch):', style: TextStyle(fontSize: 13)),
                        Text('${(voiceProvider.pitch * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Slider(
                      value: voiceProvider.pitch,
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      activeColor: const Color(0xFF8B5CF6),
                      onChanged: (val) => voiceProvider.setPitch(val),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFF8B5CF6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('Nghe thử giọng đọc mẫu'),
                        onPressed: () {
                          voiceProvider.playSample();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. DANH SÁCH NGÂN HÀNG HỖ TRỢ
              _buildSectionTitle('3. Danh sách ngân hàng lắng nghe', Icons.account_balance_rounded, const Color(0xFF10B981)),
              const SizedBox(height: 8),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 0,
                child: Column(
                  children: _enabledBanks.entries.map((entry) {
                    return SwitchListTile(
                      activeThumbColor: const Color(0xFF10B981),
                      title: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: entry.value,
                      onChanged: (val) {
                        setState(() {
                          _enabledBanks[entry.key] = val;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 4. BỘ LỌC AN TOÀN NÂNG CAO
              _buildSectionTitle('4. Bộ lọc nâng cao', Icons.tune_rounded, const Color(0xFFF59E0B)),
              const SizedBox(height: 8),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 0,
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: const Color(0xFFF59E0B),
                      title: const Text('Âm chuông Ting-ting trước khi đọc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Phát âm thanh báo hiệu trước khi đọc số tiền', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: voiceProvider.playChime,
                      onChanged: (val) => voiceProvider.togglePlayChime(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFFF59E0B),
                      title: const Text('Chống trùng lặp thông báo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Bỏ qua khi cùng 1 giao dịch được báo 2 lần liên tiếp', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: true,
                      onChanged: (val) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFFF59E0B),
                      title: const Text('Bỏ qua biến động trừ tiền (DEBIT)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Chỉ đọc to khi nhận tiền vào, bỏ qua khi tiền bị trừ ra', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: true,
                      onChanged: (val) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

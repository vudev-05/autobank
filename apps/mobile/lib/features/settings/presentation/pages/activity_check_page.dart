import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:autobank_mobile/features/notification_listener/presentation/notification_service.dart';

class ActivityCheckPage extends StatefulWidget {
  const ActivityCheckPage({super.key});

  @override
  State<ActivityCheckPage> createState() => _ActivityCheckPageState();
}

class _ActivityCheckPageState extends State<ActivityCheckPage> {
  bool _isChecking = true;
  bool _notificationListenerGranted = false;
  bool _batteryOptimizationIgnored = false;
  final bool _ttsWorking = true;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isChecking = true);
    
    final notif = await NotificationService.isListenerEnabled();
    final battery = await NotificationService.isBatteryOptimizationIgnored();
    
    if (mounted) {
      setState(() {
        _notificationListenerGranted = notif;
        _batteryOptimizationIgnored = battery;
        _isChecking = false;
      });
    }
  }

  Future<void> _testTtsVoice() async {
    try {
      await _flutterTts.setLanguage('vi-VN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak('Kiểm tra giọng đọc thành công. Tiền vừa sang máy báo vang.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang phát âm thử nghiệm qua loa máy...'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi chạy TTS: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kiểm tra hoạt động & Quyền',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0284C7)),
            tooltip: 'Kiểm tra lại',
            onPressed: _checkAllPermissions,
          ),
        ],
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BANNER TỔNG QUAN
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: (_notificationListenerGranted && _batteryOptimizationIgnored)
                            ? [const Color(0xFF065F46), const Color(0xFF059669)]
                            : [const Color(0xFF1E293B), const Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            (_notificationListenerGranted && _batteryOptimizationIgnored)
                                ? Icons.verified_user_rounded
                                : Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_notificationListenerGranted && _batteryOptimizationIgnored)
                                    ? 'Máy đã sẵn sàng hoạt động 24/7'
                                    : 'Cần cấp thêm quyền để đảm bảo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (_notificationListenerGranted && _batteryOptimizationIgnored)
                                    ? 'Tất cả các quyền quan trọng đã được kích hoạt đầy đủ.'
                                    : 'Vui lòng bật quyền bên dưới để app phát âm to ngay khi có tiền sang.',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'DANH SÁCH QUYỀN HỆ THỐNG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 1. QUYỀN ĐỌC THÔNG BÁO (NOTIFICATION LISTENER)
                  _buildPermissionCard(
                    title: 'Quyền đọc thông báo ngân hàng',
                    isGranted: _notificationListenerGranted,
                    description: 'Bắt buộc để ứng dụng lắng nghe biến động số dư tức thì từ hơn 65+ ngân hàng và ví điện tử.',
                    guide: 'Bấm nút bên dưới > Tìm "Đọc Thông Báo Nhận Tiền" > Gạt công tắc sang BẬT để cho phép.',
                    actionText: _notificationListenerGranted ? 'Kiểm tra lại' : 'Cấp quyền ngay',
                    onAction: () async {
                      await NotificationService.openSettings();
                      await Future.delayed(const Duration(seconds: 1));
                      _checkAllPermissions();
                    },
                  ),

                  const SizedBox(height: 14),

                  // 2. CHẠY NỀN KHÔNG BỊ TẮT (BATTERY OPTIMIZATION)
                  _buildPermissionCard(
                    title: 'Cài đặt Pin Ứng dụng: Chọn "Không hạn chế"',
                    isGranted: _batteryOptimizationIgnored,
                    description: 'Đây là Cài đặt Pin của riêng ứng dụng AutoBank (KHÔNG phải chế độ tiết kiệm pin của máy). Mặc định Android để là "Tối ưu hóa" (Optimized) và sẽ tắt app khi khóa màn hình. Bạn cần chọn "Không hạn chế" (Unrestricted) để máy duy trì đọc tiền 24/7.',
                    guide: 'Bấm nút "Tắt tối ưu pin (Nhanh)" để cấp quyền trực tiếp, hoặc bấm "Mở Cài đặt Pin App" > Chọn Pin > Tích chọn "Không hạn chế" (Unrestricted).',
                    actionText: _batteryOptimizationIgnored ? 'Đã bật Không hạn chế' : 'Tắt tối ưu pin (Nhanh)',
                    onAction: () async {
                      await NotificationService.requestIgnoreBatteryOptimizations();
                      await Future.delayed(const Duration(seconds: 1));
                      _checkAllPermissions();
                    },
                    secondaryActionText: 'Mở Cài đặt Pin App',
                    onSecondaryAction: () => NotificationService.openAppSettings(),
                  ),

                  const SizedBox(height: 14),

                  // 3. BỘ MÁY PHÁT ÂM TIẾNG VIỆT (TTS)
                  _buildPermissionCard(
                    title: 'Động cơ giọng đọc (Text-to-Speech)',
                    isGranted: _ttsWorking,
                    description: 'Phát âm chuẩn tiếng Việt tự nhiên, tự động điều chỉnh âm lượng to rõ ràng.',
                    guide: 'Bấm nút bên dưới để nghe thử mẫu câu phát âm chuẩn.',
                    actionText: 'Phát âm thử',
                    onAction: _testTtsVoice,
                  ),

                  const SizedBox(height: 14),

                  // 4. THÔNG BÁO CỦA ỨNG DỤNG (POST NOTIFICATIONS)
                  _buildPermissionCard(
                    title: 'Thông báo đẩy của hệ thống',
                    isGranted: true,
                    description: 'Hiển thị popup toàn màn hình và trạng thái nhận tiền trên thanh trạng thái.',
                    guide: 'Cho phép thông báo trong phần Cài đặt ứng dụng.',
                    actionText: 'Mở cài đặt app',
                    onAction: () => NotificationService.openAppSettings(),
                  ),

                  const SizedBox(height: 24),

                  // NÚT KIỂM TRA LẠI TOÀN BỘ
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.sync_rounded, color: Colors.white),
                      label: const Text(
                        'Kiểm tra lại toàn bộ trạng thái',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _checkAllPermissions,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required bool isGranted,
    required String description,
    required String guide,
    required String actionText,
    required VoidCallback onAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    final statusColor = isGranted ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final statusBg = isGranted ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      isGranted ? '● Đã cấp quyền' : '● Chưa cấp quyền',
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guide,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (secondaryActionText != null && onSecondaryAction != null && !isGranted) ...[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                  onPressed: onSecondaryAction,
                  child: Text(
                    secondaryActionText,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: isGranted ? const Color(0xFFF1F5F9) : const Color(0xFF0284C7),
                  foregroundColor: isGranted ? const Color(0xFF475569) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  isGranted ? Icons.refresh : Icons.arrow_forward_rounded,
                  size: 14,
                ),
                label: Text(
                  actionText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: onAction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

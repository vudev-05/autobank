import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/tts/tts_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_picker_service.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../../transactions/domain/entities/normalized_transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class PosSmartCashierPage extends StatefulWidget {
  const PosSmartCashierPage({super.key});

  @override
  State<PosSmartCashierPage> createState() => _PosSmartCashierPageState();
}

class _PosSmartCashierPageState extends State<PosSmartCashierPage> with SingleTickerProviderStateMixin {
  final bool _isQrEnabled = true;
  String? _userQrImageData; // Base64 data URL hoặc URL ảnh QR của quán
  Uint8List? _decodedQrBytes;
  
  // Giao dịch phát sinh trong phiên quầy thu ngân này
  NormalizedTransaction? _sessionLastTx;
  int _initialTxCount = 0;
  bool _hasCheckedInitialCount = false;

  // Quản lý tiết kiệm pin & độ sáng màn hình
  bool _isDimmed = false;
  Timer? _inactivityTimer;
  Timer? _autoDismissAlertTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedQrImage();

    // Giữ màn hình luôn sáng 24/24 cho quầy thu ngân & phát giọng nói thông báo
    NotificationService.setKeepScreenOn(true);
    NotificationService.setScreenBrightness(1.0);
    TtsService().speakTestFeedback('Đã bật chế độ quầy thu ngân');
    _resetInactivityTimer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _radarAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isDimmed) {
      setState(() => _isDimmed = false);
      NotificationService.wakeUpScreen();
      NotificationService.setScreenBrightness(1.0);
    }
    // Tự động tối mờ màn hình sau 30 giây không chạm để tối ưu pin điện thoại
    _inactivityTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() => _isDimmed = true);
        NotificationService.setScreenBrightness(0.05);
      }
    });
  }

  void _onUserTouch() {
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _autoDismissAlertTimer?.cancel();
    _inactivityTimer?.cancel();
    NotificationService.setKeepScreenOn(false);
    NotificationService.setScreenBrightness(-1.0);
    TtsService().speakTestFeedback('Đã tắt chế độ quầy thu ngân');
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedQrImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('pos_user_uploaded_qr_image');
    if (savedData != null && savedData.isNotEmpty) {
      _processAndSetQrData(savedData);
    }
  }

  void _processAndSetQrData(String data) {
    Uint8List? bytes;
    try {
      if (data.startsWith('data:image')) {
        final commaIdx = data.indexOf(',');
        if (commaIdx != -1) {
          bytes = base64Decode(data.substring(commaIdx + 1));
        }
      } else if (!data.startsWith('http://') && !data.startsWith('https://')) {
        bytes = base64Decode(data);
      }
    } catch (_) {}

    setState(() {
      _userQrImageData = data;
      _decodedQrBytes = bytes;
    });
  }

  Future<void> _pickAndSaveQrImage() async {
    try {
      final base64Image = await ImagePickerService.pickImageAsBase64();
      if (base64Image != null && base64Image.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        // Xóa ảnh cũ trong bộ nhớ để giải phóng RAM & dung lượng
        await prefs.remove('pos_user_uploaded_qr_image');
        // Lưu ảnh mới
        await prefs.setString('pos_user_uploaded_qr_image', base64Image);
        
        _processAndSetQrData(base64Image);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã tải và cài đặt ảnh mã QR quầy thành công!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeQrImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pos_user_uploaded_qr_image');
    setState(() {
      _userQrImageData = null;
      _decodedQrBytes = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑 Đã xóa ảnh mã QR khỏi ứng dụng.'),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPasteUrlDialog() {
    final urlCtrl = TextEditingController(
      text: (_userQrImageData != null && (_userQrImageData!.startsWith('http://') || _userQrImageData!.startsWith('https://')))
          ? _userQrImageData
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text('Nhập link ảnh mã QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dán link ảnh mã QR từ ngân hàng, Zalo hoặc ảnh online của bạn:',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final link = urlCtrl.text.trim();
              Navigator.pop(ctx);
              if (link.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('pos_user_uploaded_qr_image');
                await prefs.setString('pos_user_uploaded_qr_image', link);
                _processAndSetQrData(link);
              }
            },
            child: const Text('Lưu link ảnh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final txs = txProvider.transactions;
    final activeAlert = txProvider.activeAlertTransaction;

    // Ghi nhận số giao dịch ban đầu khi mới mở quầy
    if (!_hasCheckedInitialCount) {
      _initialTxCount = txs.length;
      _hasCheckedInitialCount = true;
    } else if (txs.length > _initialTxCount) {
      // Có giao dịch mới phát sinh trong ca quầy thu ngân này!
      _sessionLastTx = txs.first;
    }

    // Khi có thông báo chuyển tiền đến: Đánh thức màn hình sáng & tự động đếm ngược đóng cảnh báo trả về QR
    final alertDuration = txProvider.alertDisplayDurationSeconds;
    if (activeAlert != null) {
      if (_isDimmed) {
        _isDimmed = false;
        NotificationService.wakeUpScreen();
        NotificationService.setScreenBrightness(1.0);
      }
      _autoDismissAlertTimer ??= Timer(Duration(seconds: alertDuration), () {
        if (mounted) {
          txProvider.dismissTransactionAlert();
          _autoDismissAlertTimer = null;
          _resetInactivityTimer();
        }
      });
    } else {
      _autoDismissAlertTimer?.cancel();
      _autoDismissAlertTimer = null;
    }

    final isStrobe = txProvider.isLightStrobeActive;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserTouch(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B132B),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'Quầy Thu Ngân Thông Minh',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF38BDF8)),
              onPressed: _pickAndSaveQrImage,
              tooltip: 'Tải ảnh mã QR từ máy',
            ),
            IconButton(
              icon: const Icon(Icons.link_rounded, color: Colors.white70),
              onPressed: _showPasteUrlDialog,
              tooltip: 'Dán link ảnh mã QR',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Hiệu ứng viền chớp sáng xanh lá khi tiền về
            if (isStrobe)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF10B981), width: 10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x8010B981), blurRadius: 40, spreadRadius: 16),
                    ],
                  ),
                ),
              ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              children: [
                // ==========================================
                // 1. THANH TRẠNG THÁI GIAO DỊCH QUẦY (BẤM ĐỂ THỬ TIẾNG LOA THEO ĐÚNG CÀI ĐẶT GIỌNG NÓI)
                // ==========================================
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await NotificationService.ensureMaxVolume();
                    await TtsService().speakReceivedMoney(
                      amount: 50000,
                      bankName: 'MBBANK',
                      bypassChecks: true,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _sessionLastTx != null ? const Color(0xFF10B981) : const Color(0xFF334155),
                        width: _sessionLastTx != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: _sessionLastTx == null
                        ? Row(
                            children: [
                              ScaleTransition(
                                scale: _radarAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.sensors_rounded, color: Color(0xFF10B981), size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Đang sẵn sàng đọc thông báo khi nhận được tiền',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Loa đang trực 24/7 (Bấm vào đây để thử tiếng)',
                                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.volume_up_rounded, color: Color(0xFF38BDF8), size: 20),
                            ],
                          )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Vừa nhận: +${CurrencyFormatter.formatVND(_sessionLastTx!.amount)}',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 21,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_sessionLastTx!.bankCode} · ${_sessionLastTx!.content.isNotEmpty ? _sessionLastTx!.content : 'Thanh toán thành công'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                // ==========================================
                // 2. KHUNG HIỂN THỊ MÃ QR THANH TOÁN
                // ==========================================
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162032),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.qr_code_2_rounded, color: Color(0xFF38BDF8), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Mã QR quầy thanh toán',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isQrEnabled ? const Color(0x2E10B981) : Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isQrEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                                    color: _isQrEnabled ? const Color(0xFF10B981) : Colors.white54,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isQrEnabled ? 'TRỰC TUYẾN' : 'OFF',
                                    style: TextStyle(
                                      color: _isQrEnabled ? const Color(0xFF10B981) : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Ô HIỂN THỊ ẢNH QR CỦA QUÁN
                        if (_userQrImageData != null)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (ctx, child) => Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 260,
                                height: 260,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x330284C7),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: _decodedQrBytes != null
                                      ? Image.memory(
                                          _decodedQrBytes!,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.network(
                                          _userQrImageData!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (ctx, err, stack) => const Center(
                                            child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          )
                        else
                          // Chưa tải ảnh QR
                          Container(
                            width: 260,
                            height: 260,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_photo_alternate_rounded, size: 48, color: Color(0xFF38BDF8)),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Chưa có ảnh mã QR',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tải ảnh mã QR ngân hàng của quán để khách quét thanh toán',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                                  label: const Text('Tải ảnh QR lên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _pickAndSaveQrImage,
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        // Các nút hành động thao tác với ảnh QR
                        if (_userQrImageData != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF38BDF8)),
                                label: const Text('Đổi ảnh QR', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13)),
                                onPressed: _pickAndSaveQrImage,
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF87171)),
                                label: const Text('Xóa ảnh', style: TextStyle(color: Color(0xFFF87171), fontSize: 13)),
                                onPressed: _removeQrImage,
                              ),
                            ],
                          ),

                        const Text(
                          'Khách quét mã QR trực tiếp trên màn hình quầy',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Thông báo lưu ý
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_up_rounded, color: Color(0xFF38BDF8), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quý khách vui lòng lắng nghe loa xác nhận số tiền khi chuyển khoản thành công',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // NÚT THOÁT
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Thoát quầy thu ngân',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MÀN HÌNH TỐI MỜ TIẾT KIỆM PIN SAU 30 GIÂY: VẪN HIỂN THỊ MÃ QR ĐỂ KHÁCH QUÉT, ẨN THÔNG TIN KHÁC
          if (_isDimmed)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _resetInactivityTimer,
                child: Container(
                  color: const Color(0xFF000000), // Đen OLED tuyệt đối 100% tiết kiệm pin tối đa
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header siêu tinh gọn
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'QUẦY THANH TOÁN TỰ ĐỘNG · TRỰC 24/24',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),

                        // KHUNG MÃ QR NỔI BẬT CHÍNH GIỮA MÀN HÌNH ĐỂ KHÁCH QUÉT NGAY
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_userQrImageData != null)
                              Container(
                                width: 280,
                                height: 280,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x220284C7),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: _decodedQrBytes != null
                                      ? Image.memory(
                                          _decodedQrBytes!,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.network(
                                          _userQrImageData!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (ctx, err, stack) => const Center(
                                            child: Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.black87),
                                          ),
                                        ),
                                ),
                              )
                            else
                              Container(
                                width: 280,
                                height: 280,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_scanner_rounded, size: 64, color: Color(0xFF38BDF8)),
                                    SizedBox(height: 12),
                                    Text(
                                      'Chưa cài ảnh mã QR',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Chạm vào màn hình để tải ảnh QR ngân hàng lên quầy',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 18),
                            const Text(
                              'Quét mã QR để chuyển khoản thanh toán',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Loa quầy sẽ tự động phát âm thanh khi tiền vào',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Footer nhắc chạm để bật sáng
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_rounded, color: Color(0xFF64748B), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Chạm màn hình để bật sáng đầy đủ',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // LỚP PHỦ TIẾT KIỆM PIN (CHẾ ĐỘ CHỜ SAU 30S)
          if (_isDimmed && activeAlert == null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onUserTouch,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.88),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Icon(Icons.nightlight_round, color: Color(0xFFFBBF24), size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quầy Thu Ngân Đang Chờ',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chạm vào màn hình để bật sáng',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🔔 Loa vẫn trực 24/7 và sẵn sàng đọc khi có tiền về',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // MÀN HÌNH CẢNH BÁO TIỀN VỀ VÀ PHÂN LOẠI QUỸ CHO QUẦY THU NGÂN
          if (activeAlert != null)
            Positioned.fill(
              child: _buildCashierAlertOverlay(context, activeAlert, txProvider),
            ),
        ],
      ),
    ),
  );
  }

  /// Màn hình phân loại giao dịch toàn màn hình nổi bật trên quầy thu ngân khi có tiền về
  Widget _buildCashierAlertOverlay(BuildContext context, NormalizedTransaction tx, TransactionProvider txProvider) {
    final isCredit = tx.type.isCredit;
    final time = tx.transactionTime;
    final alertDuration = txProvider.alertDisplayDurationSeconds;

    // Xác định phân loại hiện tại đang thuộc Doanh Nghiệp hay Cá Nhân
    final existingCat = tx.category ?? '';
    String currentScope;
    if (existingCat.startsWith('[Cá Nhân]')) {
      currentScope = 'Cá Nhân';
    } else if (existingCat.startsWith('[Doanh Nghiệp]')) {
      currentScope = 'Doanh Nghiệp';
    } else {
      currentScope = isCredit ? 'Doanh Nghiệp' : 'Cá Nhân';
    }

    return StatefulBuilder(
      builder: (context, setOverlayState) {
        final bizCats = txProvider.businessBudgets.keys.toList();
        final personalCats = txProvider.personalBudgets.keys.toList();
        final activeList = currentScope == 'Doanh Nghiệp' ? bizCats : personalCats;

        return Container(
          color: Colors.black.withValues(alpha: 0.90),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isCredit ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCredit ? const Color(0xFF10B981) : const Color(0xFFE11D48)).withValues(alpha: 0.45),
                        blurRadius: 36,
                        spreadRadius: 6,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCredit ? const Color(0xFF064E3B) : const Color(0xFF881337),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.notifications_active_rounded : Icons.payments_rounded,
                          size: 42,
                          color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFF43F5E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isCredit ? '🔔 ĐÃ NHẬN TIỀN VỀ TÀI KHOẢN!' : '⚡ BIẾN ĐỘNG SỐ DƯ (CHI TIÊU)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFF43F5E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngân hàng ${tx.bankCode}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Số tiền
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isCredit ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFF881337).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCredit ? const Color(0xFF059669) : const Color(0xFFBE123C),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${isCredit ? '+' : '-'}${CurrencyFormatter.formatVND(tx.amount)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isCredit ? const Color(0xFF22C55E) : const Color(0xFFF43F5E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} • ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            ),
                            if (tx.content.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                tx.content,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ==========================================
                      // KHỐI PHÂN LOẠI QUỸ: DOANH NGHIỆP VS CÁ NHÂN
                      // ==========================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2 Tab chọn Quỹ Doanh Nghiệp vs Cá Nhân
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setOverlayState(() => currentScope = 'Doanh Nghiệp'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: currentScope == 'Doanh Nghiệp' ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: currentScope == 'Doanh Nghiệp' ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.business_center_rounded, size: 14, color: currentScope == 'Doanh Nghiệp' ? Colors.white : const Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '🏢 Quỹ Doanh Nghiệp (${bizCats.length})',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: currentScope == 'Doanh Nghiệp' ? Colors.white : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setOverlayState(() => currentScope = 'Cá Nhân'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: currentScope == 'Cá Nhân' ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: currentScope == 'Cá Nhân' ? const Color(0xFFFB7185) : const Color(0xFF334155),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person_rounded, size: 14, color: currentScope == 'Cá Nhân' ? Colors.white : const Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '👤 Quỹ Cá Nhân (${personalCats.length})',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: currentScope == 'Cá Nhân' ? Colors.white : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Danh sách Chip Quỹ của Tab đang chọn
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: activeList.map((cat) {
                                final fullCat = '[$currentScope] $cat';
                                final isSelected = (tx.category == fullCat) || (tx.category == cat);
                                return ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: currentScope == 'Doanh Nghiệp' ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                                  backgroundColor: const Color(0xFF0F172A),
                                  labelStyle: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                  ),
                                  onSelected: (_) {
                                    txProvider.updateAlertCategory(fullCat);
                                    setOverlayState(() {});
                                  },
                                );
                              }).toList(),
                            ),
                            if (tx.category != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF064E3B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF22C55E)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Đã vào: "${tx.category}"',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CẤU HÌNH THỜI GIAN ĐÓNG TỰ ĐỘNG
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Color(0xFF38BDF8), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Tự đóng sau ${alertDuration}s:',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 4,
                            children: [5, 10, 15, 30].map((sec) {
                              final isCur = alertDuration == sec;
                              return InkWell(
                                onTap: () {
                                  txProvider.setAlertDisplayDuration(sec);
                                  _autoDismissAlertTimer?.cancel();
                                  _autoDismissAlertTimer = Timer(Duration(seconds: sec), () {
                                    if (mounted) {
                                      txProvider.dismissTransactionAlert();
                                      _autoDismissAlertTimer = null;
                                      _resetInactivityTimer();
                                    }
                                  });
                                  setOverlayState(() {});
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCur ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isCur ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                                  ),
                                  child: Text(
                                    '${sec}s',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isCur ? Colors.white : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nút đóng ngay trả về mã QR
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: const Text('Đã Nhận Tiền · Trả Về Mã QR Quầy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            _autoDismissAlertTimer?.cancel();
                            _autoDismissAlertTimer = null;
                            txProvider.dismissTransactionAlert();
                            _resetInactivityTimer();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/bank_directory_widget.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../auth/presentation/providers/google_auth_provider.dart';
import '../../../notification_listener/presentation/notification_service.dart';
import '../../../subscription/presentation/pages/register_subscription_page.dart';
import '../../../system/presentation/providers/system_config_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class SettingsGuidePage extends StatelessWidget {
  const SettingsGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = context.watch<TransactionProvider>();
    final sysConfig = context.watch<SystemConfigProvider>();
    final googleAuth = context.watch<GoogleAuthProvider>();
    final acc = googleAuth.currentAccount;

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, size: 24, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Cài đặt & Tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          // ==========================================
          // 1. TÀI KHOẢN GOOGLE ĐĂNG NHẬP & ĐỔI NICK
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tài khoản Google',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: acc.isActivated ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      acc.isActivated ? Icons.verified_rounded : Icons.pending_rounded,
                      size: 13,
                      color: acc.isActivated ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      acc.isActivated ? 'Đã kích hoạt' : 'Chưa kích hoạt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: acc.isActivated ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF2563EB),
                            child: Text(
                              acc.initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white,
                              child: GoogleLogo(size: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              acc.email,
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                acc.activePackageName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0369A1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('Hạn sử dụng gói:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                        Text(
                          acc.isLifetime ? 'Vĩnh viễn (Trọn đời)' : dateFormat.format(acc.expireDate),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFECDD3)),
                            backgroundColor: const Color(0xFFFFF1F2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFDC2626)),
                          label: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626))),
                          onPressed: () => _confirmSignOut(context, googleAuth),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_rounded, size: 16, color: Color(0xFF16A34A)),
                              SizedBox(width: 6),
                              Text(
                                'Bảo vệ phiên 24/7',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==========================================
          // 2. THÔNG TIN QUẦY & CỬA HÀNG (SHOP PROFILE)
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông tin Quầy & Cửa hàng',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF0284C7),
                ),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Chỉnh sửa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _showEditShopInfoDialog(context, googleAuth),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.storefront_rounded,
                    title: 'Tên quán / Cửa hàng',
                    value: acc.shop,
                    accentColor: const Color(0xFF0284C7),
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    icon: Icons.phone_rounded,
                    title: 'Số điện thoại chủ quán',
                    value: acc.phone,
                    accentColor: const Color(0xFF10B981),
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    icon: Icons.all_inclusive_rounded,
                    title: 'Phạm vi nhận biến động số dư',
                    value: 'Tất cả 65+ Ngân hàng & Ví điện tử trên điện thoại',
                    accentColor: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==========================================
          // 3. BẢO MẬT KHÓA 1 THIẾT BỊ DUY NHẤT
          // ==========================================
          Text(
            'Bảo mật Khóa 1 Thiết Bị Duy Nhất',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: googleAuth.isDeviceLockedToCurrent ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA),
                  width: 1.2,
                ),
                color: googleAuth.isDeviceLockedToCurrent ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: googleAuth.isDeviceLockedToCurrent ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          googleAuth.isDeviceLockedToCurrent ? Icons.verified_user_rounded : Icons.lock_clock_rounded,
                          color: googleAuth.isDeviceLockedToCurrent ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              googleAuth.isDeviceLockedToCurrent
                                  ? 'Đã Khóa Độc Quyền Thiết Bị Này'
                                  : 'Chưa Liên Kết Thiết Bị Cố Định',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: googleAuth.isDeviceLockedToCurrent ? const Color(0xFF14532D) : const Color(0xFF9A3412),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Thiết bị: ${googleAuth.deviceName} (${googleAuth.currentDeviceId})',
                              style: TextStyle(
                                fontSize: 12,
                                color: googleAuth.isDeviceLockedToCurrent ? const Color(0xFF166534) : const Color(0xFFC2410C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chính sách bảo mật: 1 tài khoản Google chỉ được phát loa trên 1 điện thoại duy nhất. Nếu đổi sang máy khác, bạn phải Hủy liên kết ở máy cũ hoặc xác thực chuyển máy bằng mã OTP.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                          icon: const Icon(Icons.link_off_rounded, size: 16),
                          label: const Text('Hủy liên kết máy này', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _confirmUnbindDevice(context, googleAuth),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.phonelink_ring_rounded, size: 16),
                          label: const Text('Đổi máy bằng OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showForceSwitchOtpDialog(context, googleAuth),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==========================================
          // 4. QUẢN LÝ GÓI BẢN QUYỀN
          // ==========================================
          Text(
            'Quản lý Bản Quyền & Gói Cước',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acc.activePackageName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          acc.isLifetime
                              ? 'Hạn dùng: Vĩnh viễn trọn đời (Không giới hạn)'
                              : 'Còn đến: ${dateFormat.format(acc.expireDate)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (acc.isLifetime)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'VIP Trọn Đời',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterSubscriptionPage()),
                        );
                      },
                      child: const Text('Gia hạn / Thêm gói', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ==========================================
          // 5. TRẠNG THÁI CẤP QUYỀN VÀ NỀN 24/7
          // ==========================================
          Text(
            'Trạng thái Cấp Quyền & Vận Hành',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: txProvider.isPermissionGranted ? Colors.green.shade50 : Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        txProvider.isPermissionGranted ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: txProvider.isPermissionGranted ? Colors.green.shade700 : Colors.amber.shade800,
                        size: 24,
                      ),
                    ),
                    title: const Text('Quyền đọc thông báo ngân hàng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      txProvider.isPermissionGranted ? 'Đang hoạt động bình thường' : 'Chưa được cấp quyền',
                      style: TextStyle(
                        color: txProvider.isPermissionGranted ? Colors.green.shade800 : Colors.amber.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        NotificationService.openSettings();
                      },
                      child: const Text('Mở Cài đặt'),
                    ),
                  ),
                  const Divider(height: 16),
                  FutureBuilder<bool>(
                    future: NotificationService.isBatteryOptimizationIgnored(),
                    builder: (context, snapshot) {
                      final isIgnored = snapshot.data ?? true;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isIgnored ? Colors.green.shade50 : Colors.amber.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isIgnored ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
                            color: isIgnored ? Colors.green.shade700 : Colors.amber.shade900,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'Chế độ Pin không giới hạn (Chống tắt ngầm 24/7)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          isIgnored
                              ? 'Đang hoạt động 24/24 (Đã tắt tiết kiệm pin)'
                              : 'Chưa cấp quyền: Cần bật Không giới hạn pin để không bị ngắt ngầm khi tắt màn hình.',
                          style: TextStyle(
                            color: isIgnored ? Colors.green.shade800 : Colors.amber.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: OutlinedButton(
                          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () async {
                            await NotificationService.requestIgnoreBatteryOptimizations();
                          },
                          child: Text(isIgnored ? 'Đã bật' : 'Tắt tối ưu pin'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sysConfig.keepScreenOn ? Colors.blue.shade50 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.screen_lock_portrait_rounded,
                        color: sysConfig.keepScreenOn ? const Color(0xFF0284C7) : Colors.grey,
                        size: 22,
                      ),
                    ),
                    title: const Text('Màn hình chờ luôn sáng (Trực 24/24)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text(
                      'Giữ màn hình không bao giờ tắt khi cắm sạc trực quầy.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: sysConfig.keepScreenOn,
                    onChanged: (val) {
                      sysConfig.setKeepScreenOn(val);
                    },
                  ),
                  const Divider(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sysConfig.isPhoneListening ? Colors.green.shade50 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wifi_tethering_rounded,
                        color: sysConfig.isPhoneListening ? Colors.green.shade700 : Colors.grey,
                        size: 22,
                      ),
                    ),
                    title: const Text('Hoạt động nền & Truyền tín hiệu 24/24',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text(
                      'Tự động đồng bộ số dư và cấp quyền cho loa trình duyệt trên máy tính.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: sysConfig.isPhoneListening,
                    onChanged: (val) {
                      sysConfig.setIsPhoneListening(val);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // 6. KHUNG GIỜ ĐỌC THÔNG BÁO (LỊCH PHÁT LOA)
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Khung Giờ Đọc Thông Báo',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: txProvider.isScheduleEnabled ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: txProvider.isScheduleEnabled ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  txProvider.isScheduleEnabled
                      ? '${txProvider.scheduleStartHour.toString().padLeft(2, '0')}:${txProvider.scheduleStartMinute.toString().padLeft(2, '0')} - ${txProvider.scheduleEndHour.toString().padLeft(2, '0')}:${txProvider.scheduleEndMinute.toString().padLeft(2, '0')}'
                      : 'Cả ngày 24/24',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: txProvider.isScheduleEnabled ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: txProvider.isScheduleEnabled ? const Color(0xFFEFF6FF) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time_filled_rounded,
                        color: txProvider.isScheduleEnabled ? const Color(0xFF0284C7) : Colors.grey,
                        size: 22,
                      ),
                    ),
                    title: const Text('Chỉ đọc trong khung giờ đã cài đặt',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text(
                      'Ngoài khung giờ này, ứng dụng sẽ tự động im lặng để không làm phiền giấc ngủ và nghỉ ngơi.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: txProvider.isScheduleEnabled,
                    onChanged: (val) {
                      txProvider.updateSchedule(enabled: val);
                    },
                  ),

                  if (txProvider.isScheduleEnabled) ...[
                    const Divider(height: 16),
                    InkWell(
                      onTap: () => _showCustomScheduleDialog(context, txProvider),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Khung giờ đang áp dụng:',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Từ ${txProvider.scheduleStartHour.toString().padLeft(2, '0')}:${txProvider.scheduleStartMinute.toString().padLeft(2, '0')} đến ${txProvider.scheduleEndHour.toString().padLeft(2, '0')}:${txProvider.scheduleEndMinute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Row(
                              children: [
                                Text('Đổi giờ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                SizedBox(width: 4),
                                Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF0284C7)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Chọn nhanh khung giờ:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildSchedulePresetChip(
                          label: '☀️ 06:00 - 22:00 (Ban ngày)',
                          isSelected: txProvider.scheduleStartHour == 6 && txProvider.scheduleEndHour == 22,
                          onTap: () => txProvider.updateSchedule(enabled: true, startHour: 6, startMinute: 0, endHour: 22, endMinute: 0),
                        ),
                        _buildSchedulePresetChip(
                          label: '⚡ 06:00 - 10:00 (Sáng sớm)',
                          isSelected: txProvider.scheduleStartHour == 6 && txProvider.scheduleEndHour == 10,
                          onTap: () => txProvider.updateSchedule(enabled: true, startHour: 6, startMinute: 0, endHour: 10, endMinute: 0),
                        ),
                        _buildSchedulePresetChip(
                          label: '🏢 08:00 - 18:00 (Hành chính)',
                          isSelected: txProvider.scheduleStartHour == 8 && txProvider.scheduleEndHour == 18,
                          onTap: () => txProvider.updateSchedule(enabled: true, startHour: 8, startMinute: 0, endHour: 18, endMinute: 0),
                        ),
                        _buildSchedulePresetChip(
                          label: '🌙 17:00 - 23:00 (Buổi tối)',
                          isSelected: txProvider.scheduleStartHour == 17 && txProvider.scheduleEndHour == 23,
                          onTap: () => txProvider.updateSchedule(enabled: true, startHour: 17, startMinute: 0, endHour: 23, endMinute: 0),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // 7. CẨM NANG CHẠY NGẦM THEO HÃNG MÁY
          // ==========================================
          Text(
            'Cẩm nang chạy ngầm 24/7 theo hãng máy',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildBrandAccordion(
            title: 'Xiaomi (MIUI / HyperOS)',
            icon: Icons.phone_android,
            steps: [
              '1. Vào Cài đặt -> Ứng dụng -> Quản lý ứng dụng -> Chọn "Đọc thông báo nhận tiền".',
              '2. Bật công tắc "Tự khởi chạy" (Autostart).',
              '3. Tiết kiệm pin -> Chọn "Không hạn chế" (No restrictions).',
              '4. Mở màn hình đa nhiệm -> Nhấn giữ app và chọn icon Ổ khóa để không bị đóng.',
            ],
          ),
          const SizedBox(height: 8),

          _buildBrandAccordion(
            title: 'Samsung (One UI)',
            icon: Icons.smartphone,
            steps: [
              '1. Vào Cài đặt -> Pin & Chăm sóc thiết bị -> Pin.',
              '2. Giới hạn sử dụng dưới nền -> Thêm app vào "Ứng dụng không bao giờ ngủ".',
              '3. Tắt tính năng "Tối ưu hóa pin" cho app.',
            ],
          ),
          const SizedBox(height: 8),

          _buildBrandAccordion(
            title: 'Oppo / Realme (ColorOS / Realme UI)',
            icon: Icons.phonelink_setup,
            steps: [
              '1. Cài đặt -> Quản lý ứng dụng -> Chọn app.',
              '2. Cho phép hoạt động dưới nền và Tự động khởi chạy.',
              '3. Khóa app trong danh sách ứng dụng gần đây.',
            ],
          ),
          const SizedBox(height: 8),

          _buildBrandAccordion(
            title: 'Vivo (Funtouch OS)',
            icon: Icons.devices,
            steps: [
              '1. Cài đặt -> Quản lý quyền -> Tự khởi chạy -> Bật cho app.',
              '2. Pin -> Quản lý mức tiêu thụ pin dưới nền -> Chọn "Cho phép tiêu thụ pin dưới nền cao".',
            ],
          ),

          const SizedBox(height: 24),

          // ==========================================
          // 7. HỖ TRỢ KỸ THUẬT & CSKH 24/7
          // ==========================================
          Text(
            'Hỗ trợ kỹ thuật & CSKH 24/7',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.phone_in_talk, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('Hotline kỹ thuật 24/7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(sysConfig.hotline, style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: sysConfig.hotline));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã sao chép hotline ${sysConfig.hotline}!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.chat_bubble_outline, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('Zalo hỗ trợ trực tuyến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('zalo.me/${sysConfig.hotline}', style: const TextStyle(color: Color(0xFF0284C7))),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: 'https://zalo.me/${sysConfig.hotline}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép link Zalo hỗ trợ!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.screen_share_outlined, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('Hỗ trợ cài đặt từ xa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Cài đặt qua UltraViewer / Anydesk miễn phí', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng liên hệ Hotline hoặc Zalo để được hỗ trợ từ xa!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // HỖ TRỢ 65+ NGÂN HÀNG & VÍ ĐIỆN TỬ (BÊ GIAO DIỆN WEB VỀ APP ĐIỆN THOẠI)
          const BankDirectoryWidget(showHeader: true),

          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  sysConfig.brandName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phiên bản v${sysConfig.latestVersion} (Đồng bộ SQL)',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandAccordion({
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFF0284C7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: steps
            .map(
              (step) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Dialog chỉnh sửa thông tin quán & SĐT
  void _showEditShopInfoDialog(BuildContext context, GoogleAuthProvider googleAuth) {
    final shopCtrl = TextEditingController(text: googleAuth.shopName);
    final phoneCtrl = TextEditingController(text: googleAuth.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Thông tin Cửa hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shopCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên quán / Cửa hàng',
                hintText: 'VD: Bánh mì Kim Anh Q1',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại chủ quán',
                hintText: 'VD: 0988 123 456',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (shopCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                googleAuth.updateAccountInfo(
                  shop: shopCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật thông tin cửa hàng thành công!'),
                    backgroundColor: Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  // Hộp thoại xác nhận đăng xuất tài khoản
  void _confirmSignOut(BuildContext context, GoogleAuthProvider googleAuth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Đăng xuất tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản "${googleAuth.email}" không?\n\nToàn bộ cấu hình câu đọc và dữ liệu của bạn đã được lưu an toàn trên hệ thống MySQL.',
          style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await googleAuth.signOut();
            },
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }





  // Xác nhận hủy liên kết thiết bị
  void _confirmUnbindDevice(BuildContext context, GoogleAuthProvider googleAuth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Hủy liên kết thiết bị', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Sau khi hủy liên kết, bạn có thể mang tài khoản này đăng nhập vào điện thoại mới. Điện thoại hiện tại sẽ tạm dừng phát loa cho đến khi liên kết lại.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await googleAuth.unbindCurrentDevice();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Đã hủy liên kết máy thành công! Bạn có thể đăng nhập trên máy mới.' : 'Lỗi khi hủy liên kết!'),
                    backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Đồng ý Hủy'),
          ),
        ],
      ),
    );
  }

  // Modal đổi máy bằng OTP
  void _showForceSwitchOtpDialog(BuildContext context, GoogleAuthProvider googleAuth) {
    final otpCtrl = TextEditingController();
    const demoOtp = '888999';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.phonelink_lock_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Xác thực đổi thiết bị', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Để chuyển bản quyền từ máy cũ sang máy này, vui lòng nhập mã OTP xác thực (Mã demo OTP: $demoOtp):',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(letterSpacing: 6, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '------',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (otpCtrl.text.trim() == demoOtp || otpCtrl.text.trim().length == 6) {
                Navigator.pop(ctx);
                final res = await googleAuth.bindCurrentDevice(forceSwitch: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['success'] == true ? 'Đã hủy máy cũ và liên kết thành công sang máy này!' : (res['message'] ?? 'Lỗi liên kết')),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mã OTP không chính xác! Vui lòng nhập $demoOtp'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Xác nhận Đổi Máy'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  void _showCustomScheduleDialog(BuildContext context, TransactionProvider txProvider) {
    int startHour = txProvider.scheduleStartHour;
    int endHour = txProvider.scheduleEndHour;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.more_time_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('Cài đặt Khung Giờ Đọc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chỉ phát âm thanh đọc thông báo nhận tiền trong khoảng thời gian này. Ngoài giờ này app sẽ im lặng.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giờ bắt đầu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: startHour,
                              items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('${i.toString().padLeft(2, '0')}:00'),
                                ),
                              ),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => startHour = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Text('➔', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giờ kết thúc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: endHour,
                              items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('${i.toString().padLeft(2, '0')}:00'),
                                ),
                              ),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => endHour = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ví dụ: Từ 06:00 đến 10:00 (hoặc 06:00 đến 22:00) theo đúng mong muốn của bạn.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                txProvider.updateSchedule(
                  enabled: true,
                  startHour: startHour,
                  startMinute: 0,
                  endHour: endHour,
                  endMinute: 0,
                );
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật khung giờ đọc thông báo: ${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00!'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Áp dụng khung giờ'),
            ),
          ],
        ),
      ),
    );
  }
}

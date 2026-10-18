import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DevicePreset {
  iphone15Pro('iPhone 15 Pro', 393, 852),
  galaxyS24('Galaxy S24', 412, 915),
  compact('iPhone SE / Nhỏ', 375, 667),
  responsive('Tự co giãn', 420, 0);

  final String label;
  final double width;
  final double height;
  const DevicePreset(this.label, this.width, this.height);
}

class PhoneSimulatorFrame extends StatefulWidget {
  final Widget child;

  const PhoneSimulatorFrame({
    super.key,
    required this.child,
  });

  @override
  State<PhoneSimulatorFrame> createState() => _PhoneSimulatorFrameState();
}

class _PhoneSimulatorFrameState extends State<PhoneSimulatorFrame> {
  DevicePreset _selectedDevice = DevicePreset.iphone15Pro;
  bool _showFrame = true;

  @override
  Widget build(BuildContext context) {
    // Khi chạy trên thiết bị di động thật (Android / iOS): Luôn hiển thị toàn màn hình gốc
    if (!kIsWeb) {
      return widget.child;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 500 || !_showFrame) {
      return widget.child;
    }

    final targetWidth = _selectedDevice.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final targetHeight = _selectedDevice.height == 0 
        ? (screenHeight - 100).clamp(600.0, 920.0) 
        : _selectedDevice.height;

    // Scale nếu màn hình máy tính có chiều cao nhỏ hơn khung điện thoại
    final maxAvailableHeight = screenHeight - 110;
    final scale = (maxAvailableHeight > 0 && maxAvailableHeight < targetHeight)
        ? (maxAvailableHeight / targetHeight).clamp(0.65, 1.0)
        : 1.0;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Nền bàn làm việc studio Slate-900
      body: SafeArea(
        child: Column(
          children: [
            // Thanh công cụ Studio trên đỉnh
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_android, size: 16, color: Color(0xFF38BDF8)),
                          SizedBox(width: 6),
                          Text(
                            'MÔ PHỎNG ĐIỆN THOẠI (DEV PREVIEW)',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Dropdown chọn máy
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF475569)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DevicePreset>(
                          value: _selectedDevice,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          items: DevicePreset.values.map((preset) {
                            return DropdownMenuItem(
                              value: preset,
                              child: Text('${preset.label} (${preset.width.toInt()}px)'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDevice = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Gợi ý Hot reload
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 16, color: Color(0xFF34D399)),
                          SizedBox(width: 4),
                          Text(
                            'Lưu code & Bấm "r" ở Terminal để Hot-Reload tức thì < 1s',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Nút tắt khung (xem toàn màn hình)
                    IconButton(
                      tooltip: 'Chuyển sang toàn màn hình',
                      icon: const Icon(Icons.fullscreen, color: Colors.white70, size: 20),
                      onPressed: () {
                        setState(() => _showFrame = false);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Khung điện thoại ở giữa
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: targetWidth + 24, // Thêm độ dày viền
                        height: targetHeight + 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B), // Khung viền kim loại
                          borderRadius: BorderRadius.circular(52),
                          border: Border.all(
                            color: const Color(0xFF475569),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 40,
                              spreadRadius: 10,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8), // Bezel đen
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(44),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // Ứng dụng thật
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                                  child: widget.child,
                                ),
                              ),

                              // Thanh trạng thái đỉnh (Status Bar)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 42,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  color: Colors.transparent,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      // Dynamic Island
                                      Container(
                                        width: 100,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(right: 12),
                                              width: 9,
                                              height: 9,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF1E293B),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.signal_cellular_4_bar, size: 14),
                                          SizedBox(width: 4),
                                          Icon(Icons.wifi, size: 14),
                                          SizedBox(width: 4),
                                          Icon(Icons.battery_charging_full, size: 16, color: Color(0xFF22C55E)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Vạch điều hướng dưới cùng (Home Indicator)
                              Positioned(
                                bottom: 6,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 130,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

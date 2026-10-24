import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/google_auth_provider.dart';
import 'app_pin_security_service.dart';

class AppLockScreenOverlay extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const AppLockScreenOverlay({super.key, this.onUnlocked});

  @override
  State<AppLockScreenOverlay> createState() => _AppLockScreenOverlayState();
}

class _AppLockScreenOverlayState extends State<AppLockScreenOverlay> {
  // Mode 0: Nhập mã PIN 4 số
  // Mode 1: Nhập OTP 6 số khi quên mã
  // Mode 2: Đặt lại mã PIN mới sau khi xác thực OTP thành công
  int _screenMode = 0;

  String _pinInput = '';
  String _otpInput = '';
  String _newPin1 = '';
  String _newPin2 = '';
  String? _fallbackOtp;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final pinService = context.watch<AppPinSecurityService>();
    final googleAuth = context.watch<GoogleAuthProvider>();
    final userEmail = googleAuth.isSignedIn && googleAuth.email.isNotEmpty
        ? googleAuth.email
        : 'admin@autobank.com';

    return PopScope(
      canPop: false, // Tuyệt đối không cho bấm back để lọt vào app
      child: Material(
        color: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_screenMode == 0)
                      _buildPinInputView(pinService)
                    else if (_screenMode == 1)
                      _buildOtpVerificationView(pinService, userEmail)
                    else
                      _buildResetPinView(pinService),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODE 0: NHẬP MÃ PIN 4 SỐ ĐỂ MỞ KHÓA
  // ==========================================
  Widget _buildPinInputView(AppPinSecurityService pinService) {
    return Column(
      children: [
        // Icon Khiên bảo mật
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
          ),
          child: const Icon(Icons.shield_rounded, color: Color(0xFF0284C7), size: 38),
        ),
        const SizedBox(height: 16),

        const Text(
          'Mã Bảo Mật Ứng Dụng',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'Nhập mã PIN 4 số để mở khóa bảo vệ phiên làm việc của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 8),

        const SizedBox(height: 16),

        // 4 Chấm tròn PIN
        _buildPinDots(pinLength: _pinInput.length, total: 4, hasError: _hasError),
        const SizedBox(height: 12),

        if (_hasError) ...[
          Text(
            _errorMessage,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),

        // Bàn phím số
        _buildNumPad(
          onDigit: (d) async {
            if (_pinInput.length < 4) {
              setState(() {
                _pinInput += d;
                _hasError = false;
              });

              if (_pinInput.length == 4) {
                if (pinService.verifyPin(_pinInput)) {
                  HapticFeedback.lightImpact();
                  await pinService.recordUnlockSuccess();
                  widget.onUnlocked?.call();
                } else {
                  HapticFeedback.vibrate();
                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Mã PIN không chính xác! Vui lòng thử lại.';
                    _pinInput = '';
                  });
                }
              }
            }
          },
          onDelete: () {
            if (_pinInput.isNotEmpty) {
              setState(() => _pinInput = _pinInput.substring(0, _pinInput.length - 1));
            }
          },
        ),

        const SizedBox(height: 18),

        // NÚT QUÊN MÃ PIN
        TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF0284C7)),
          label: const Text(
            'Quên mã PIN? Nhận mã OTP qua Email',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
          ),
          onPressed: () => _startForgotFlow(pinService),
        ),
      ],
    );
  }

  // ==========================================
  // MODE 1: XÁC THỰC MÃ OTP 6 SỐ TỪ EMAIL
  // ==========================================
  Widget _buildOtpVerificationView(AppPinSecurityService pinService, String userEmail) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
          ),
          child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 34),
        ),
        const SizedBox(height: 16),

        const Text(
          'Xác Thực Cấp Lại PIN (6 Số)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),

        Text(
          'Hệ thống đã gửi mã xác thực 6 số đến:\n$userEmail',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 10),

        if (_fallbackOtp != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Mã OTP xác thực của bạn: $_fallbackOtp',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // 6 Ô OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final isFilled = i < _otpInput.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 38,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFilled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  width: 1.8,
                ),
              ),
              child: Text(
                isFilled ? _otpInput[i] : '-',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        if (_hasError) ...[
          Text(
            _errorMessage,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),

        _buildNumPad(
          onDigit: (d) async {
            if (_otpInput.length < 6) {
              setState(() {
                _otpInput += d;
                _hasError = false;
              });

              if (_otpInput.length == 6) {
                final isValid = await pinService.verifyPinResetOtpViaApi(userEmail, _otpInput);
                if (isValid) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _screenMode = 2; // Chuyển sang đặt lại mã PIN mới
                    _hasError = false;
                  });
                } else {
                  HapticFeedback.vibrate();
                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Mã OTP không đúng hoặc đã hết hạn!';
                    _otpInput = '';
                  });
                }
              }
            }
          },
          onDelete: () {
            if (_otpInput.isNotEmpty) {
              setState(() => _otpInput = _otpInput.substring(0, _otpInput.length - 1));
            }
          },
        ),

        const SizedBox(height: 16),

        // Nút quay lại màn hình nhập mã PIN
        TextButton.icon(
          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
          label: const Text('Quay lại màn hình nhập mã PIN', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          onPressed: () {
            setState(() {
              _screenMode = 0;
              _pinInput = '';
              _otpInput = '';
              _hasError = false;
            });
          },
        ),
      ],
    );
  }

  // ==========================================
  // MODE 2: THIẾT LẬP MÃ PIN 4 SỐ MỚI
  // ==========================================
  Widget _buildResetPinView(AppPinSecurityService pinService) {
    final isStep2 = _newPin1.length == 4;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDDD6FE), width: 2),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF8B5CF6), size: 34),
        ),
        const SizedBox(height: 16),

        Text(
          !isStep2 ? 'Tạo Mã PIN Mới (4 Số)' : 'Nhập Lại Mã PIN Để Xác Nhận',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),

        Text(
          !isStep2 ? 'Vui lòng chọn 4 chữ số mã PIN mới của bạn' : 'Nhập lại chính xác 4 số vừa tạo',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),

        _buildPinDots(pinLength: !isStep2 ? _newPin1.length : _newPin2.length, total: 4, hasError: _hasError),
        const SizedBox(height: 12),

        if (_hasError) ...[
          Text(
            _errorMessage,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),

        _buildNumPad(
          onDigit: (d) async {
            if (!isStep2) {
              if (_newPin1.length < 4) {
                setState(() {
                  _newPin1 += d;
                  _hasError = false;
                });
              }
            } else {
              if (_newPin2.length < 4) {
                setState(() {
                  _newPin2 += d;
                  _hasError = false;
                });

                if (_newPin2.length == 4) {
                  if (_newPin1 == _newPin2) {
                    await pinService.setPin(_newPin1);
                    await pinService.recordUnlockSuccess();
                    widget.onUnlocked?.call();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Đã cấp lại mã PIN mới thành công! Ứng dụng đã được mở khóa.'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    HapticFeedback.vibrate();
                    setState(() {
                      _hasError = true;
                      _errorMessage = 'Mã PIN xác nhận không khớp! Vui lòng nhập lại.';
                      _newPin2 = '';
                    });
                  }
                }
              }
            }
          },
          onDelete: () {
            setState(() {
              if (!isStep2) {
                if (_newPin1.isNotEmpty) _newPin1 = _newPin1.substring(0, _newPin1.length - 1);
              } else {
                if (_newPin2.isNotEmpty) {
                  _newPin2 = _newPin2.substring(0, _newPin2.length - 1);
                } else {
                  _newPin1 = '';
                }
              }
            });
          },
        ),
      ],
    );
  }

  Future<void> _startForgotFlow(AppPinSecurityService pinService) async {
    final googleAuth = context.read<GoogleAuthProvider>();
    final userEmail = googleAuth.isSignedIn && googleAuth.email.isNotEmpty
        ? googleAuth.email
        : 'admin@autobank.com';

    setState(() {
      _screenMode = 1;
      _otpInput = '';
      _hasError = false;
      _errorMessage = '';
    });

    final res = await pinService.requestPinResetOtpFromApi(userEmail);
    if (mounted) {
      setState(() {
        _fallbackOtp = res['otp'] as String?;
      });
    }
  }

  // ==========================================
  // WIDGETS CHUNG: PIN DOTS & BÀN PHÍM SỐ
  // ==========================================
  Widget _buildPinDots({required int pinLength, required int total, bool hasError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < pinLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? const Color(0xFFDC2626)
                : isFilled
                    ? const Color(0xFF0284C7)
                    : Colors.white,
            border: Border.all(
              color: hasError
                  ? const Color(0xFFDC2626)
                  : isFilled
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFCBD5E1),
              width: 2.2,
            ),
            boxShadow: isFilled && !hasError
                ? [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumPad({required ValueChanged<String> onDigit, required VoidCallback onDelete}) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 1; col <= 3; col++)
                  _buildNumBtn((row * 3 + col).toString(), onDigit),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72),
            _buildNumBtn('0', onDigit),
            SizedBox(
              width: 72,
              height: 72,
              child: IconButton(
                icon: const Icon(Icons.backspace_rounded, size: 26, color: Color(0xFF64748B)),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onDelete();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumBtn(String digit, ValueChanged<String> onDigit) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: () {
          HapticFeedback.lightImpact();
          onDigit(digit);
        },
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/google_auth_provider.dart';
import '../../features/notification_center/domain/models/app_notification_item.dart';
import '../../features/notification_center/presentation/providers/app_notification_provider.dart';
import 'app_pin_security_service.dart';

class AppPinSecurityDialogs {
  /// 1. CÀI ĐẶT MÃ PIN LẦN ĐẦU (4 SỐ)
  static Future<bool> showSetPinDialog(BuildContext context) async {
    final pinService = AppPinSecurityService();
    String pin1 = '';
    String pin2 = '';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isStep2 = pin1.length == 4;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !isStep2 ? 'Cài Đặt Mã PIN (4 Số)' : 'Nhập Lại Mã PIN Xác Nhận',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  !isStep2
                      ? 'Thiết lập mã PIN 4 số để bảo vệ app. Sau 1 tiếng không sử dụng, app sẽ yêu cầu nhập lại.'
                      : 'Vui lòng nhập lại chính xác 4 số mã PIN vừa chọn để xác nhận.',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                _buildPinDots(pinLength: !isStep2 ? pin1.length : pin2.length),
                const SizedBox(height: 24),

                _buildKeypad(
                  onNumberPress: (digit) async {
                    if (!isStep2) {
                      if (pin1.length < 4) {
                        setDialogState(() => pin1 += digit);
                      }
                    } else {
                      if (pin2.length < 4) {
                        setDialogState(() => pin2 += digit);
                        if (pin2.length == 4) {
                          if (pin1 == pin2) {
                            await pinService.setPin(pin1);
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                          } else {
                            HapticFeedback.vibrate();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Mã PIN không khớp! Vui lòng nhập lại.'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            setDialogState(() => pin2 = '');
                          }
                        }
                      }
                    }
                  },
                  onDeletePress: () {
                    setDialogState(() {
                      if (!isStep2) {
                        if (pin1.isNotEmpty) pin1 = pin1.substring(0, pin1.length - 1);
                      } else {
                        if (pin2.isNotEmpty) {
                          pin2 = pin2.substring(0, pin2.length - 1);
                        } else {
                          pin1 = '';
                        }
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    return result ?? false;
  }

  /// 2. ĐỔI MÃ PIN: BẮT BUỘC NHẬP MÃ PIN CŨ TRƯỚC
  static Future<bool> showChangePinDialog(BuildContext context) async {
    final pinService = AppPinSecurityService();
    if (!pinService.isPinEnabled) {
      return await showSetPinDialog(context);
    }

    String oldPinInput = '';
    String newPin1 = '';
    String newPin2 = '';
    int step = 1; // 1: Nhập mã cũ, 2: Nhập mã mới, 3: Xác nhận mã mới

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String titleText;
          String descText;
          int currentInputLength;

          if (step == 1) {
            titleText = 'Nhập Mã PIN Hiện Tại';
            descText = 'Vui lòng nhập mã PIN cũ để xác thực quyền đổi mật khẩu.';
            currentInputLength = oldPinInput.length;
          } else if (step == 2) {
            titleText = 'Nhập Mã PIN Mới (4 Số)';
            descText = 'Chọn 4 chữ số mã PIN mới bạn muốn sử dụng.';
            currentInputLength = newPin1.length;
          } else {
            titleText = 'Nhập Lại Mã PIN Mới';
            descText = 'Nhập lại chính xác 4 số mã PIN mới để xác nhận.';
            currentInputLength = newPin2.length;
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step == 1 ? Icons.lock_outline_rounded : Icons.lock_reset_rounded,
                    color: const Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titleText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  descText,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                _buildPinDots(pinLength: currentInputLength),
                const SizedBox(height: 24),

                _buildKeypad(
                  onNumberPress: (digit) async {
                    if (step == 1) {
                      if (oldPinInput.length < 4) {
                        setDialogState(() => oldPinInput += digit);
                        if (oldPinInput.length == 4) {
                          if (pinService.verifyPin(oldPinInput)) {
                            setDialogState(() => step = 2); // Qua bước nhập mã mới
                          } else {
                            HapticFeedback.vibrate();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Mã PIN cũ không chính xác!'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            setDialogState(() => oldPinInput = '');
                          }
                        }
                      }
                    } else if (step == 2) {
                      if (newPin1.length < 4) {
                        setDialogState(() => newPin1 += digit);
                        if (newPin1.length == 4) {
                          setDialogState(() => step = 3); // Qua bước xác nhận
                        }
                      }
                    } else {
                      if (newPin2.length < 4) {
                        setDialogState(() => newPin2 += digit);
                        if (newPin2.length == 4) {
                          if (newPin1 == newPin2) {
                            await pinService.changePin(oldPin: oldPinInput, newPin: newPin1);
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                          } else {
                            HapticFeedback.vibrate();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Mã PIN mới không khớp! Vui lòng nhập lại.'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            setDialogState(() => newPin2 = '');
                          }
                        }
                      }
                    }
                  },
                  onDeletePress: () {
                    setDialogState(() {
                      if (step == 1) {
                        if (oldPinInput.isNotEmpty) {
                          oldPinInput = oldPinInput.substring(0, oldPinInput.length - 1);
                        }
                      } else if (step == 2) {
                        if (newPin1.isNotEmpty) {
                          newPin1 = newPin1.substring(0, newPin1.length - 1);
                        }
                      } else {
                        if (newPin2.isNotEmpty) {
                          newPin2 = newPin2.substring(0, newPin2.length - 1);
                        } else {
                          step = 2;
                        }
                      }
                    });
                  },
                ),

                if (step == 1) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx, false);
                      await showForgotPinFlow(context);
                    },
                    child: const Text(
                      'Quên mã PIN cũ? Nhận mã OTP qua Email',
                      style: TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    return result ?? false;
  }

  /// 3. TẮT MÃ PIN: YÊU CẦU NHẬP MÃ CŨ ĐỂ XÁC NHẬN
  static Future<bool> showDisablePinDialog(BuildContext context) async {
    final pinService = AppPinSecurityService();
    if (!pinService.isPinEnabled) return true;

    String oldPinInput = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.lock_open_rounded, color: Color(0xFFDC2626), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Xác Nhận Tắt Mã PIN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vui lòng nhập mã PIN 4 số hiện tại để xác nhận tắt khóa bảo vệ ứng dụng.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                _buildPinDots(pinLength: oldPinInput.length),
                const SizedBox(height: 24),

                _buildKeypad(
                  onNumberPress: (digit) async {
                    if (oldPinInput.length < 4) {
                      setDialogState(() => oldPinInput += digit);
                      if (oldPinInput.length == 4) {
                        if (pinService.verifyPin(oldPinInput)) {
                          await pinService.disablePin();
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                        } else {
                          HapticFeedback.vibrate();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Mã PIN không chính xác!'),
                                backgroundColor: Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          setDialogState(() => oldPinInput = '');
                        }
                      }
                    }
                  },
                  onDeletePress: () {
                    setDialogState(() {
                      if (oldPinInput.isNotEmpty) {
                        oldPinInput = oldPinInput.substring(0, oldPinInput.length - 1);
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    return confirmed ?? false;
  }

  static bool _isUnlockDialogShowing = false;

  /// 4. MỞ KHÓA APP (TOKEN PHIÊN 1 TIẾNG HOẶC KHI KHỞI ĐỘNG LẠI APP)
  /// Đảm bảo tính bảo mật tuyệt đối: Không thể bấm back hoặc hủy để lọt vào app
  static Future<bool> showUnlockPinDialog(BuildContext context) async {
    final pinService = AppPinSecurityService();
    if (!pinService.isPinEnabled) return true;

    // Kiểm tra token phiên: nếu chưa hết hạn (chưa quá 60 phút và không phải cold-start) -> Cho vào app
    if (!pinService.isSessionExpired()) {
      return true;
    }

    if (_isUnlockDialogShowing) return false;
    _isUnlockDialogShowing = true;

    try {
      // VÒNG LẶP BẢO MẬT BẮT BUỘC:
      // Người dùng chỉ có thể:
      // 1. Nhập đúng mã PIN 4 số -> Mở khóa và vào app.
      // 2. Hoàn thành xác thực OTP Email và tạo mã mới -> Mở khóa và vào app.
      // 3. Nếu bấm Hủy hoặc thoát ở bước Quên mã -> VÒNG LẶP SẼ QUAY LẠI MÀN HÌNH NHẬP MÃ PIN (Không bao giờ lọt vào app).
      // 4. Nếu bấm "Thoát ứng dụng" -> Đóng app bằng SystemNavigator.pop().
      while (context.mounted && pinService.isPinEnabled && pinService.isSessionExpired()) {
        final action = await _showSingleUnlockDialog(context);
        if (!context.mounted) return false;

        if (action == 'unlocked') {
          return true;
        } else if (action == 'forgot') {
          final resetOk = await showForgotPinFlow(context);
          if (!context.mounted) return false;
          if (resetOk == true) {
            await pinService.recordUnlockSuccess();
            return true;
          }
          // Nếu không hoàn thành cấp lại mã (bấm Hủy hoặc thoát OTP)
          // Vòng lặp while tiếp tục giữ người dùng ở màn hình nhập PIN!
        } else if (action == 'exit') {
          SystemNavigator.pop();
          return false;
        }
      }

      return !pinService.isSessionExpired();
    } finally {
      _isUnlockDialogShowing = false;
    }
  }

  /// Màn hình nhập mã PIN 4 số đơn lẻ
  static Future<String?> _showSingleUnlockDialog(BuildContext context) async {
    final pinService = AppPinSecurityService();
    String currentInput = '';
    bool hasError = false;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return PopScope(
            canPop: false, // Bắt buộc nhập mã PIN, không bấm back ra ngoài được
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              // Thoát ứng dụng an toàn khi bấm back Android
              SystemNavigator.pop();
            },
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Column(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF0284C7), size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Mã Bảo Mật Ứng Dụng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Vui lòng nhập mã PIN 4 số để tiếp tục sử dụng AutoBank.\n(Phiên đăng nhập có hiệu lực 1 tiếng).',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  _buildPinDots(pinLength: currentInput.length),
                  const SizedBox(height: 20),

                  _buildKeypad(
                    onNumberPress: (digit) async {
                      if (currentInput.length < 4) {
                        setDialogState(() => currentInput += digit);
                        if (currentInput.length == 4) {
                          if (pinService.verifyPin(currentInput)) {
                            await pinService.recordUnlockSuccess();
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx, 'unlocked');
                          } else {
                            HapticFeedback.vibrate();
                            hasError = true;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Mã PIN không chính xác! Vui lòng thử lại.'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            setDialogState(() => currentInput = '');
                          }
                        }
                      }
                    },
                    onDeletePress: () {
                      setDialogState(() {
                        if (currentInput.isNotEmpty) {
                          currentInput = currentInput.substring(0, currentInput.length - 1);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // NÚT QUÊN MÃ PIN (Nổi bật hơn khi người dùng nhập sai)
                  Container(
                    decoration: hasError ? BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ) : null,
                    padding: hasError ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4) : EdgeInsets.zero,
                    child: TextButton.icon(
                      icon: Icon(Icons.help_outline_rounded, size: 16, color: hasError ? const Color(0xFFDC2626) : const Color(0xFF0284C7)),
                      label: Text(
                        hasError ? 'Quên mã PIN? Bấm vào đây để nhận mã qua Email' : 'Quên mã PIN? Nhận mã xác thực qua Email',
                        style: TextStyle(
                          color: hasError ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx, 'forgot');
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.exit_to_app_rounded, size: 16, color: Color(0xFF94A3B8)),
                    label: const Text('Thoát ứng dụng', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    onPressed: () {
                      Navigator.pop(dialogCtx, 'exit');
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 5. QUÊN MÃ PIN -> GỬI MÃ OTP 6 SỐ VỀ EMAIL -> ĐẶT LẠI MÃ MỚI
  /// Trả về true nếu người dùng hoàn tất đặt lại mã PIN mới thành công, ngược lại trả về false
  static Future<bool> showForgotPinFlow(BuildContext context) async {
    final pinService = AppPinSecurityService();
    final googleAuth = context.read<GoogleAuthProvider>();
    final notifProvider = context.read<AppNotificationProvider>();

    final userEmail = googleAuth.isSignedIn && googleAuth.email.isNotEmpty
        ? googleAuth.email
        : 'admin@autobank.com';

    // 1. Gọi API gửi mã OTP 6 số về Gmail thật của người dùng
    final res = await pinService.requestPinResetOtpFromApi(userEmail);
    final isFallback = res['localFallback'] == true;
    final fallbackOtp = res['otp'] as String?;

    if (isFallback && fallbackOtp != null) {
      // Nếu offline, gửi thông báo mã tạm thời trong app
      notifProvider.postNotification(
        title: '🔐 Mã OTP cấp lại PIN: $fallbackOtp',
        message: 'Mã xác thực cấp lại mã PIN AutoBank của bạn là: $fallbackOtp. Mã có hiệu lực trong 10 phút.',
        category: NotificationCategory.auth,
        showAndroidStatusNotification: true,
      );
    }

    String enteredOtp = '';

    if (!context.mounted) return false;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return PopScope(
            canPop: false, // Bắt buộc bấm Hủy nếu không muốn tiếp tục
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Xác Thực Cấp Lại PIN (6 Số)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFallback
                        ? 'Hệ thống đã cấp mã xác thực 6 số tạm thời cho bạn.'
                        : 'Hệ thống đã gửi mã xác thực 6 số đến Gmail:\n$userEmail\n(Vui lòng mở ứng dụng Gmail để lấy mã)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, color: Color(0xFF0284C7), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isFallback && fallbackOtp != null
                                ? 'Mã OTP tạm thời: $fallbackOtp'
                                : 'Kiểm tra hộp thư đến hoặc mục Thư rác/Spam',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6 ô nhập OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < enteredOtp.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 36,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isFilled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          isFilled ? enteredOtp[index] : '-',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  _buildKeypad(
                    onNumberPress: (digit) async {
                      if (enteredOtp.length < 6) {
                        setDialogState(() {
                          enteredOtp += digit;
                        });

                        if (enteredOtp.length == 6) {
                          final isValid = await pinService.verifyPinResetOtpViaApi(userEmail, enteredOtp);
                          if (isValid) {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                          } else {
                            HapticFeedback.vibrate();
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Mã OTP 6 số không đúng hoặc đã hết hạn!'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            setDialogState(() {
                              enteredOtp = '';
                            });
                          }
                        }
                      }
                    },
                    onDeletePress: () {
                      setDialogState(() {
                        if (enteredOtp.isNotEmpty) {
                          enteredOtp = enteredOtp.substring(0, enteredOtp.length - 1);
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Xác thực OTP thành công -> Thiết lập ngay mã PIN mới
    if (verified == true && context.mounted) {
      final success = await showSetPinDialog(context);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Đã cấp lại mã PIN mới thành công! Ứng dụng đã được mở khóa.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return true;
      }
    }

    return false;
  }

  /// 6. HỘP THOẠI QUẢN LÝ MÃ LIVE WEB TỪ XA (6 SỐ - HOÀN TOÀN KHÁC VỚI MÃ PIN 4 SỐ)
  static Future<void> showLiveWebPinDialog(BuildContext context) async {
    final pinService = AppPinSecurityService();
    final ctrl = TextEditingController(text: pinService.liveWebPin);

    await showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.cell_tower_rounded, color: Color(0xFF16A34A), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mã Bảo Mật Live Web (6 Số)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mã bảo mật 6 số dùng để mở khóa nghe loa từ xa trên máy tính/iPad tại trang Live Web.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu ý: Mã này là 6 số, khác biệt hoàn toàn với mã PIN 4 số bảo vệ ứng dụng điện thoại.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mã Live Web của bạn:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.shuffle_rounded, size: 16, color: Color(0xFF0284C7)),
                  label: const Text('Tạo mã ngẫu nhiên', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final rand = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
                    ctrl.text = rand;
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: ctrl,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF16A34A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2)),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newPin = ctrl.text.trim();
              if (newPin.length == 6 && int.tryParse(newPin) != null) {
                await pinService.setLiveWebPin(newPin);
                if (context.mounted) {
                  Navigator.pop(dCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã cập nhật mã Live Web 6 số thành công: $newPin!'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đúng 6 chữ số!'),
                    backgroundColor: Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Lưu Mã 6 Số'),
          ),
        ],
      ),
    );
  }

  // WIDGET TIỆN ÍCH DÙNG CHUNG: 4 CHẤM TRÒN PIN
  static Widget _buildPinDots({required int pinLength, int total = 4}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isFilled = index < pinLength;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF0284C7) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
              width: 2.0,
            ),
          ),
        );
      }),
    );
  }

  // BÀN PHÍM SỐ ẢO BẢO MẬT
  static Widget _buildKeypad({
    required void Function(String digit) onNumberPress,
    required VoidCallback onDeletePress,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1', '2', '3'].map((d) => _buildKeyBtn(d, () => onNumberPress(d))).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4', '5', '6'].map((d) => _buildKeyBtn(d, () => onNumberPress(d))).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['7', '8', '9'].map((d) => _buildKeyBtn(d, () => onNumberPress(d))).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 64, height: 46),
              _buildKeyBtn('0', () => onNumberPress('0')),
              SizedBox(
                width: 64,
                height: 46,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onDeletePress,
                  child: const Icon(Icons.backspace_outlined, size: 20, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildKeyBtn(String digit, VoidCallback onTap) {
    return SizedBox(
      width: 64,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Text(
          digit,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

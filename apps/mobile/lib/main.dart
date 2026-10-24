import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/security/app_pin_security_service.dart';
import 'core/tts/tts_service.dart';
import 'core/widgets/phone_simulator_frame.dart';
import 'features/affiliate/presentation/providers/affiliate_provider.dart';
import 'features/auth/presentation/pages/initial_plan_selection_page.dart';
import 'features/auth/presentation/pages/welcome_landing_page.dart';
import 'features/auth/presentation/providers/google_auth_provider.dart';
import 'features/navigation/presentation/main_navigation_wrapper.dart';
import 'features/notification_center/presentation/providers/app_notification_provider.dart';
import 'features/system/presentation/providers/system_config_provider.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';
import 'features/voice_settings/presentation/providers/voice_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa xoay màn hình 100% đứng (Portrait Up)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Khởi tạo bảo mật mã PIN app trước tiên để kiểm tra trạng thái khóa
  await AppPinSecurityService().init();

  // Khởi tạo trước dịch vụ phát âm thanh TTS để sẵn sàng ngay khi người dùng ấn vào chức năng
  TtsService().init();

  // Bắt toàn bộ lỗi Flutter framework để không làm đóng ứng dụng
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[AutoBank Framework Error]: ${details.exceptionAsString()}');
  };

  // Bắt toàn bộ lỗi async unhandled để chống văng app trên Android/Web
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[AutoBank Async Guard]: $error');
    return true; // Đã ngăn chặn crash hệ thống
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoogleAuthProvider()),
        ChangeNotifierProvider(create: (_) => SystemConfigProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => VoiceSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AppNotificationProvider()),
        ChangeNotifierProvider(create: (_) => AffiliateProvider()),
        ChangeNotifierProvider.value(value: AppPinSecurityService()),
      ],
      child: const AutoBankApp(),
    ),
  );
}

class AutoBankApp extends StatelessWidget {
  const AutoBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đọc Thông Báo Nhận Tiền',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7), // Màu xanh nước
          primary: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const PhoneSimulatorFrame(
        child: AuthGateWrapper(),
      ),
    );
  }
}

class AuthGateWrapper extends StatelessWidget {
  const AuthGateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<GoogleAuthProvider>();
    if (!auth.isSignedIn) {
      return const WelcomeLandingPage();
    }
    // Chỉ tài khoản MỚI ĐĂNG KÝ (chưa có SĐT và chưa từng kích hoạt gói/dùng thử) mới phải nhập thông tin & chọn gói
    final isNewUser = (auth.phone.isEmpty || auth.phone == 'Chưa có SĐT') &&
        (!auth.isTrialStarted && !auth.hasUsedTrial && !auth.isActivated && !auth.isLifetime);
    if (isNewUser) {
      return const InitialPlanSelectionPage();
    }
    return const MainNavigationWrapper();
  }
}

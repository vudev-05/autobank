import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/widgets/phone_simulator_frame.dart';
import 'features/auth/presentation/pages/initial_plan_selection_page.dart';
import 'features/auth/presentation/pages/welcome_landing_page.dart';
import 'features/auth/presentation/providers/google_auth_provider.dart';
import 'features/navigation/presentation/main_navigation_wrapper.dart';
import 'features/notification_center/presentation/providers/app_notification_provider.dart';
import 'features/system/presentation/providers/system_config_provider.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';
import 'features/voice_settings/presentation/providers/voice_settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
    // Yêu cầu: Người dùng mới tạo tài khoản phải chọn gói dùng thử 3 ngày hoặc gói bản quyền trước khi vào sử dụng app
    if (!auth.isTrialStarted && !auth.hasUsedTrial && !auth.isActivated && !auth.isLifetime) {
      return const InitialPlanSelectionPage();
    }
    return const MainNavigationWrapper();
  }
}

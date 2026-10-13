import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:autobank_mobile/main.dart';
import 'package:autobank_mobile/features/transactions/presentation/providers/transaction_provider.dart';

import 'package:autobank_mobile/features/voice_settings/presentation/providers/voice_settings_provider.dart';

void main() {
  testWidgets('AutoBank App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => VoiceSettingsProvider()),
        ],
        child: const AutoBankApp(),
      ),
    );

    // Verify title is rendered
    expect(find.text('Đọc thông báo nhận tiền'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:h2hfleet/core/theme/app_theme.dart';
import 'package:h2hfleet/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen builds and renders cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );

    // Verify H2H brand and login elements are present
    expect(find.text('H2H'), findsOneWidget);
    expect(find.text('FLEET'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบด้วย Apple'), findsOneWidget);
  });
}

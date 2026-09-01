import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/ui/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders Passkey authentication elements', (WidgetTester tester) async {
    bool loginSuccessTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          onLoginSuccess: () {
            loginSuccessTriggered = true;
          },
        ),
      ),
    );

    // Verify Title & Subtitle
    expect(find.text("Sleep Apnea App"), findsOneWidget);
    expect(find.text("Biometric Passkey Required"), findsOneWidget);

    // Verify Passkey Button
    final Finder passkeyBtn = find.text("Sign in with Passkey");
    expect(passkeyBtn, findsOneWidget);

    // Tap Passkey button and verify trigger
    await tester.tap(passkeyBtn);
    await tester.pump(const Duration(milliseconds: 900));
    expect(loginSuccessTriggered, isTrue);
  });
}

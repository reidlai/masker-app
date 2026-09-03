import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/auth/auth_bloc.dart';
import 'package:masker_app/ui/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders Passkey authentication elements and triggers AuthBloc', (WidgetTester tester) async {
    bool loginSuccessTriggered = false;

    await tester.pumpWidget(
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          passkeyAuthenticator: () async {
            await Future.delayed(const Duration(milliseconds: 50));
          },
        ),
        child: MaterialApp(
          home: LoginPage(
            onLoginSuccess: () {
              loginSuccessTriggered = true;
            },
          ),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(loginSuccessTriggered, isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/auth/auth_bloc.dart';
import 'package:masker_app/core/bloc/auth/auth_state.dart';
import 'package:masker_app/core/config/passkey_simulator_config.dart';
import 'package:masker_app/ui/pages/login_page.dart';

void main() {
  // PasskeySimulatorConfig is a process-global singleton; keep tests isolated.
  setUp(() => PasskeySimulatorConfig.instance.reset());
  tearDown(() => PasskeySimulatorConfig.instance.reset());

  testWidgets(
      'LoginPage renders Passkey authentication elements and triggers AuthBloc',
      (WidgetTester tester) async {
    var loginSuccessTriggered = false;

    await tester.pumpWidget(
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(
          passkeyAuthenticator: () async {
            await Future.delayed(const Duration(milliseconds: 50));
          },
        ),
        child: MaterialApp(
          home: LoginPage(onLoginSuccess: () => loginSuccessTriggered = true),
        ),
      ),
    );

    expect(find.text('D-BAND Sleep Apnea Detection App'), findsOneWidget);
    expect(find.text('Biometric Passkey Required'), findsOneWidget);

    final passkeyBtn = find.text('Sign in with Passkey');
    expect(passkeyBtn, findsOneWidget);

    await tester.tap(passkeyBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(loginSuccessTriggered, isTrue);
  });

  testWidgets(
      'simulator off + no authenticator: Sign in shows the unavailable message, '
      'the button stays enabled, and a later tap re-runs the attempt',
      (WidgetTester tester) async {
    var loginSuccessTriggered = false;
    final states = <AuthState>[];
    final bloc = AuthBloc(isPasskeySimulatorEnabled: () => false);
    addTearDown(bloc.close);
    final sub = bloc.stream.listen(states.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: LoginPage(onLoginSuccess: () => loginSuccessTriggered = true),
        ),
      ),
    );

    await tester.tap(find.text('Sign in with Passkey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(passkeyUnavailableMessage), findsOneWidget);
    expect(loginSuccessTriggered, isFalse);
    // No dead end: the button is still enabled after AuthUnavailable.
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );

    // A second attempt *after* the 300 ms throttle window genuinely re-runs.
    await tester.pump(const Duration(milliseconds: 350));
    states.clear();
    await tester.tap(find.text('Sign in with Passkey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(states, [isA<AuthInProgress>(), isA<AuthUnavailable>()]);
    expect(find.text(passkeyUnavailableMessage), findsOneWidget);
    expect(loginSuccessTriggered, isFalse);

    // Let the second tap's throttleTime(300ms) window elapse so no timer
    // outlives the test.
    await tester.pump(const Duration(milliseconds: 350));
  });
}

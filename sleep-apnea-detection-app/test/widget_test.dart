// Smoke tests for the root MaskerApp widget.
//
// Boot routing: a fresh install (onboarding gate not complete) goes straight to
// the onboarding wizard; a returning user gets the sign-in screen. The
// "wired-up app blocks passkey sign-in when the simulator is off" check runs on
// the returning-user path.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masker_app/core/bloc/auth/auth_state.dart'
    show passkeyUnavailableMessage;
import 'package:masker_app/core/config/passkey_simulator_config.dart';
import 'package:masker_app/core/onboarding/onboarding_gate.dart';
import 'package:masker_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOnboardingGate implements OnboardingGate {
  _FakeOnboardingGate({required this.complete});
  bool complete;
  @override
  Future<bool> isComplete() async => complete;
  @override
  Future<void> markComplete() async => complete = true;
  @override
  Future<void> clear() async => complete = false;
}

Future<void> _bootSettle(WidgetTester tester) async {
  await tester.pumpWidget(const MaskerApp());
  await tester.pump(); // process AppFlowResolveRequested
  await tester.pump(const Duration(milliseconds: 50)); // land the resolved stage
}

void main() {
  tearDown(() => PasskeySimulatorConfig.instance.reset());

  testWidgets('fresh install: MaskerApp boots straight to the onboarding wizard',
      (tester) async {
    OnboardingGate.instance = _FakeOnboardingGate(complete: false);

    await _bootSettle(tester);

    expect(find.byKey(const Key('onboarding-step-register')), findsOneWidget);
    expect(find.text('Sign in with Passkey'), findsNothing);
    expect(find.text('Biometric Passkey Required'), findsNothing);
  });

  group('returning user (onboarding complete)', () {
    setUp(() =>
        OnboardingGate.instance = _FakeOnboardingGate(complete: true));

    testWidgets('MaskerApp boots to the login screen', (tester) async {
      await _bootSettle(tester);

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('D-BAND Sleep Apnea Detection App'), findsOneWidget);
    });

    testWidgets('Passkey Simulator off: the wired-up app blocks passkey sign-in',
        (tester) async {
      PasskeySimulatorConfig.instance.setEnabled(false);
      await _bootSettle(tester);

      await tester.tap(find.text('Sign in with Passkey'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(passkeyUnavailableMessage), findsOneWidget);
      // Still on the login screen — no fake session was minted.
      expect(find.text('D-BAND Sleep Apnea Detection App'), findsOneWidget);
    });
  });

  group('real SharedPreferencesOnboardingGate wired through MaskerApp', () {
    setUp(OnboardingGate.reset); // undo flutter_test_config's in-memory fake

    testWidgets('empty prefs → onboarding wizard', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _bootSettle(tester);
      expect(find.byKey(const Key('onboarding-step-register')), findsOneWidget);
      expect(find.text('Sign in with Passkey'), findsNothing);
    });

    testWidgets('onboarding_complete: true → sign-in screen', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      await _bootSettle(tester);
      expect(find.text('D-BAND Sleep Apnea Detection App'), findsOneWidget);
      expect(find.byKey(const Key('onboarding-step-register')), findsNothing);
    });
  });
}

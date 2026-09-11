// Smoke tests for the root MaskerApp widget.
//
// Verifies the app boots to the login screen, and that the *wired-up* app
// (real providers from `main`) blocks passkey sign-in when the Passkey
// Simulator is off — i.e. `main` wires the gate in and wires no authenticator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masker_app/core/bloc/auth/auth_state.dart'
    show passkeyUnavailableMessage;
import 'package:masker_app/core/config/passkey_simulator_config.dart';
import 'package:masker_app/main.dart';

void main() {
  tearDown(() => PasskeySimulatorConfig.instance.reset());

  testWidgets('MaskerApp boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaskerApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('D-BAND Sleep Apnea Detection App'), findsOneWidget);
  });

  testWidgets(
      'Passkey Simulator off: the wired-up app blocks passkey sign-in',
      (WidgetTester tester) async {
    PasskeySimulatorConfig.instance.setEnabled(false);
    await tester.pumpWidget(const MaskerApp());

    await tester.tap(find.text('Sign in with Passkey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(passkeyUnavailableMessage), findsOneWidget);
    // Still on the login screen — no fake session was minted.
    expect(find.text('D-BAND Sleep Apnea Detection App'), findsOneWidget);
  });
}

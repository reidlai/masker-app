import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/passkey_auth_card_organism.dart';

void main() {
  testWidgets('PasskeyAuthCardOrganism renders passkey button and handles tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasskeyAuthCardOrganism(
            isAuthenticating: false,
            onAuthenticate: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text("Biometric Passkey Required"), findsOneWidget);
    final btn = find.text("Sign in with Passkey");
    expect(btn, findsOneWidget);

    await tester.tap(btn);
    expect(tapped, isTrue);
  });
}

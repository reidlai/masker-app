// Smoke test for the root MaskerApp widget.
//
// Verifies the app boots to the login screen when the user is not yet
// authenticated.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:masker_app/main.dart';

void main() {
  testWidgets('MaskerApp boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaskerApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Sleep Apnea App'), findsOneWidget);
  });
}

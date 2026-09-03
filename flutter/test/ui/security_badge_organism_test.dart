import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/security_badge_organism.dart';

void main() {
  testWidgets('SecurityBadgeOrganism renders security compliance text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SecurityBadgeOrganism(),
        ),
      ),
    );

    expect(find.text("🔒 HIPAA §164.312 Protected · FIDO2 Hardware Encryption"), findsOneWidget);
  });
}

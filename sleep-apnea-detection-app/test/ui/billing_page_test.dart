import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/billing_page.dart';

void main() {
  group('BillingPage Widget Tests', () {
    testWidgets('BillingPage renders plan card and payment method', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BillingPage(),
        ),
      );

      // Verify header and plan title
      expect(find.text('Billing & Subscription'), findsOneWidget);
      expect(find.text('Premium Plan'), findsOneWidget);
      expect(find.text('PAYMENT METHOD ON FILE'), findsOneWidget);
      expect(find.text('Visa ·· 4242'), findsOneWidget);
    });
  });
}

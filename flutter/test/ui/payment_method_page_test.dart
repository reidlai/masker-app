import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/payment_method_page.dart';

void main() {
  group('PaymentMethodPage Widget Tests', () {
    testWidgets('PaymentMethodPage renders card details and actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodPage(),
        ),
      );

      // Verify title
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('CARD ON FILE'), findsOneWidget);
      expect(find.text('David Miller'), findsOneWidget);
      expect(find.text('Replace Card'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/language_region_page.dart';

void main() {
  group('LanguageRegionPage Widget Tests', () {
    testWidgets('LanguageRegionPage renders sections and handles selections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LanguageRegionPage(),
        ),
      );

      // Verify sections
      expect(find.text('APPLICATION LANGUAGE'), findsOneWidget);
      expect(find.text('REGION & LOCALIZATION'), findsOneWidget);
      expect(find.text('MEASUREMENT UNITS'), findsOneWidget);

      // Verify options
      expect(find.text('English (US)'), findsOneWidget);
      expect(find.text('Metric (kg, cm)'), findsOneWidget);

      // Select English (UK)
      await tester.tap(find.text('English (UK)'));
      await tester.pumpAndSettle();

      expect(find.text('English (UK)'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/history_filter_page.dart';

void main() {
  group('HistoryFilterPage Widget Tests', () {
    testWidgets('HistoryFilterPage renders title, filter chips, and list items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryFilterPage(),
        ),
      );

      // Verify app bar title
      expect(find.text('Session History'), findsOneWidget);

      // Verify filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Normal (<5)'), findsOneWidget);
      expect(find.text('Moderate (5–29)'), findsOneWidget);
      expect(find.text('Severe (≥30)'), findsOneWidget);

      // Verify sessions rendered
      expect(find.text('Sep 5, 2026'), findsOneWidget);

      // Filter by Moderate
      await tester.tap(find.text('Moderate (5–29)'));
      await tester.pumpAndSettle();

      expect(find.text('Aug 31, 2026'), findsOneWidget);
      expect(find.text('Sep 5, 2026'), findsNothing);
    });
  });
}

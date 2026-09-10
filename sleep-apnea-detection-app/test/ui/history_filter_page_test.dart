import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/atoms/shad_badge.dart';
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
      expect(find.text('Mild (5–15)'), findsOneWidget);
      expect(find.text('Moderate (15–30)'), findsOneWidget);
      expect(find.text('Severe (≥30)'), findsOneWidget);

      // Verify apnea-only caveat present
      expect(find.textContaining('apnea-only screen'), findsOneWidget);

      // Verify sessions rendered
      expect(find.text('Sep 5, 2026'), findsOneWidget);

      // Filter by Moderate
      await tester.ensureVisible(find.text('Moderate (15–30)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moderate (15–30)'));
      await tester.pumpAndSettle();

      expect(find.text('Aug 31, 2026'), findsOneWidget);
      expect(find.text('Sep 5, 2026'), findsNothing);
    });

    testWidgets('row badge for a Mild-band session (AI 9.4) uses the amber '
        '(moderate) variant, not the green (normal) one', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HistoryFilterPage()),
      );

      // Seed row "Sep 3, 2026" has ai 9.4 -> Mild band -> amber badge.
      final badge = tester.widget<ShadBadge>(
        find.widgetWithText(ShadBadge, 'AI 9.4'),
      );
      expect(badge.variant, ShadBadgeVariant.moderate);

      // And a Normal-band row (Sep 5, ai 3.2) stays green.
      final normalBadge = tester.widget<ShadBadge>(
        find.widgetWithText(ShadBadge, 'AI 3.2'),
      );
      expect(normalBadge.variant, ShadBadgeVariant.normal);
    });
  });
}

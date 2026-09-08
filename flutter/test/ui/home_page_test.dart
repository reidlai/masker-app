import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/home_page.dart';
import 'package:masker_app/ui/molecules/home_summary_card.dart';
import 'package:masker_app/ui/molecules/device_status_card.dart';
import 'package:masker_app/ui/molecules/weekly_trend_card.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('HomePage renders greeting, streak, summary card, device status card, and weekly trend card', (WidgetTester tester) async {
      bool summaryTapped = false;
      bool historyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            onOpenSummary: () => summaryTapped = true,
            onOpenHistory: () => historyTapped = true,
          ),
        ),
      );

      // Verify streak text
      expect(find.text('12 nights monitored'), findsOneWidget);

      // Verify cards exist
      expect(find.byType(HomeSummaryCard), findsOneWidget);
      expect(find.byType(DeviceStatusCard), findsOneWidget);
      expect(find.byType(WeeklyTrendCard), findsOneWidget);

      // Tap summary hero card
      await tester.tap(find.byType(HomeSummaryCard));
      await tester.pumpAndSettle();
      expect(summaryTapped, isTrue);

      // Tap weekly trend card
      await tester.tap(find.byType(WeeklyTrendCard));
      await tester.pumpAndSettle();
      expect(historyTapped, isTrue);
    });
  });
}

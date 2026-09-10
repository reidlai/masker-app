import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/profile/device_profile_service.dart';
import 'package:masker_app/ui/pages/home_page.dart';
import 'package:masker_app/ui/molecules/home_summary_card.dart';
import 'package:masker_app/ui/molecules/device_status_card.dart';
import 'package:masker_app/ui/molecules/weekly_trend_card.dart';

void main() {
  setUp(() {
    DeviceProfileService.instance.reset();
    BleSimulatorDriver().resetForTest();
  });
  tearDown(() => BleSimulatorDriver().resetForTest());

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

      expect(find.text('12 nights monitored'), findsOneWidget);
      expect(find.byType(HomeSummaryCard), findsOneWidget);
      expect(find.byType(DeviceStatusCard), findsOneWidget);
      expect(find.byType(WeeklyTrendCard), findsOneWidget);

      await tester.tap(find.byType(HomeSummaryCard));
      await tester.pumpAndSettle();
      expect(summaryTapped, isTrue);

      await tester.tap(find.byType(WeeklyTrendCard));
      await tester.pumpAndSettle();
      expect(historyTapped, isTrue);
    });

    testWidgets('no bound device → card reads "D-BAND not found"', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('D-BAND not found'), findsOneWidget);
      expect(find.text('D-BAND connected'), findsNothing);
    });

    testWidgets('bound device + simulator inactive → still "not found" (gate is bound && active)', (tester) async {
      DeviceProfileService.instance.set(demoDeviceProfile);
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('D-BAND not found'), findsOneWidget);
    });

    testWidgets('bound device + simulator active → "D-BAND connected"', (tester) async {
      DeviceProfileService.instance.set(demoDeviceProfile);
      BleSimulatorDriver().setSimulatorEnabled(true); // starts the emitter timer
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();

      expect(find.text('D-BAND connected'), findsOneWidget);

      BleSimulatorDriver().resetForTest(); // cancel the periodic timer before test end
      await tester.pump();
    });
  });
}

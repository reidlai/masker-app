import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_telemetry_service.dart';
import 'package:masker_app/ui/organisms/developer_simulator_bar_organism.dart';

void main() {
  tearDown(() {
    BleTelemetryService().resetForTest();
  });

  testWidgets('DeveloperSimulatorBarOrganism renders developer toolbar and scenario chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeveloperSimulatorBarOrganism(),
        ),
      ),
    );

    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsOneWidget);
    expect(find.text("Idle Noise"), findsOneWidget);
    expect(find.text("Active Baseline"), findsOneWidget);
    expect(find.text("Normal (16 bpm)"), findsOneWidget);
    expect(find.text("Apnea Drop (>10s)"), findsOneWidget);
    expect(find.text("Recovery (5s)"), findsOneWidget);

    final apneaChip = find.text("Apnea Drop (>10s)");
    await tester.tap(apneaChip);
    await tester.pump();

    expect(BleTelemetryService().currentScenario, equals(SimulatorScenario.apneaAlert));

    BleTelemetryService().resetForTest();
  });
}
